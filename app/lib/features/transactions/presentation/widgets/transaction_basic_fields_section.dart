import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TransactionTypeSelector(type: type, onTypeChanged: onTypeChanged),
        const SizedBox(height: 24),
        const _FieldLabel('Valor'),
        const SizedBox(height: 8),
        DuoTextField(
          controller: valueController,
          label: hasPurchaseItems ? 'Total da compra' : 'R\$ 0,00',
          prefixText: 'R\$ ',
          readOnly: hasPurchaseItems,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          helperText: hasPurchaseItems
              ? 'Calculado automaticamente pelos itens adicionados.'
              : null,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Descrição'),
        const SizedBox(height: 8),
        DuoTextField(
          controller: descriptionController,
          label: hasPurchaseItems ? 'Descrição da compra' : 'Ex.: Supermercado',
          hintText: hasPurchaseItems ? 'Ex.: Compras do mês' : 'Ex.: Supermercado',
          icon: Icons.edit_note_rounded,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 28),
        const _SectionTitle(
          icon: Icons.category_outlined,
          title: 'Classificação financeira',
          subtitle: 'Organize esta movimentação nas suas finanças.',
        ),
        const SizedBox(height: 16),
        if (hasPurchaseItems)
          _AutomaticClassificationCard(
            category: selectedCategory,
            subcategory: selectedSubcategory,
          )
        else ...[
          DuoDropdown<TaxonomyItem>(
            label: 'Categoria',
            value: selectedCategory,
            icon: Icons.folder_outlined,
            items: DuoTaxonomy.items.map((category) {
              return DropdownMenuItem<TaxonomyItem>(
                value: category,
                child: Text('${category.icon} ${category.name}', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onCategoryChanged(value);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DuoDropdown<TaxonomyItem>(
            key: ValueKey('transaction-subcategory-${selectedCategory.id}-${selectedSubcategory?.id}'),
            label: 'Subcategoria',
            value: selectedSubcategory,
            hintText: 'Selecione uma opção',
            icon: Icons.sell_outlined,
            items: subcategories.map((subcategory) {
              return DropdownMenuItem<TaxonomyItem>(
                value: subcategory,
                child: Text('${subcategory.icon} ${subcategory.name}', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: subcategories.isEmpty ? null : onSubcategoryChanged,
          ),
        ],
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: DuoColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionTitle({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: DuoColors.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: DuoColors.primaryLight, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: DuoColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: DuoColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      );
}

class _TransactionTypeSelector extends StatelessWidget {
  final String type;
  final ValueChanged<String> onTypeChanged;
  const _TransactionTypeSelector({required this.type, required this.onTypeChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: DuoColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DuoColors.border),
        ),
        child: Row(
          children: [
            Expanded(child: _TypeOption(label: 'Despesa', icon: Icons.arrow_upward_rounded, isSelected: type == 'expense', accentColor: DuoColors.error, onTap: () => onTypeChanged('expense'))),
            const SizedBox(width: 4),
            Expanded(child: _TypeOption(label: 'Receita', icon: Icons.arrow_downward_rounded, isSelected: type == 'income', accentColor: DuoColors.success, onTap: () => onTypeChanged('income'))),
          ],
        ),
      );
}

class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  const _TypeOption({required this.label, required this.icon, required this.isSelected, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withValues(alpha: .14) : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: isSelected ? accentColor : DuoColors.textSecondary),
              const SizedBox(width: 7),
              Text(label, style: TextStyle(color: isSelected ? DuoColors.textPrimary : DuoColors.textSecondary, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
}

class _AutomaticClassificationCard extends StatelessWidget {
  final TaxonomyItem category;
  final TaxonomyItem? subcategory;
  const _AutomaticClassificationCard({required this.category, required this.subcategory});

  @override
  Widget build(BuildContext context) {
    final classification = subcategory == null ? category.name : '${category.name} › ${subcategory!.name}';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DuoColors.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DuoColors.primary.withValues(alpha: .24)),
      ),
      child: Row(
        children: [
          Text(category.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Classificação automática', style: TextStyle(color: DuoColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(classification, style: const TextStyle(color: DuoColors.textPrimary, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
