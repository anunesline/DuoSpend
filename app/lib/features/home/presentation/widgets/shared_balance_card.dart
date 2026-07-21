import 'package:flutter/material.dart';

import '../../../transactions/domain/purchase/services/balance_summary.dart';

class SharedBalanceCard extends StatelessWidget {
  final BalanceSummary summary;

  const SharedBalanceCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;
    String title;
    String subtitle;

    if (summary.hasCredit) {
      icon = Icons.trending_up;
      color = Colors.green;
      title = 'Você tem dinheiro para receber';
      subtitle =
          'R\$ ${summary.amountToReceive.toStringAsFixed(2)}';
    } else if (summary.hasDebt) {
      icon = Icons.trending_down;
      color = Colors.red;
      title = 'Você possui um acerto pendente';
      subtitle =
          'R\$ ${summary.amountToPay.toStringAsFixed(2)}';
    } else {
      icon = Icons.check_circle_outline;
      color = Colors.blue;
      title = 'Tudo acertado';
      subtitle = 'Nenhum acerto pendente.';
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (summary.pendingTransfers > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${summary.pendingTransfers} acerto(s) pendente(s)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}