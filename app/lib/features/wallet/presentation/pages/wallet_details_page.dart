import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_amount.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../home/data/models/wallet_model.dart';

class WalletDetailsPage extends StatelessWidget {
  final WalletModel wallet;

  const WalletDetailsPage({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          wallet.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: DuoColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DuoCard(
            borderRadius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.isShared
                      ? 'Carteira compartilhada'
                      : 'Carteira pessoal',
                  style: const TextStyle(color: DuoColors.textSecondary),
                ),
                const SizedBox(height: 12),
                DuoAmount(value: wallet.balance),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
