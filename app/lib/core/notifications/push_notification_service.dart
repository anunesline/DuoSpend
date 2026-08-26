import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushNotificationService {
  static const _appId = String.fromEnvironment('ONESIGNAL_APP_ID');

  final FirebaseAuth auth;

  StreamSubscription<User?>? _authSubscription;
  String? _identifiedUserId;
  bool _initialized = false;

  PushNotificationService({FirebaseAuth? auth})
      : auth = auth ?? FirebaseAuth.instance;

  bool get _supportsPush {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_initialized || !_supportsPush) return;
    _initialized = true;

    if (_appId.trim().isEmpty) {
      debugPrint(
        'OneSignal disabled: build without --dart-define=ONESIGNAL_APP_ID.',
      );
      return;
    }

    try {
      OneSignal.initialize(_appId.trim());
      await OneSignal.Notifications.requestPermission(false);

      _authSubscription = auth.authStateChanges().listen((user) {
        unawaited(_syncIdentity(user));
      });
      await _syncIdentity(auth.currentUser);
    } catch (error, stackTrace) {
      debugPrint('OneSignal unavailable: $error\n$stackTrace');
    }
  }

  Future<void> _syncIdentity(User? user) async {
    try {
      final nextUserId = user?.uid.trim();
      if (nextUserId == null || nextUserId.isEmpty) {
        if (_identifiedUserId != null) {
          await OneSignal.logout();
          _identifiedUserId = null;
        }
        return;
      }

      if (_identifiedUserId == nextUserId) return;
      await OneSignal.login(nextUserId);
      _identifiedUserId = nextUserId;
    } catch (error) {
      debugPrint('Could not sync OneSignal user: $error');
    }
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
  }
}
