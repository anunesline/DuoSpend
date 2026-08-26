import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationMessage {
  final String title;
  final String body;
  final Map<String, dynamic> data;

  const PushNotificationMessage({
    required this.title,
    required this.body,
    required this.data,
  });
}

class PushNotificationService {
  final FirebaseMessaging messaging;
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  final ValueNotifier<PushNotificationMessage?> foregroundMessage =
      ValueNotifier<PushNotificationMessage?>(null);

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  String? _lastUserId;
  bool _initialized = false;

  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : messaging = messaging ?? FirebaseMessaging.instance,
        auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance;

  bool get _supportsMessaging {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> initialize() async {
    if (_initialized || !_supportsMessaging) return;
    _initialized = true;

    await messaging.setAutoInitEnabled(true);
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Foreground messages are rendered by DuoSpendApp to avoid duplicate
    // banners on Apple platforms. Background/terminated notification payloads
    // remain handled by the OS through FCM.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    _authSubscription = auth.authStateChanges().listen(_handleAuthChanged);
    _tokenSubscription = messaging.onTokenRefresh.listen(_saveTokenForCurrentUser);
    _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
      foregroundMessage.value = PushNotificationMessage(
        title: message.notification?.title ?? 'DuoSpend',
        body: message.notification?.body ?? 'Você tem um novo lembrete.',
        data: Map<String, dynamic>.from(message.data),
      );
    });

    await _handleAuthChanged(auth.currentUser);
  }

  Future<void> _handleAuthChanged(User? user) async {
    final previousUserId = _lastUserId;
    final nextUserId = user?.uid.trim();
    _lastUserId = nextUserId;

    final token = await messaging.getToken();
    if (previousUserId != null &&
        previousUserId.isNotEmpty &&
        previousUserId != nextUserId &&
        token != null &&
        token.isNotEmpty) {
      await _tokenReference(previousUserId, token).delete();
    }

    if (nextUserId == null || nextUserId.isEmpty || token == null || token.isEmpty) {
      return;
    }
    await _saveToken(nextUserId, token);
  }

  Future<void> _saveTokenForCurrentUser(String token) async {
    final userId = auth.currentUser?.uid.trim();
    if (userId == null || userId.isEmpty || token.isEmpty) return;
    await _saveToken(userId, token);
  }

  Future<void> _saveToken(String userId, String token) async {
    await _tokenReference(userId, token).set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>> _tokenReference(
    String userId,
    String token,
  ) {
    final safeToken = token.replaceAll('/', '_');
    return firestore
        .collection('users')
        .doc(userId)
        .collection('fcm_tokens')
        .doc(safeToken);
  }

  void clearForegroundMessage() {
    foregroundMessage.value = null;
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    foregroundMessage.dispose();
  }
}
