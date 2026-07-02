import 'package:flutter/material.dart';
import '../../../../core/services/auth/auth_service.dart';
import '../../../home/presentation/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _loading = false;

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
  debugPrint("🔥 Usuário logado: ${user.displayName}");

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const HomePage(),
    ),
  );
}
      
    } catch (e) {
      debugPrint("Erro login: $e");
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 80,
                  color: Color(0xFF4F46E5),
                ),

                const SizedBox(height: 24),

                const Text(
                  'DuoSpend',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Organize suas finanças sozinho ou em casal.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _loginWithGoogle,
                    icon: const Icon(Icons.login),
                    label: _loading
                        ? const Text("Entrando...")
                        : const Text("Entrar com Google"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}