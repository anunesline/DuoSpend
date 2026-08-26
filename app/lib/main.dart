import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/notifications/push_notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (error) {
    if (error.code != 'duplicate-app') {
      rethrow;
    }
  }

  final pushNotificationService = PushNotificationService();
  await pushNotificationService.initialize();
  final dependencies = await AppBootstrap.initialize();

  runApp(
    DuoSpendApp(
      dependencies: dependencies,
      pushNotificationService: pushNotificationService,
    ),
  );
}
