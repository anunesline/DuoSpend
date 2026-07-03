import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/catalog/taxonomy/duo_taxonomy.dart';
import '../../../../shared/catalog/taxonomy/taxonomy_item.dart';
import '../../data/models/transaction_item_model.dart';

class AddTransactionItemPage extends StatefulWidget {
  const AddTransactionItemPage({super.key});

  @override
  State<AddTransactionItemPage> createState() => _AddTransactionItemPageState();
}

class _AddTransactionItemPageState extends State<AddTransactionItemPage> {
  final nameController = TextEditingController();
  final brandController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final totalPriceController = TextEditingController();

  String unit = 'un';
  final List<String> units = ['un', 'kg', 'g', 'L', 'ml'];

  TaxonomyItem selectedCategory = DuoTaxonomy.items.first;
  TaxonomyItem? selectedSubcategory = DuoTaxonomy.items.first.children.isNotEmpty
      ? DuoTaxonomy.items.first.children.first
      : null;

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    quantityController.dispose();
    totalPriceController.dispose();
    super.dispose();
  }

  void _changeCategory(TaxonomyItem category) {
    setState(() {
      selectedCategory = category;
      selectedSubcategory =
          category.children.isNotEmpty ? category.children.first : null;
    });
  }

  void _saveItem() {
    final name = nameController.text.trim();
    final brand = brandController.text.trim();
    final quantity = double.tryParse(
      quantityController.text.replaceAll(',', '.'),
    );
    final totalPrice = double.tryParse(
      totalPriceController.text.replaceAll(',', '.'),
    );

    if (name.isEmpty || quantity == null || totalPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os dados do item.')),
      );
      return;
    }

    final item = TransactionItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      transactionId: '',
      name: name,
      brand: brand,
      quantity: quantity,
      unit: unit,
      unitPrice: totalPrice / quantity,
      totalPrice: totalPrice,
      taxonomyId: selectedSubcategory?.id ?? selectedCategory.id,
      category: selectedCategory.name,
      subcategory: selectedSubcategory?.name ?? 'Sem subcategoria',
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final subcategories = selectedCategory.children;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar item'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'O que você comprou?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: brandController,
              decoration: const InputDecoration(
                labelText: 'Marca',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<TaxonomyItem>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoria do item',
                border: OutlineInputBorder(),
              ),
              items: DuoTaxonomy.items.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text('${category.icon} ${category.name}'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) _changeCategory(value);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<TaxonomyItem>(
              value: selectedSubcategory,
              decoration: const InputDecoration(
                labelText: 'Subcategoria do item',
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
            TextField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantidade',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              value: unit,
              decoration: const InputDecoration(
                labelText: 'Unidade',
                border: OutlineInputBorder(),
              ),
              items: units.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    unit = value;
                  });
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: totalPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor total do item',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveItem,
                child: const Text('Adicionar item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}