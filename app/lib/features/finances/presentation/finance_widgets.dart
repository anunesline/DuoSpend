import 'package:flutter/material.dart';

import '../../home/data/models/wallet_model.dart';
import '../../home/presentation/widgets/orbit_home_primitives.dart';

export '../../home/presentation/widgets/orbit_home_primitives.dart';

IconData accountIcon(AccountKind kind) => switch (kind) {
  AccountKind.bank => Icons.account_balance_outlined,
  AccountKind.digital => Icons.phone_android_rounded,
  AccountKind.cash => Icons.payments_outlined,
  AccountKind.other => Icons.account_balance_wallet_outlined,
};
Color accountColor(AccountKind kind) => switch (kind) {
  AccountKind.bank => OrbitHomeTokens.cyan,
  AccountKind.digital => OrbitHomeTokens.purple,
  AccountKind.cash => OrbitHomeTokens.green,
  AccountKind.other => OrbitHomeTokens.amber,
};

/// All money input uses Brazilian formatting, with at most two decimals.
double? parseAccountMoney(String value) {
  final text = value.trim();
  if (text.isEmpty) return 0;
  if (!RegExp(r'^-?(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d{1,2})?$').hasMatch(text))
    return null;
  final result = double.tryParse(text.replaceAll('.', '').replaceAll(',', '.'));
  return result != null && result.isFinite ? result : null;
}

class FinanceScaffold extends StatelessWidget {
  final String title;
  final bool showAppBar;
  final Widget child;
  final List<Widget>? actions;
  final Widget? navigation;
  const FinanceScaffold({
    super.key,
    required this.title,
    this.showAppBar = true,
    required this.child,
    this.actions,
    this.navigation,
  });
  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      scaffoldBackgroundColor: OrbitHomeTokens.background,
      colorScheme: const ColorScheme.dark(
        primary: OrbitHomeTokens.purple,
        surface: OrbitHomeTokens.surface,
        onSurface: OrbitHomeTokens.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OrbitHomeTokens.surface,
        labelStyle: const TextStyle(color: OrbitHomeTokens.muted, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: OrbitHomeTokens.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    ),
    child: Scaffold(
      backgroundColor: OrbitHomeTokens.background,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: OrbitHomeTokens.background,
              foregroundColor: OrbitHomeTokens.text,
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: actions,
            )
          : null,
      bottomNavigationBar: navigation,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class FinanceEntry extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? amount;
  final VoidCallback onTap;
  const FinanceEntry({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.amount,
  });
  @override
  Widget build(BuildContext context) => OrbitHomeSurface(
    onTap: onTap,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 270 ||
            MediaQuery.textScalerOf(context).scale(12) > 15;
        Widget money() => Text(
          amount!,
          textAlign: stacked ? TextAlign.left : TextAlign.right,
          style: const TextStyle(
            color: OrbitHomeTokens.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        );
        return Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: OrbitHomeTokens.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: OrbitHomeTokens.muted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  if (amount != null && stacked) ...[
                    const SizedBox(height: 5),
                    money(),
                  ],
                ],
              ),
            ),
            if (amount != null && !stacked) ...[
              const SizedBox(width: 8),
              Flexible(flex: 2, child: money()),
            ],
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: OrbitHomeTokens.muted,
              size: 20,
            ),
          ],
        );
      },
    ),
  );
}

class FinanceButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  const FinanceButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: outlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: OrbitHomeTokens.purple,
              padding: const EdgeInsets.all(14),
              side: const BorderSide(color: OrbitHomeTokens.purple),
            ),
            child: Text(label),
          )
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: OrbitHomeTokens.purple,
              foregroundColor: OrbitHomeTokens.background,
              padding: const EdgeInsets.all(14),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
  );
}

class FinanceError extends StatelessWidget {
  final VoidCallback retry;
  const FinanceError({super.key, required this.retry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Não foi possível carregar os dados.',
            style: TextStyle(color: OrbitHomeTokens.muted),
          ),
          TextButton(onPressed: retry, child: const Text('Tentar novamente')),
        ],
      ),
    ),
  );
}
