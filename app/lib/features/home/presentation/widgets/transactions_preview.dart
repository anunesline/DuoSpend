import 'package:flutter/material.dart';

import '../../../transactions/data/models/transaction_model.dart';

class TransactionsPreview extends StatelessWidget {
  final List<TransactionModel> transactions;
  final VoidCallback? onViewAll;

  const TransactionsPreview({
    super.key,
    required this.transactions,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final previewTransactions = transactions.take(5).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Últimas movimentações',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('Ver todas'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (previewTransactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 20,
                  ),
                  child: Text(
                    'Nenhuma movimentação encontrada.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ...previewTransactions.map(
                (transaction) => _TransactionPreviewTile(
                  transaction: transaction,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TransactionPreviewTile extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionPreviewTile({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? Colors.green.withValues(alpha: 0.12)
              : Colors.red.withValues(alpha: 0.12),
          child: Icon(
            isIncome
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: isIncome
                ? Colors.green
                : Colors.red,
          ),
        ),
        title: Text(
          transaction.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(
            top: 4,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _formatDate(transaction.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (transaction.isSharedExpense)
                _ConfirmationStatusChip(
                  transaction: transaction,
                ),
            ],
          ),
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'} '
          'R\$ ${transaction.value.toStringAsFixed(2).replaceAll('.', ',')}',
          style: TextStyle(
            color: isIncome
                ? Colors.green
                : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }
}

class _ConfirmationStatusChip extends StatelessWidget {
  final TransactionModel transaction;

  const _ConfirmationStatusChip({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final status = _resolveStatus();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 13,
            color: status.color,
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _ConfirmationStatusPresentation _resolveStatus() {
    if (transaction.isAwaitingConfirmation) {
      return const _ConfirmationStatusPresentation(
        label: 'Pendente',
        icon: Icons.schedule_rounded,
        color: Colors.orange,
      );
    }

    if (transaction.confirmationStatus.isRejected) {
      return const _ConfirmationStatusPresentation(
        label: 'Recusada',
        icon: Icons.close_rounded,
        color: Colors.red,
      );
    }

    return const _ConfirmationStatusPresentation(
      label: 'Confirmada',
      icon: Icons.check_rounded,
      color: Colors.green,
    );
  }
}

class _ConfirmationStatusPresentation {
  final String label;
  final IconData icon;
  final Color color;

  const _ConfirmationStatusPresentation({
    required this.label,
    required this.icon,
    required this.color,
  });
}