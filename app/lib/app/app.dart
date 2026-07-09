import 'package:flutter/material.dart';

import '../core/di/app_dependency_container.dart';
import '../features/auth/presentation/pages/login_page.dart';

class DuoSpendApp extends StatelessWidget {
  final AppDependencyContainer dependencies;

  const DuoSpendApp({
    super.key,
    required this.dependencies,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DuoSpend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: LoginPage(
        dependencies: dependencies,
      ),
    );
  }
}