import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_amount.dart';
import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';

class SummaryCard extends StatelessWidget {
  final double income;
  final double expense;

  const SummaryCard({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryItem(
            title: 'Receitas',
            value: income,
            icon: Icons.south_west_rounded,
            accent: DuoColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryItem(
            title: 'Despesas',
            value: expense,
            icon: Icons.north_east_rounded,
            accent: DuoColors.error,
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color accent;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 22,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: DuoColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          DuoAmount(
            value: value,
            compact: true,
            color: accent,
          ),
        ],
      ),
    );
  }
}