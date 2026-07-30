import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_amount.dart';
import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';

class BalanceCard extends StatelessWidget {
  final double balance;

  const BalanceCard({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      glow: true,
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: DuoColors.glass,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: DuoColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: DuoColors.glass,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: DuoColors.border,
                  ),
                ),
                child: const Text(
                  'Disponível',
                  style: TextStyle(
                    color: DuoColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          DuoAmount(
            label: 'Saldo disponível',
            value: balance,
          ),

          const SizedBox(height: 24),

          Container(
            height: 1,
            color: DuoColors.divider,
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: DuoColors.success,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Seu saldo está atualizado.',
                  style: TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: DuoColors.textHint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}