import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/knowledge/products/product_repository.dart';
import '../../../../shared/knowledge/products/product_seed.dart';
import '../../../../shared/knowledge/taxonomy/duo_taxonomy.dart';
import '../../../../shared/knowledge/taxonomy/taxonomy_item.dart';
import '../../../../shared/widgets/product_search_field.dart';
import '../../../../shared/widgets/product_summary_card.dart';
import '../../data/models/product_model.dart';
import '../../data/models/transaction_item_model.dart';

class AddTransactionItemPage extends StatefulWidget {
  const AddTransactionItemPage({super.key});

  @override
  State<AddTransactionItemPage> createState() => _AddTransactionItemPageState();
}

class _AddTransactionItemPageState extends State<AddTransactionItemPage> {
  final ProductRepository productRepository = ProductRepository();

  final nameController = TextEditingController();
  final brandController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final totalPriceController = TextEditingController();

  List<ProductModel> productSuggestions = [];
  ProductModel? selectedProduct;

  bool get isKnownProduct => selectedProduct != null;

  String unit = 'un';
  final List<String> units = ['un', 'kg', 'g', 'L', 'ml'];

  TaxonomyItem selectedCategory = DuoTaxonomy.items.first;
  TaxonomyItem? selectedSubcategory = DuoTaxonomy.items.first.children.isNotEmpty
      ? DuoTaxonomy.items.first.children.first
      : null;

  String taxonomyId = '';

  @override
  void initState() {
    super.initState();
    ProductSeed.load(productRepository);
  }

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    quantityController.dispose();
    totalPriceController.dispose();
    super.dispose();
  }

  void _searchProducts(String query) {
    setState(() {
      selectedProduct = null;
      productSuggestions = productRepository.search(query);
    });
  }

  void _selectProduct(ProductModel product) {
    final path = _findTaxonomyPath(product.taxonomyId);

    setState(() {
      selectedProduct = product;

      nameController.text = product.name;
      brandController.text = product.brand;
      unit = product.defaultUnit;
      taxonomyId = product.taxonomyId;

      if (path.isNotEmpty) {
        selectedCategory = path.first;
        selectedSubcategory = path.length > 1 ? path[1] : null;
      }

      productSuggestions = [];
    });
  }

  List<TaxonomyItem> _findTaxonomyPath(String id) {
    for (final item in DuoTaxonomy.items) {
      final path = _findPathRecursive(item, id);
      if (path.isNotEmpty) return path;
    }

    return [];
  }

  List<TaxonomyItem> _findPathRecursive(TaxonomyItem item, String id) {
    if (item.id == id) return [item];

    for (final child in item.children) {
      final childPath = _findPathRecursive(child, id);

      if (childPath.isNotEmpty) {
        return [item, ...childPath];
      }
    }

    return [];
  }

  void _changeCategory(TaxonomyItem category) {
    setState(() {
      selectedCategory = category;
      selectedSubcategory =
          category.children.isNotEmpty ? category.children.first : null;
      taxonomyId = selectedSubcategory?.id ?? selectedCategory.id;
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
      productId: selectedProduct?.id,
      merchantId: null,
      name: name,
      brand: brand,
      quantity: quantity,
      unit: unit,
      unitPrice: totalPrice / quantity,
      totalPrice: totalPrice,
      taxonomyId: taxonomyId.isEmpty
          ? selectedSubcategory?.id ?? selectedCategory.id
          : taxonomyId,
      category: selectedCategory.name,
      subcategory: selectedSubcategory?.name ?? 'Sem subcategoria',
      productCategoryId: selectedProduct?.productCategoryId ?? '',
      productCategoryName: selectedProduct?.productCategoryName ?? '',
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
            ProductSearchField(
              suggestions: productSuggestions,
              onSearch: _searchProducts,
              onSelected: _selectProduct,
            ),
            const SizedBox(height: AppSpacing.lg),

            if (isKnownProduct)
              ProductSummaryCard(
                product: selectedProduct!,
                category: selectedCategory.name,
                subcategory: selectedSubcategory?.name ?? 'Sem subcategoria',
              )
            else ...[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do produto',
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
                          taxonomyId = value?.id ?? '';
                        });
                      },
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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