import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_amount.dart';
import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      glow: true,
      borderRadius: 28,
      gradient: DuoColors.heroGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visão financeira',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: DuoColors.primaryLight,
                        letterSpacing: .2,
                      ),
                    ),
                    SizedBox(height: 5),
                    _AvailableLabel(),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: DuoColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: DuoColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DuoAmount(
            value: balance,
            amountFontSize: 34,
          ),
          const SizedBox(height: 22),
          Container(
            height: 1,
            color: DuoColors.divider,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FlowStat(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Entradas no mês',
                  value: income,
                  accentColor: DuoColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                color: DuoColors.divider,
              ),
              Expanded(
                child: _FlowStat(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Saídas no mês',
                  value: expense,
                  accentColor: DuoColors.error,
                  amountColor: DuoColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvailableLabel extends StatelessWidget {
  const _AvailableLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Saldo atual',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DuoColors.textSecondary,
            letterSpacing: .1,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.visibility_off_rounded,
          size: 15,
          color: DuoColors.textHint,
        ),
      ],
    );
  }
}

class _FlowStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color accentColor;
  final Color? amountColor;

  const _FlowStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DuoAmount(
          value: value,
          compact: true,
          amountFontSize: 16,
          color: amountColor ?? accentColor,
        ),
      ],
    );
  }
}
