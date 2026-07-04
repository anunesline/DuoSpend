import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/purchase/models/purchase_item_model.dart';

class PurchaseItemsSection extends StatelessWidget {
  final List<PurchaseItemModel> items;
  final VoidCallback onAddItem;
  final void Function(PurchaseItemModel item) onRemoveItem;
  final double total;

  const PurchaseItemsSection({
    super.key,
    required this.items,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.total,
  });

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatQuantity(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
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
              'Itens (${items.length})',
              style: const TextStyle(
                fontSize: 18,
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
        if (items.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Nenhum item adicionado.\n'
                'Use essa área para detalhar compras de mercado, farmácia, casa e outros consumos.',
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
                    '${_formatQuantity(item.quantity)} ${item.unit}'
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
        const SizedBox(height: AppSpacing.md),
        if (items.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total dos itens: ${_formatMoney(total)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}