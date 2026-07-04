import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/models/transaction_item_model.dart';

class TransactionItemsSection extends StatelessWidget {
  const TransactionItemsSection({
    super.key,
    required this.items,
    required this.onAddItem,
    required this.onRemoveItem,
  });

  final List<TransactionItemModel> items;
  final VoidCallback onAddItem;
  final void Function(TransactionItemModel item) onRemoveItem;

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Itens da compra',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.receipt_long_outlined),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Nenhum item adicionado ainda.',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Você pode detalhar produtos de mercado, farmácia, casa e outros consumos.',
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: items.map((item) {
              return Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.quantity.toStringAsFixed(2).replaceAll('.', ',')} ${item.unit}'
                    '${item.brand.isNotEmpty ? ' • ${item.brand}' : ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMoney(item.totalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => onRemoveItem(item),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}