import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
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
  final FirebaseFunctions functions;

  final ValueNotifier<PushNotificationMessage?> foregroundMessage =
      ValueNotifier<PushNotificationMessage?>(null);

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  String? _lastUserId;
  String? _lastToken;
  bool _initialized = false;

  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : messaging = messaging ?? FirebaseMessaging.instance,
        auth = auth ?? FirebaseAuth.instance,
        functions = functions ?? FirebaseFunctions.instance;

  bool get _supportsMessaging {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> initialize() async {
    if (_initialized || !_supportsMessaging) return;
    _initialized = true;

    try {
      await messaging.setAutoInitEnabled(true);
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );

      _authSubscription = auth.authStateChanges().listen((user) {
        unawaited(_handleAuthChanged(user));
      });
      _tokenSubscription = messaging.onTokenRefresh.listen((token) {
        unawaited(_handleTokenRefresh(token));
      });
      _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
        foregroundMessage.value = PushNotificationMessage(
          title: message.notification?.title ?? 'DuoSpend',
          body: message.notification?.body ?? 'Você tem um novo lembrete.',
          data: Map<String, dynamic>.from(message.data),
        );
      });

      await _handleAuthChanged(auth.currentUser);
    } catch (error, stackTrace) {
      debugPrint('Push notifications unavailable: $error\n$stackTrace');
    }
  }

  Future<void> _handleAuthChanged(User? user) async {
    try {
      final previousUserId = _lastUserId;
      final nextUserId = user?.uid.trim();

      if (previousUserId != null &&
          previousUserId.isNotEmpty &&
          previousUserId != nextUserId) {
        // Once sign-out finishes the callable endpoint is no longer authorized.
        // Deleting the registration token locally invalidates it at FCM; any
        // stale server record is removed automatically after a failed send.
        await messaging.deleteToken();
        _lastToken = null;
      }

      _lastUserId = nextUserId;
      if (nextUserId == null || nextUserId.isEmpty) return;

      final token = await messaging.getToken();
      _lastToken = token;
      if (token == null || token.isEmpty) return;
      await _registerToken(token);
    } catch (error) {
      debugPrint('Could not sync FCM token: $error');
    }
  }

  Future<void> _handleTokenRefresh(String token) async {
    try {
      final oldToken = _lastToken;
      _lastToken = token;
      if (auth.currentUser == null || token.isEmpty) return;

      if (oldToken != null && oldToken.isNotEmpty && oldToken != token) {
        await _unregisterToken(oldToken);
      }
      await _registerToken(token);
    } catch (error) {
      debugPrint('Could not refresh FCM token: $error');
    }
  }

  Future<void> _registerToken(String token) async {
    await functions.httpsCallable('registerPushToken').call({
      'token': token,
      'platform': defaultTargetPlatform.name,
    });
  }

  Future<void> _unregisterToken(String token) async {
    await functions.httpsCallable('unregisterPushToken').call({
      'token': token,
    });
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
