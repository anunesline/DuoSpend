import 'package:flutter/material.dart';

import '../core/di/app_dependency_container.dart';
import '../core/notifications/push_notification_service.dart';
import '../features/auth/presentation/pages/login_page.dart';

class DuoSpendApp extends StatefulWidget {
  final AppDependencyContainer dependencies;
  final PushNotificationService pushNotificationService;

  const DuoSpendApp({
    super.key,
    required this.dependencies,
    required this.pushNotificationService,
  });

  @override
  State<DuoSpendApp> createState() => _DuoSpendAppState();
}

class _DuoSpendAppState extends State<DuoSpendApp> {
  @override
  void dispose() {
    widget.pushNotificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DuoSpend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: LoginPage(
        dependencies: widget.dependencies,
      ),
    );
  }
}
