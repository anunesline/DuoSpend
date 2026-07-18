import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/purchase/models/purchase_item_model.dart';
import 'purchase_item_card.dart';

class PurchaseItemsSection extends StatelessWidget {
  final List<PurchaseItemModel> items;
  final VoidCallback onAddItem;
  final void Function(PurchaseItemModel item) onRemoveItem;
  final void Function(PurchaseItemModel item)? onEditItem;
  final double total;

  const PurchaseItemsSection({
    super.key,
    required this.items,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.total,
    this.onEditItem,
  });

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<bool?> _confirmRemoveItem(
    BuildContext context,
    PurchaseItemModel item,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          icon: Icon(
            Icons.delete_outline,
            color: colorScheme.error,
          ),
          title: const Text('Excluir item?'),
          content: Text(
            'Deseja remover "${item.name}" desta compra?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _showRemovedMessage(
    BuildContext context,
    PurchaseItemModel item,
  ) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${item.name} removido da compra.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Itens da compra',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          items.isEmpty
              ? 'Adicione os produtos que fazem parte desta compra.'
              : '${items.length} ${items.length == 1 ? 'item adicionado' : 'itens adicionados'}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
            );
          },
          child: items.isEmpty
              ? _EmptyItemsCard(
                  key: const ValueKey('empty-purchase-items'),
                  onAddItem: onAddItem,
                )
              : Column(
                  key: ValueKey(
                    'purchase-items-${items.length}-${items.map((item) => item.hashCode).join('-')}',
                  ),
                  children: [
                    for (var index = 0; index < items.length; index++)
                      _AnimatedPurchaseItem(
                        key: ValueKey(items[index]),
                        index: index,
                        child: Dismissible(
                          key: ValueKey(
                            'purchase-item-${items[index].hashCode}-$index',
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) {
                            return _confirmRemoveItem(
                              context,
                              items[index],
                            );
                          },
                          onDismissed: (_) {
                            final removedItem = items[index];

                            onRemoveItem(removedItem);
                            _showRemovedMessage(
                              context,
                              removedItem,
                            );
                          },
                          background: _DeleteBackground(
                            colorScheme: colorScheme,
                          ),
                          child: PurchaseItemCard(
                            item: items[index],
                            onTap: onEditItem == null
                                ? null
                                : () {
                                    onEditItem!(items[index]);
                                  },
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _ItemsTotalCard(
            total: total,
            formattedTotal: _formatMoney(total),
          ),
        ],
      ],
    );
  }
}

class _AnimatedPurchaseItem extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedPurchaseItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final delay = index > 5 ? 250 : index * 50;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 260 + delay),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(
        begin: 0,
        end: 1,
      ),
      builder: (context, value, animatedChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              0,
              12 * (1 - value),
            ),
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }
}

class _EmptyItemsCard extends StatelessWidget {
  final VoidCallback onAddItem;

  const _EmptyItemsCard({
    super.key,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.shopping_basket_outlined,
              color: colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhum item adicionado',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Detalhe compras de mercado, farmácia, casa e outros consumos.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onAddItem,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar primeiro item'),
          ),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  final ColorScheme colorScheme;

  const _DeleteBackground({
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Excluir',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ItemsTotalCard extends StatelessWidget {
  final double total;
  final String formattedTotal;

  const _ItemsTotalCard({
    required this.total,
    required this.formattedTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total dos itens',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  total > 0
                      ? 'Soma dos subtotais da compra'
                      : 'Preencha os valores dos itens',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formattedTotal,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}