import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/purchase/models/purchase_item_model.dart';

class PurchaseItemCard extends StatelessWidget {
  final PurchaseItemModel item;
  final VoidCallback? onTap;

  final String? selectedConsumer;
  final ValueChanged<String>? onConsumerChanged;
  final String currentMemberLabel;
  final String partnerMemberLabel;

  const PurchaseItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.selectedConsumer,
    this.onConsumerChanged,
    this.currentMemberLabel = 'Eu',
    this.partnerMemberLabel = 'Parceiro',
  });

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatQuantity(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r',$'), '')
        .replaceAll('.', ',');
  }

  String get _categoryLabel {
    final category = item.productCategoryName.trim();

    if (category.isEmpty) {
      return 'Sem categoria';
    }

    return category;
  }

  String get _brandLabel {
    final brand = item.brand.trim();

    if (brand.isEmpty) {
      return 'Sem marca';
    }

    return brand;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(
        bottom: AppSpacing.sm,
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.7,
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          colorScheme.primaryContainer,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.shopping_basket_outlined,
                      color:
                          colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(
                    width: AppSpacing.md,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: theme
                              .textTheme.titleMedium
                              ?.copyWith(
                            fontWeight:
                                FontWeight.w700,
                            color:
                                colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(
                          height: AppSpacing.xs,
                        ),
                        Text(
                          _brandLabel,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: theme
                              .textTheme.bodyMedium
                              ?.copyWith(
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: AppSpacing.sm,
                  ),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatMoney(
                          item.totalPrice,
                        ),
                        style: theme
                            .textTheme.titleMedium
                            ?.copyWith(
                          fontWeight:
                              FontWeight.w800,
                          color:
                              colorScheme.onSurface,
                        ),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(
                          height: AppSpacing.xs,
                        ),
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: colorScheme
                              .onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: AppSpacing.md,
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _InformationChip(
                    icon: Icons.category_outlined,
                    label: _categoryLabel,
                  ),
                  _InformationChip(
                    icon:
                        Icons.inventory_2_outlined,
                    label:
                        '${_formatQuantity(item.quantity)} ${item.unit.trim()}',
                  ),
                ],
              ),
              const SizedBox(
                height: AppSpacing.md,
              ),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant,
              ),
              if (onConsumerChanged != null) ...[
                const SizedBox(
                  height: AppSpacing.md,
                ),
                Text(
                  'Consumido por',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(
                  height: AppSpacing.sm,
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _ConsumerChip(
                      label: currentMemberLabel,
                      value: 'me',
                      selected:
                          selectedConsumer == 'me',
                      onSelected:
                          onConsumerChanged,
                    ),
                    _ConsumerChip(
                      label: partnerMemberLabel,
                      value: 'partner',
                      selected: selectedConsumer ==
                          'partner',
                      onSelected:
                          onConsumerChanged,
                    ),
                    _ConsumerChip(
                      label: 'Ambos',
                      value: 'both',
                      selected:
                          selectedConsumer == 'both',
                      onSelected:
                          onConsumerChanged,
                    ),
                  ],
                ),
                const SizedBox(
                  height: AppSpacing.md,
                ),
                Divider(
                  height: 1,
                  color:
                      colorScheme.outlineVariant,
                ),
              ],
              const SizedBox(
                height: AppSpacing.md,
              ),
              Row(
                children: [
                  Expanded(
                    child: _PriceInformation(
                      label: 'Preço unitário',
                      value: _formatMoney(
                        item.unitPrice,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color:
                        colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: _PriceInformation(
                      label: 'Subtotal',
                      value: _formatMoney(
                        item.totalPrice,
                      ),
                      alignEnd: true,
                      emphasized: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsumerChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String>? onSelected;

  const _ConsumerChip({
    required this.label,
    required this.value,
    required this.selected,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      onSelected: onSelected == null
          ? null
          : (_) {
              onSelected!(value);
            },
    );
  }
}

class _InformationChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InformationChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer
            .withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color:
                colorScheme.onSecondaryContainer,
          ),
          const SizedBox(
            width: AppSpacing.xs,
          ),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme
                    .onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceInformation extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;
  final bool emphasized;

  const _PriceInformation({
    required this.label,
    required this.value,
    this.alignEnd = false,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(
          height: AppSpacing.xs,
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: emphasized
                ? FontWeight.w800
                : FontWeight.w600,
            color: emphasized
                ? colorScheme.primary
                : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}