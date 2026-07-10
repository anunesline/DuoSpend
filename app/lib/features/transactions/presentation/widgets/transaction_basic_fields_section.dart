import 'package:flutter/material.dart';

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
        TextField(
          controller: descriptionController,
          decoration: InputDecoration(
            labelText: hasPurchaseItems
                ? 'Descrição da compra'
                : 'Descrição da transação',
            hintText: hasPurchaseItems
                ? 'Ex.: Compras do mês'
                : 'Ex.: Conta de luz, salário ou aluguel',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: valueController,
          readOnly: hasPurchaseItems,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: InputDecoration(
            labelText: hasPurchaseItems
                ? 'Total da compra'
                : 'Valor',
            prefixText: 'R\$ ',
            helperText: hasPurchaseItems
                ? 'Calculado automaticamente pelos itens'
                : null,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _TransactionTypeSelector(
          type: type,
          onTypeChanged: onTypeChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (hasPurchaseItems)
          _AutomaticClassificationCard(
            category: selectedCategory,
            subcategory: selectedSubcategory,
          )
        else ...[
          const Text(
            'Classificação financeira',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Escolha onde esta movimentação entra nas suas finanças.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<TaxonomyItem>(
            initialValue: selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Categoria do gasto',
              border: OutlineInputBorder(),
            ),
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
          DropdownButtonFormField<TaxonomyItem>(
            initialValue: selectedSubcategory,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tipo da movimentação',
              hintText: 'Selecione uma opção',
              border: OutlineInputBorder(),
            ),
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
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(
          value: 'expense',
          label: Text('Despesa'),
          icon: Icon(Icons.arrow_downward),
        ),
        ButtonSegment<String>(
          value: 'income',
          label: Text('Receita'),
          icon: Icon(Icons.arrow_upward),
        ),
      ],
      selected: {type},
      onSelectionChanged: (values) {
        if (values.isNotEmpty) {
          onTypeChanged(values.first);
        }
      },
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Classificação automática',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${category.icon} $classification',
                ),
                const SizedBox(height: 4),
                const Text(
                  'Definida a partir dos produtos adicionados.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
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