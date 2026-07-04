import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/models/transaction_item_model.dart';

class TransactionSummaryCard extends StatelessWidget {
  const TransactionSummaryCard({
    super.key,
    required this.items,
    required this.manualValue,
  });

  final List<TransactionItemModel> items;
  final double? manualValue;

  double get itemsTotal {
    return items.fold<double>(
      0,
      (total, item) => total + item.totalPrice,
    );
  }

  double get total {
    if (items.isNotEmpty) {
      return itemsTotal;
    }

    return manualValue ?? 0;
  }

  double get totalQuantity {
    return items.fold<double>(
      0,
      (total, item) => total + item.quantity,
    );
  }

  double get averageTicket {
    if (items.isEmpty) return 0;
    return itemsTotal / items.length;
  }

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatQuantity(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo da compra',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),

            _SummaryRow(
              label: 'Total',
              value: _formatMoney(total),
              isPrimary: true,
            ),

            const Divider(height: AppSpacing.xl),

            _SummaryRow(
              label: 'Itens',
              value: '${items.length}',
            ),
            const SizedBox(height: AppSpacing.sm),

            _SummaryRow(
              label: 'Quantidade total',
              value: _formatQuantity(totalQuantity),
            ),
            const SizedBox(height: AppSpacing.sm),

            _SummaryRow(
              label: 'Ticket médio',
              value: _formatMoney(averageTicket),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isPrimary = false,
  });

  final String label;
  final String value;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final textStyle = isPrimary
        ? Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            )
        : Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: textStyle,
        ),
      ],
    );
  }
}