import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_amount.dart';
import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../transactions/domain/purchase/services/balance_summary.dart';

class SharedBalanceCard extends StatelessWidget {
  final BalanceSummary summary;
  final int? pendingCount;
  final VoidCallback? onTap;

  const SharedBalanceCard({
    super.key,
    required this.summary,
    this.pendingCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    double? amount;
    String? subtitle;

    if (summary.hasCredit) {
      title = 'Saldo entre vocês';
      amount = summary.amountToReceive;
    } else if (summary.hasDebt) {
      title = 'Saldo entre vocês';
      amount = -summary.amountToPay;
    } else {
      title = 'Tudo acertado';
      subtitle = 'Nenhum acerto pendente.';
    }

    return DuoCard(
      borderRadius: 22,
      padding: EdgeInsets.zero,
      gradient: const LinearGradient(
        colors: [Color(0xFF191D26), Color(0xFF121720)],
      ),
      child: Column(
        children: [
          if (pendingCount != null) ...[
            _SharedOverviewRow(
              icon: Icons.schedule_rounded,
              iconColor: const Color(0xFFF0A128),
              title: 'Pendências',
              subtitle: pendingCount == 1
                  ? '1 confirmação aguardando'
                  : '$pendingCount confirmações aguardando',
              onTap: onTap,
            ),
            const Divider(height: 1, thickness: 1, color: DuoColors.divider),
          ],
          _SharedOverviewRow(
            icon: summary.isSettled
                ? Icons.check_rounded
                : Icons.groups_rounded,
            iconColor: summary.isSettled
                ? DuoColors.success
                : DuoColors.primary,
            title: title,
            subtitle: subtitle,
            amount: amount,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _SharedOverviewRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final double? amount;
  final VoidCallback? onTap;

  const _SharedOverviewRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.amount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: iconColor.withValues(alpha: .20)),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: DuoColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (amount != null)
                      DuoAmount(
                        value: amount!.abs(),
                        prefix: amount! >= 0 ? 'Você recebe ' : 'Você deve ',
                        compact: true,
                        amountFontSize: 13,
                        color: DuoColors.primaryLight,
                      )
                    else if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: DuoColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DuoColors.textHint,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
