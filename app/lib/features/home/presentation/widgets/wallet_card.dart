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
    return isShared
        ? 'Carteira compartilhada'
        : 'Carteira pessoal';
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: DuoColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _walletIcon,
              color: DuoColors.textPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Text(
                  _walletTypeLabel,
                  style: const TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Saldo ',
                        style: TextStyle(
                          color: DuoColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: 'R\$ ${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: DuoColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: DuoColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: DuoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}