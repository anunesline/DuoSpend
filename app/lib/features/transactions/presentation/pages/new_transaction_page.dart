import 'package:flutter/material.dart';

import '../../../../shared/catalog/taxonomy/duo_taxonomy.dart';
import '../../../../shared/catalog/taxonomy/taxonomy_item.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/transaction_controller.dart';

class NewTransactionPage extends StatefulWidget {
  const NewTransactionPage({super.key});

  @override
  State<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends State<NewTransactionPage> {
  final descriptionController = TextEditingController();
  final valueController = TextEditingController();
  final controller = TransactionController();

  String type = 'expense';

  TaxonomyItem selectedCategory = DuoTaxonomy.items.first;
  TaxonomyItem? selectedSubcategory = DuoTaxonomy.items.first.children.isNotEmpty
      ? DuoTaxonomy.items.first.children.first
      : null;

  @override
  void dispose() {
    descriptionController.dispose();
    valueController.dispose();
    super.dispose();
  }

  void _changeCategory(TaxonomyItem category) {
    setState(() {
      selectedCategory = category;
      selectedSubcategory =
          category.children.isNotEmpty ? category.children.first : null;
    });
  }

  Future<void> _saveTransaction() async {
    final description = descriptionController.text.trim();
    final value = double.tryParse(
      valueController.text.replaceAll(',', '.'),
    );

    if (description.isEmpty || value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos.'),
        ),
      );
      return;
    }

    await controller.saveTransaction(
      description: description,
      value: value,
      type: type,
      category: selectedCategory.name,
      subcategory: selectedSubcategory?.name ?? 'Sem subcategoria',
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subcategories = selectedCategory.children;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Transação'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
                return DropdownMenuItem(
                  value: category,
                  child: Text('${category.icon} ${category.name}'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _changeCategory(value);
                }
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
                return DropdownMenuItem(
                  value: subcategory,
                  child: Text('${subcategory.icon} ${subcategory.name}'),
                );
              }).toList(),
              onChanged: subcategories.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        selectedSubcategory = value;
                      });
                    },
            ),
            const SizedBox(height: AppSpacing.lg),
            RadioListTile<String>(
              title: const Text('Receita'),
              value: 'income',
              groupValue: type,
              onChanged: (value) {
                setState(() {
                  type = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Despesa'),
              value: 'expense',
              groupValue: type,
              onChanged: (value) {
                setState(() {
                  type = value!;
                });
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}