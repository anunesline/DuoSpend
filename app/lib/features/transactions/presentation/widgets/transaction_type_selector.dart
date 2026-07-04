import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class TransactionTypeSelector extends StatelessWidget {
  const TransactionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final String selectedType;
  final ValueChanged<String> onChanged;

  bool get isIncome => selectedType == 'income';
  bool get isExpense => selectedType == 'expense';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo da movimentação',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _TypeOption(
                    label: 'Despesa',
                    icon: Icons.arrow_downward,
                    selected: isExpense,
                    onTap: () => onChanged('expense'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TypeOption(
                    label: 'Receita',
                    icon: Icons.arrow_upward,
                    selected: isIncome,
                    onTap: () => onChanged('income'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.35)
              : colorScheme.surface,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color:
                        selected ? colorScheme.primary : colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}