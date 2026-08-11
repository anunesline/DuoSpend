import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';

class WalletCard extends StatelessWidget {
  final String walletName;
  final double balance;
  final bool isShared;
  final VoidCallback? onTap;

  const WalletCard({
    super.key,
    required this.walletName,
    required this.balance,
    this.isShared = false,
    this.onTap,
  });

  String get _walletTypeLabel {
    return isShared ? 'Compartilhada' : 'Pessoal';
  }

  IconData get _walletIcon {
    return isShared
        ? Icons.groups_rounded
        : Icons.person_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      onTap: onTap,
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: DuoColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _walletIcon,
              color: DuoColors.textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  walletName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _walletTypeLabel,
                  style: const TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
              color: DuoColors.primaryLight,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: DuoColors.textHint,
            size: 22,
          ),
        ],
      ),
    );
  }
}
