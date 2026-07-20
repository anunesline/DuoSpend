import 'package:flutter/material.dart';

import '../../../../core/di/app_dependency_container.dart';
import '../../../../core/services/auth/auth_service.dart';
import '../../../home/presentation/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  final AppDependencyContainer dependencies;

  const LoginPage({
    super.key,
    required this.dependencies,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  bool _loading = false;

  Future<void> _loginWithGoogle() async {
    if (_loading) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        return;
      }

      debugPrint('Usuário logado: ${user.displayName}');

      await widget.dependencies.productBootstrap.initialize(
        userId: user.uid,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            walletContext: widget.dependencies.walletContext,
            shoppingController: widget.dependencies.shoppingController,
            consumerController: widget.dependencies.consumerController,
            purchaseController: widget.dependencies.purchaseController,
            productRepository: widget.dependencies.productRepository,
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao realizar login e inicializar produtos: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível concluir o login. Tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 80,
                  color: Color(0xFF4F46E5),
                ),
                const SizedBox(
                  height: 24,
                ),
                const Text(
                  'DuoSpend',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Organize suas finanças sozinho ou em casal.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 48,
                ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _loading
                        ? null
                        : _loginWithGoogle,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.login,
                          ),
                    label: Text(
                      _loading
                          ? 'Carregando seus produtos...'
                          : 'Entrar com Google',
                    ),
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