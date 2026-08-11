import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
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

    if (previewTransactions.isEmpty) {
      return DuoCard(
        borderRadius: 20,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Nenhuma movimentação encontrada.',
              style: TextStyle(
                color: DuoColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return DuoCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < previewTransactions.length; i++) ...[
            _TransactionPreviewTile(
              transaction: previewTransactions[i],
            ),
            if (i != previewTransactions.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: DuoColors.divider,
              ),
          ],
        ],
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
    final visual = _resolveCategoryVisual(transaction);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              visual.icon,
              color: visual.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DuoColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _formatDate(transaction.date),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: DuoColors.textSecondary,
                      ),
                    ),
                    _CategoryChip(
                      label: transaction.category,
                      color: visual.color,
                    ),
                    if (transaction.isSharedExpense)
                      _ConfirmationStatusChip(
                        transaction: transaction,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${isIncome ? '+' : '-'} '
            'R\$ ${transaction.value.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              color: isIncome
                  ? DuoColors.success
                  : DuoColors.error,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final target = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final differenceInDays = today.difference(target).inDays;

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';

    if (differenceInDays == 0) {
      return 'Hoje • $time';
    }

    if (differenceInDays == 1) {
      return 'Ontem • $time';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month • $time';
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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
        color: status.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 12,
            color: status.color,
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
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
        color: DuoColors.warning,
      );
    }

    if (transaction.confirmationStatus.isRejected) {
      return const _ConfirmationStatusPresentation(
        label: 'Recusada',
        icon: Icons.close_rounded,
        color: DuoColors.error,
      );
    }

    return const _ConfirmationStatusPresentation(
      label: 'Confirmada',
      icon: Icons.check_rounded,
      color: DuoColors.success,
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

class _CategoryVisual {
  final IconData icon;
  final Color color;

  const _CategoryVisual(this.icon, this.color);
}

_CategoryVisual _resolveCategoryVisual(TransactionModel transaction) {
  if (transaction.type == 'income') {
    return const _CategoryVisual(
      Icons.attach_money_rounded,
      DuoColors.success,
    );
  }

  final haystack = [
    transaction.category,
    transaction.subcategory,
    transaction.description,
  ].join(' ').toLowerCase();

  if (haystack.contains('mercado') ||
      haystack.contains('supermercado') ||
      haystack.contains('hortifr')) {
    return const _CategoryVisual(
      Icons.shopping_cart_rounded,
      DuoColors.success,
    );
  }

  if (haystack.contains('restaurante') ||
      haystack.contains('lanchonete') ||
      haystack.contains('padaria') ||
      haystack.contains('delivery')) {
    return const _CategoryVisual(
      Icons.restaurant_rounded,
      DuoColors.warning,
    );
  }

  if (haystack.contains('combust') ||
      haystack.contains('posto') ||
      haystack.contains('uber') ||
      haystack.contains('99') ||
      haystack.contains('pedágio') ||
      haystack.contains('estacionamento') ||
      haystack.contains('transporte')) {
    return const _CategoryVisual(
      Icons.local_gas_station_rounded,
      DuoColors.primaryLight,
    );
  }

  if (haystack.contains('saúde') ||
      haystack.contains('farmácia') ||
      haystack.contains('médico')) {
    return const _CategoryVisual(
      Icons.local_hospital_rounded,
      DuoColors.error,
    );
  }

  if (haystack.contains('lazer') ||
      haystack.contains('assinatura') ||
      haystack.contains('streaming')) {
    return const _CategoryVisual(
      Icons.sports_esports_rounded,
      DuoColors.primaryLight,
    );
  }

  return const _CategoryVisual(
    Icons.receipt_long_rounded,
    DuoColors.textSecondary,
  );
}
