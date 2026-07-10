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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ProductRepository productRepository = ProductRepository();

  final TextEditingController nameController = TextEditingController();

  final TextEditingController brandController = TextEditingController();

  final TextEditingController quantityController = TextEditingController(
    text: '1',
  );

  final TextEditingController totalPriceController = TextEditingController();

  List<ProductModel> productSuggestions = [];

  ProductModel? selectedProduct;

  bool _isApplyingSelectedProduct = false;
  bool _showValidationErrors = false;

  String unit = 'un';

  final List<String> units = [
    'un',
    'kg',
    'g',
    'L',
    'ml',
    'lata',
    'garrafa',
    'pacote',
    'caixa',
    'frasco',
    'sachê',
    'bandeja',
    'pote',
    'rolo',
    'dúzia',
  ];

  TaxonomyItem selectedFinancialCategory = DuoTaxonomy.items.first;

  TaxonomyItem? selectedFinancialSubcategory =
      DuoTaxonomy.items.first.children.isNotEmpty
      ? DuoTaxonomy.items.first.children.first
      : null;

  TaxonomyItem? selectedProductCategory;

  bool get isKnownProduct => selectedProduct != null;

  bool get hasValidProductName {
    return nameController.text.trim().isNotEmpty;
  }

  List<TaxonomyItem> get financialSubcategories {
    return selectedFinancialCategory.children;
  }

  List<TaxonomyItem> get productCategories {
    return selectedFinancialSubcategory?.children ?? const [];
  }

  ProductModel? get productForSummary {
    final product = selectedProduct;

    if (product == null) {
      return null;
    }

    final currentName = nameController.text.trim();
    final currentBrand = brandController.text.trim();

    return ProductModel(
      id: product.id,
      name: currentName.isEmpty ? product.name : currentName,
      normalizedName: currentName.isEmpty
          ? product.normalizedName
          : _normalize(currentName),
      brand: currentBrand,
      barcode: product.barcode,
      defaultUnit: unit,
      productCategoryId: product.productCategoryId,
      productCategoryName: product.productCategoryName,
      taxonomyId: product.taxonomyId,
      averagePrice: product.averagePrice,
      lastPrice: product.lastPrice,
      lastMerchantId: product.lastMerchantId,
      favorite: product.favorite,
      createdAt: product.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  void initState() {
    super.initState();

    ProductSeed.load(productRepository);
    _setDefaultProductCategory();

    nameController.addListener(_handleProductDataChanged);
    brandController.addListener(_handleProductDataChanged);
  }

  @override
  void dispose() {
    nameController.removeListener(_handleProductDataChanged);
    brandController.removeListener(_handleProductDataChanged);

    nameController.dispose();
    brandController.dispose();
    quantityController.dispose();
    totalPriceController.dispose();

    super.dispose();
  }

  String _normalize(String value) {
    return productRepository.normalize(value);
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _handleProductDataChanged() {
    if (_isApplyingSelectedProduct) {
      return;
    }

    final product = selectedProduct;

    if (product == null) {
      return;
    }

    final currentName = _normalize(nameController.text);
    final selectedName = _normalize(product.name);

    if (currentName != selectedName) {
      setState(() {
        selectedProduct = null;
      });

      return;
    }

    final currentBrand = _normalize(brandController.text);
    final selectedBrand = _normalize(product.brand);

    if (currentBrand != selectedBrand) {
      setState(() {});
    }
  }

  void _setDefaultProductCategory() {
    final categories = productCategories;

    selectedProductCategory = categories.isNotEmpty ? categories.first : null;
  }

  void _searchProducts(String query) {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      setState(() {
        productSuggestions = [];
      });

      return;
    }

    setState(() {
      productSuggestions = productRepository.search(normalizedQuery);
    });
  }

  void _selectProduct(ProductModel product) {
    final path = _findTaxonomyPath(product.taxonomyId);

    _isApplyingSelectedProduct = true;

    setState(() {
      selectedProduct = product;

      nameController.text = product.name;
      brandController.text = product.brand;

      unit = product.defaultUnit;

      if (!units.contains(unit)) {
        units.add(unit);
      }

      if (path.isNotEmpty) {
        selectedFinancialCategory = path.first;

        selectedFinancialSubcategory = path.length > 1 ? path[1] : null;

        selectedProductCategory = path.length > 2 ? path[2] : null;
      }

      productSuggestions = [];
      _showValidationErrors = false;
    });

    _isApplyingSelectedProduct = false;

    FocusScope.of(context).unfocus();
  }

  List<TaxonomyItem> _findTaxonomyPath(String id) {
    for (final item in DuoTaxonomy.items) {
      final path = _findPathRecursive(item, id);

      if (path.isNotEmpty) {
        return path;
      }
    }

    return [];
  }

  List<TaxonomyItem> _findPathRecursive(TaxonomyItem item, String id) {
    if (item.id == id) {
      return [item];
    }

    for (final child in item.children) {
      final childPath = _findPathRecursive(child, id);

      if (childPath.isNotEmpty) {
        return [item, ...childPath];
      }
    }

    return [];
  }

  void _changeFinancialCategory(TaxonomyItem category) {
    setState(() {
      selectedFinancialCategory = category;

      selectedFinancialSubcategory = category.children.isNotEmpty
          ? category.children.first
          : null;

      _setDefaultProductCategory();
      selectedProduct = null;
    });
  }

  void _changeFinancialSubcategory(TaxonomyItem? subcategory) {
    setState(() {
      selectedFinancialSubcategory = subcategory;
      _setDefaultProductCategory();
      selectedProduct = null;
    });
  }

  void _changeProductCategory(TaxonomyItem? category) {
    setState(() {
      selectedProductCategory = category;
      selectedProduct = null;
    });
  }

  ProductModel? _findExistingProduct({
    required String name,
    required String brand,
  }) {
    final normalizedName = _normalize(name);
    final normalizedBrand = _normalize(brand);

    final products = productRepository.search(name);

    for (final product in products) {
      final sameName = _normalize(product.normalizedName) == normalizedName;

      final sameBrand = _normalize(product.brand) == normalizedBrand;

      if (sameName && sameBrand) {
        return product;
      }
    }

    return null;
  }

  bool _selectedProductMatchesCurrentFields() {
    final product = selectedProduct;

    if (product == null) {
      return false;
    }

    return _normalize(product.name) == _normalize(nameController.text) &&
        _normalize(product.brand) == _normalize(brandController.text);
  }

  ProductModel _resolveAndSaveProduct({
    required String name,
    required String brand,
    required String taxonomyId,
    required String productCategoryId,
    required String productCategoryName,
    required double unitPrice,
  }) {
    if (_selectedProductMatchesCurrentFields()) {
      return selectedProduct!;
    }

    final existingProduct = _findExistingProduct(name: name, brand: brand);

    if (existingProduct != null) {
      return existingProduct;
    }

    final now = DateTime.now();

    final newProduct = ProductModel(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      normalizedName: _normalize(name),
      brand: brand,
      barcode: '',
      defaultUnit: unit,
      productCategoryId: productCategoryId,
      productCategoryName: productCategoryName,
      taxonomyId: taxonomyId,
      averagePrice: unitPrice,
      lastPrice: unitPrice,
      lastMerchantId: '',
      favorite: false,
      createdAt: now,
      updatedAt: now,
    );

    productRepository.save(newProduct);

    return newProduct;
  }

  String? _validateQuantity(String? value) {
    final quantity = _parseNumber(value ?? '');

    if (quantity == null || quantity <= 0) {
      return 'Informe uma quantidade válida.';
    }

    return null;
  }

  String? _validateTotalPrice(String? value) {
    final totalPrice = _parseNumber(value ?? '');

    if (totalPrice == null || totalPrice <= 0) {
      return 'Informe um valor válido.';
    }

    return null;
  }

  void _saveItem() {
    FocusScope.of(context).unfocus();

    setState(() {
      _showValidationErrors = true;
    });

    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (!hasValidProductName || !isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confira os campos obrigatórios destacados.'),
        ),
      );

      return;
    }

    final name = nameController.text.trim();
    final brand = brandController.text.trim();

    final quantity = _parseNumber(quantityController.text)!;

    final totalPrice = _parseNumber(totalPriceController.text)!;

    final productCategoryId =
        selectedProduct?.productCategoryId ?? selectedProductCategory?.id ?? '';

    final productCategoryName =
        selectedProduct?.productCategoryName ??
        selectedProductCategory?.name ??
        '';

    final taxonomyId =
        selectedProduct?.taxonomyId ??
        selectedProductCategory?.id ??
        selectedFinancialSubcategory?.id ??
        selectedFinancialCategory.id;

    final unitPrice = totalPrice / quantity;

    final product = _resolveAndSaveProduct(
      name: name,
      brand: brand,
      taxonomyId: taxonomyId,
      productCategoryId: productCategoryId,
      productCategoryName: productCategoryName,
      unitPrice: unitPrice,
    );

    final item = TransactionItemModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      transactionId: '',
      productId: product.id,
      merchantId: null,
      name: product.name,
      brand: product.brand,
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      taxonomyId: product.taxonomyId,
      category: selectedFinancialCategory.name,
      subcategory: selectedFinancialSubcategory?.name ?? 'Sem subcategoria',
      productCategoryId: product.productCategoryId,
      productCategoryName: product.productCategoryName,
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final summaryProduct = productForSummary;

    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar item'), centerTitle: true),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Produto *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                ProductSearchField(
                  controller: nameController,
                  suggestions: productSuggestions,
                  onSearch: _searchProducts,
                  onSelected: _selectProduct,
                ),
                if (_showValidationErrors && !hasValidProductName) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Informe o nome do produto.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '* Campos obrigatórios',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: brandController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    hintText: 'Ex.: Tirol',
                    helperText: 'Opcional. O DuoSpend aprenderá essa variação.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (summaryProduct != null) ...[
                  ProductSummaryCard(
                    key: ValueKey(
                      '${summaryProduct.id}-'
                      '${summaryProduct.name}-'
                      '${summaryProduct.brand}-'
                      '$unit',
                    ),
                    product: summaryProduct,
                    category:
                        selectedFinancialSubcategory?.name ??
                        selectedFinancialCategory.name,
                    subcategory:
                        selectedProductCategory?.name ??
                        summaryProduct.productCategoryName,
                  ),
                ] else ...[
                  const Text(
                    'Classificação',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ajude o DuoSpend a entender este produto.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<TaxonomyItem>(
                    key: ValueKey(
                      'financial-category-'
                      '${selectedFinancialCategory.id}',
                    ),
                    initialValue: selectedFinancialCategory,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de gasto',
                      helperText: 'Classificação financeira da compra',
                      border: OutlineInputBorder(),
                    ),
                    items: DuoTaxonomy.items.map((category) {
                      return DropdownMenuItem<TaxonomyItem>(
                        value: category,
                        child: Text('${category.icon} ${category.name}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _changeFinancialCategory(value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<TaxonomyItem>(
                    key: ValueKey(
                      'financial-subcategory-'
                      '${selectedFinancialCategory.id}-'
                      '${selectedFinancialSubcategory?.id}',
                    ),
                    initialValue: selectedFinancialSubcategory,
                    decoration: const InputDecoration(
                      labelText: 'Contexto da compra',
                      helperText: 'Ex.: Mercado, Restaurante ou Padaria',
                      border: OutlineInputBorder(),
                    ),
                    items: financialSubcategories
                        .map(
                          (subcategory) => DropdownMenuItem<TaxonomyItem>(
                            value: subcategory,
                            child: Text(
                              '${subcategory.icon} '
                              '${subcategory.name}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: financialSubcategories.isEmpty
                        ? null
                        : _changeFinancialSubcategory,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<TaxonomyItem>(
                    key: ValueKey(
                      'product-category-'
                      '${selectedFinancialSubcategory?.id}-'
                      '${selectedProductCategory?.id}',
                    ),
                    initialValue: selectedProductCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoria do produto',
                      helperText: 'Ex.: Laticínios, Bebidas ou Carnes',
                      border: OutlineInputBorder(),
                    ),
                    items: productCategories
                        .map(
                          (category) => DropdownMenuItem<TaxonomyItem>(
                            value: category,
                            child: Text('${category.icon} ${category.name}'),
                          ),
                        )
                        .toList(),
                    onChanged: productCategories.isEmpty
                        ? null
                        : _changeProductCategory,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: _validateQuantity,
                        decoration: const InputDecoration(
                          labelText: 'Quantidade *',
                          hintText: '1',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('unit-$unit'),
                        initialValue: unit,
                        decoration: const InputDecoration(
                          labelText: 'Unidade *',
                          border: OutlineInputBorder(),
                        ),
                        items: units.map((item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            unit = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: totalPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  validator: _validateTotalPrice,
                  onFieldSubmitted: (_) => _saveItem(),
                  decoration: const InputDecoration(
                    labelText: 'Valor total *',
                    hintText: '0,00',
                    helperText: 'Informe o valor total deste item.',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saveItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar item'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
