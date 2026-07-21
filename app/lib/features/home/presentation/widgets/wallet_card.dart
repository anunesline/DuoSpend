import 'package:flutter/material.dart';

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
        : 'Carteira individual';
  }

  IconData get _walletIcon {
    return isShared ? Icons.groups_rounded : Icons.person_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF4F46E5),
                child: Icon(
                  _walletIcon,
                  color: Colors.white,
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _walletTypeLabel,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Saldo: R\$ ${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}