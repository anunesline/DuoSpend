import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../../core/design_system/duo_dropdown.dart';
import '../../../../core/design_system/duo_text_field.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/knowledge/taxonomy/duo_taxonomy.dart';
import '../../../../shared/knowledge/taxonomy/taxonomy_item.dart';

class TransactionBasicFieldsSection extends StatelessWidget {
  final TextEditingController descriptionController;
  final TextEditingController valueController;

  final String type;
  final bool hasPurchaseItems;

  final TaxonomyItem selectedCategory;
  final TaxonomyItem? selectedSubcategory;

  final ValueChanged<String> onTypeChanged;
  final ValueChanged<TaxonomyItem> onCategoryChanged;
  final ValueChanged<TaxonomyItem?> onSubcategoryChanged;

  const TransactionBasicFieldsSection({
    super.key,
    required this.descriptionController,
    required this.valueController,
    required this.type,
    required this.hasPurchaseItems,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onSubcategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subcategories = selectedCategory.children;

    return DuoCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            icon: Icons.receipt_long_rounded,
            title: 'Dados da movimentação',
            subtitle: 'Preencha as informações principais.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _TransactionTypeSelector(
            type: type,
            onTypeChanged: onTypeChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          DuoTextField(
            controller: descriptionController,
            label: hasPurchaseItems
                ? 'Descrição da compra'
                : 'Descrição',
            hintText: hasPurchaseItems
                ? 'Ex.: Compras do mês'
                : 'Ex.: Conta de luz, salário ou aluguel',
            icon: Icons.edit_note_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          DuoTextField(
            controller: valueController,
            label: hasPurchaseItems
                ? 'Total da compra'
                : 'Valor',
            prefixText: 'R\$ ',
            icon: Icons.payments_outlined,
            readOnly: hasPurchaseItems,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            helperText: hasPurchaseItems
                ? 'Calculado automaticamente pelos itens adicionados.'
                : null,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (hasPurchaseItems)
            _AutomaticClassificationCard(
              category: selectedCategory,
              subcategory: selectedSubcategory,
            )
          else ...[
            const _SectionDivider(),
            const SizedBox(height: AppSpacing.xl),
            const _SectionHeader(
              icon: Icons.category_rounded,
              title: 'Classificação financeira',
              subtitle:
                  'Escolha onde esta movimentação entra nas suas finanças.',
            ),
            const SizedBox(height: AppSpacing.lg),
            DuoDropdown<TaxonomyItem>(
              label: 'Categoria',
              value: selectedCategory,
              icon: Icons.folder_outlined,
              items: DuoTaxonomy.items.map((category) {
                return DropdownMenuItem<TaxonomyItem>(
                  value: category,
                  child: Text(
                    '${category.icon} ${category.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onCategoryChanged(value);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            DuoDropdown<TaxonomyItem>(
              key: ValueKey(
                'transaction-subcategory-'
                '${selectedCategory.id}-'
                '${selectedSubcategory?.id}',
              ),
              label: 'Tipo da movimentação',
              value: selectedSubcategory,
              hintText: 'Selecione uma opção',
              icon: Icons.sell_outlined,
              items: subcategories.map((subcategory) {
                return DropdownMenuItem<TaxonomyItem>(
                  value: subcategory,
                  child: Text(
                    '${subcategory.icon} ${subcategory.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: subcategories.isEmpty
                  ? null
                  : onSubcategoryChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: DuoColors.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DuoColors.primary.withValues(alpha: .24),
            ),
          ),
          child: Icon(
            icon,
            color: DuoColors.primaryLight,
            size: 21,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: DuoColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: DuoColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionTypeSelector extends StatelessWidget {
  final String type;
  final ValueChanged<String> onTypeChanged;

  const _TransactionTypeSelector({
    required this.type,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo',
          style: TextStyle(
            color: DuoColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: DuoColors.background.withValues(alpha: .48),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: DuoColors.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TypeOption(
                  label: 'Despesa',
                  icon: Icons.north_east_rounded,
                  isSelected: type == 'expense',
                  accentColor: DuoColors.error,
                  onTap: () => onTypeChanged('expense'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _TypeOption(
                  label: 'Receita',
                  icon: Icons.south_west_rounded,
                  isSelected: type == 'income',
                  accentColor: DuoColors.success,
                  onTap: () => onTypeChanged('income'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: .13)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: .36)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? accentColor
                    : DuoColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? DuoColors.textPrimary
                        : DuoColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutomaticClassificationCard extends StatelessWidget {
  final TaxonomyItem category;
  final TaxonomyItem? subcategory;

  const _AutomaticClassificationCard({
    required this.category,
    required this.subcategory,
  });

  @override
  Widget build(BuildContext context) {
    final classification = subcategory == null
        ? category.name
        : '${category.name} › ${subcategory!.name}';

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DuoColors.primary.withValues(alpha: .15),
            DuoColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DuoColors.primary.withValues(alpha: .30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DuoColors.primary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: DuoColors.primaryLight,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Classificação automática',
                  style: TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${category.icon} $classification',
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Definida com base nos produtos adicionados.',
                  style: TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: DuoColors.border,
    );
  }
}
