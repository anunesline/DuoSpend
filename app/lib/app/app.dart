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
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    widget.pushNotificationService.foregroundMessage.addListener(
      _showForegroundNotification,
    );
  }

  void _showForegroundNotification() {
    final message = widget.pushNotificationService.foregroundMessage.value;
    if (message == null) return;

    final messenger = _messengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${message.title}\n${message.body}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    widget.pushNotificationService.clearForegroundMessage();
  }

  @override
  void dispose() {
    widget.pushNotificationService.foregroundMessage.removeListener(
      _showForegroundNotification,
    );
    widget.pushNotificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
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
