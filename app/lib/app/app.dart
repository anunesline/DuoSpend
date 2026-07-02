import 'package:flutter/material.dart';
import '../features/auth/presentation/pages/login_page.dart';

class DuoSpendApp extends StatelessWidget {
  const DuoSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DuoSpend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}