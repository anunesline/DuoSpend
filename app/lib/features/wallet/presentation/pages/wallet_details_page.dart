import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_amount.dart';
import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../../core/design_system/duo_page_scaffold.dart';
import '../../../home/data/models/wallet_model.dart';

class WalletDetailsPage extends StatelessWidget {
  final WalletModel wallet;

  const WalletDetailsPage({super.key, required this.wallet});

  String get _updatedAt =>
      DateFormat("d 'de' MMM", 'pt_BR').format(wallet.updatedAt);

  @override
  Widget build(BuildContext context) {
    return DuoPageScaffold(
      title: wallet.name,
      eyebrow: wallet.isShared ? 'Carteira compartilhada' : 'Carteira pessoal',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DuoCard(
            glow: true,
            borderRadius: 28,
            gradient: DuoColors.heroGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: DuoColors.primaryGradient,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        wallet.isShared
                            ? Icons.groups_rounded
                            : Icons.account_balance_wallet_rounded,
                        color: DuoColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saldo disponível',
                            style: TextStyle(
                              color: DuoColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            wallet.isShared
                                ? 'Visão de vocês'
                                : 'Sua visão financeira',
                            style: const TextStyle(
                              color: DuoColors.primaryLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                DuoAmount(value: wallet.balance, amountFontSize: 36),
                const SizedBox(height: 20),
                Container(height: 1, color: DuoColors.divider),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.sync_rounded,
                      size: 16,
                      color: DuoColors.textHint,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Atualizada $_updatedAt',
                      style: const TextStyle(
                        color: DuoColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Sobre esta carteira',
            style: TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -.35,
            ),
          ),
          const SizedBox(height: 12),
          DuoCard(
            padding: EdgeInsets.zero,
            borderRadius: 20,
            child: Column(
              children: [
                _DetailRow(
                  icon: wallet.isShared
                      ? Icons.groups_outlined
                      : Icons.person_outline_rounded,
                  label: 'Tipo',
                  value: wallet.isShared ? 'Compartilhada' : 'Individual',
                ),
                const _Divider(),
                _DetailRow(
                  icon: Icons.people_outline_rounded,
                  label: 'Participantes',
                  value: wallet.memberCount == 0
                      ? 'Somente você'
                      : '${wallet.memberCount} '
                            '${wallet.memberCount == 1 ? 'pessoa' : 'pessoas'}',
                ),
                const _Divider(),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Criada em',
                  value: DateFormat(
                    "d 'de' MMM 'de' y",
                    'pt_BR',
                  ).format(wallet.createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          DuoCard(
            borderRadius: 20,
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: DuoColors.primaryLight,
                  size: 21,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Os lançamentos, cartões e metas vinculados continuam disponíveis pela sua Home.',
                    style: TextStyle(
                      color: DuoColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    child: Row(
      children: [
        Icon(icon, color: DuoColors.primaryLight, size: 20),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: DuoColors.divider,
  );
}
