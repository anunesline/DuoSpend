import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/knowledge/taxonomy/duo_taxonomy.dart';
import '../../../../shared/knowledge/taxonomy/taxonomy_item.dart';

class TransactionBasicFieldsSection extends StatelessWidget {
  final TextEditingController descriptionController;
  final TextEditingController valueController;
  final String type;
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
      children: [
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descrição',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: valueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Valor',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownButtonFormField<TaxonomyItem>(
          value: selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Categoria',
            border: OutlineInputBorder(),
          ),
          items: DuoTaxonomy.items.map((category) {
            return DropdownMenuItem<TaxonomyItem>(
              value: category,
              child: Text('${category.icon} ${category.name}'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onCategoryChanged(value);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownButtonFormField<TaxonomyItem>(
          value: selectedSubcategory,
          decoration: const InputDecoration(
            labelText: 'Subcategoria',
            border: OutlineInputBorder(),
          ),
          items: subcategories.map((subcategory) {
            return DropdownMenuItem<TaxonomyItem>(
              value: subcategory,
              child: Text('${subcategory.icon} ${subcategory.name}'),
            );
          }).toList(),
          onChanged: subcategories.isEmpty ? null : onSubcategoryChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        RadioListTile<String>(
          title: const Text('Receita'),
          value: 'income',
          groupValue: type,
          onChanged: (value) {
            if (value != null) onTypeChanged(value);
          },
        ),
        RadioListTile<String>(
          title: const Text('Despesa'),
          value: 'expense',
          groupValue: type,
          onChanged: (value) {
            if (value != null) onTypeChanged(value);
          },
        ),
      ],
    );
  }
}