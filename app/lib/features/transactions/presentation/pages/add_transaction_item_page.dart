import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/knowledge/products/product_repository.dart';
import '../../../../shared/knowledge/taxonomy/duo_taxonomy.dart';
import '../../../../shared/knowledge/taxonomy/taxonomy_item.dart';
import '../../../../shared/widgets/product_search_field.dart';
import '../../../../shared/widgets/product_summary_card.dart';
import '../../data/models/product_model.dart';
import '../../data/models/transaction_item_model.dart';

class AddTransactionItemPage extends StatefulWidget {
  final TransactionItemModel? initialItem;
  final ProductRepository productRepository;

  const AddTransactionItemPage({
    super.key,
    this.initialItem,
    required this.productRepository,
  });

  bool get isEditing => initialItem != null;

  @override
  State<AddTransactionItemPage> createState() {
    return _AddTransactionItemPageState();
  }
}

class _AddTransactionItemPageState extends State<AddTransactionItemPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  ProductRepository get productRepository {
    return widget.productRepository;
  }

  final TextEditingController nameController = TextEditingController();

  final TextEditingController brandController = TextEditingController();

  final TextEditingController quantityController = TextEditingController(
    text: '1',
  );

  final TextEditingController unitPriceController = TextEditingController();

  List<ProductModel> productSuggestions = [];

  ProductModel? selectedProduct;

  bool _isApplyingSelectedProduct = false;
  bool _showValidationErrors = false;
  bool _isSavingItem = false;

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

  bool get isKnownProduct {
    final product = selectedProduct;

    return product != null && !_isGenericOtherProduct(product);
  }

  bool get hasValidProductName {
    final normalizedName = _normalize(nameController.text);

    return normalizedName.isNotEmpty &&
        normalizedName != 'outro' &&
        normalizedName != 'outros';
  }

  List<TaxonomyItem> get financialSubcategories {
    return selectedFinancialCategory.children;
  }

  List<TaxonomyItem> get productCategories {
    return selectedFinancialSubcategory?.children ?? const <TaxonomyItem>[];
  }

  double get currentQuantity {
    final quantity = _parseNumber(quantityController.text);

    if (quantity == null || quantity <= 0) {
      return 0;
    }

    return quantity;
  }

  double get currentUnitPrice {
    final unitPrice = _parseNumber(unitPriceController.text);

    if (unitPrice == null || unitPrice <= 0) {
      return 0;
    }

    return unitPrice;
  }

  double get currentSubtotal {
    return currentQuantity * currentUnitPrice;
  }

  bool get hasValidSubtotal {
    return currentQuantity > 0 && currentUnitPrice > 0;
  }

  ProductModel? get productForSummary {
    final product = selectedProduct;

    if (product == null || _isGenericOtherProduct(product)) {
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

    _setDefaultProductCategory();
    _populateInitialItem();

    nameController.addListener(_handleProductDataChanged);
    brandController.addListener(_handleProductDataChanged);
    quantityController.addListener(_handlePurchaseValuesChanged);
    unitPriceController.addListener(_handlePurchaseValuesChanged);
  }

  @override
  void dispose() {
    nameController.removeListener(_handleProductDataChanged);
    brandController.removeListener(_handleProductDataChanged);
    quantityController.removeListener(_handlePurchaseValuesChanged);
    unitPriceController.removeListener(_handlePurchaseValuesChanged);

    nameController.dispose();
    brandController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();

    super.dispose();
  }

  void _populateInitialItem() {
    final item = widget.initialItem;

    if (item == null) {
      return;
    }

    _isApplyingSelectedProduct = true;

    nameController.text = item.name;
    brandController.text = item.brand;
    quantityController.text = _formatEditableNumber(item.quantity);

    unitPriceController.text = item.unitPrice
        .toStringAsFixed(2)
        .replaceAll('.', ',');

    unit = item.unit;

    if (!units.contains(unit)) {
      units.add(unit);
    }

    final taxonomyPath = _findTaxonomyPath(item.taxonomyId);

    if (taxonomyPath.isNotEmpty) {
      selectedFinancialCategory = taxonomyPath.first;

      selectedFinancialSubcategory = taxonomyPath.length > 1
          ? taxonomyPath[1]
          : null;

      selectedProductCategory = taxonomyPath.length > 2
          ? taxonomyPath[2]
          : null;
    } else {
      _selectTaxonomyFromItemNames(item);
    }

    final existingProduct = _findExistingProduct(
      name: item.name,
      brand: item.brand,
    );

    selectedProduct =
        existingProduct != null && !_isGenericOtherProduct(existingProduct)
        ? existingProduct
        : null;

    _isApplyingSelectedProduct = false;
  }

  void _selectTaxonomyFromItemNames(TransactionItemModel item) {
    for (final category in DuoTaxonomy.items) {
      if (category.name != item.category) {
        continue;
      }

      selectedFinancialCategory = category;

      TaxonomyItem? matchingSubcategory;

      for (final subcategory in category.children) {
        if (subcategory.name == item.subcategory) {
          matchingSubcategory = subcategory;
          break;
        }
      }

      selectedFinancialSubcategory =
          matchingSubcategory ??
          (category.children.isNotEmpty ? category.children.first : null);

      final categories =
          selectedFinancialSubcategory?.children ?? const <TaxonomyItem>[];

      TaxonomyItem? matchingProductCategory;

      for (final productCategory in categories) {
        final matchesId = productCategory.id == item.productCategoryId;

        final matchesName = productCategory.name == item.productCategoryName;

        if (matchesId || matchesName) {
          matchingProductCategory = productCategory;
          break;
        }
      }

      selectedProductCategory =
          matchingProductCategory ??
          (categories.isNotEmpty ? categories.first : null);

      return;
    }
  }

  String _formatEditableNumber(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'[,.]$'), '')
        .replaceAll('.', ',');
  }

  String _normalize(String value) {
    return productRepository.normalize(value);
  }

  bool _isGenericOtherProduct(ProductModel product) {
    final normalizedName = _normalize(product.name);

    return normalizedName == 'outro' || normalizedName == 'outros';
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  void _handlePurchaseValuesChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
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
    final isGenericOther = _isGenericOtherProduct(product);

    final typedName = nameController.text.trim();
    final typedBrand = brandController.text.trim();

    _isApplyingSelectedProduct = true;

    setState(() {
      selectedProduct = isGenericOther ? null : product;

      if (!isGenericOther) {
        nameController.text = product.name;
        brandController.text = product.brand;

        unit = product.defaultUnit;

        if (!units.contains(unit)) {
          units.add(unit);
        }
      } else {
        final normalizedTypedName = _normalize(typedName);

        if (typedName.isNotEmpty &&
            normalizedTypedName != 'outro' &&
            normalizedTypedName != 'outros') {
          nameController.text = typedName;
        } else {
          nameController.clear();
        }

        brandController.text = typedBrand;
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
      if (_isGenericOtherProduct(product)) {
        continue;
      }

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

    if (product == null || _isGenericOtherProduct(product)) {
      return false;
    }

    return _normalize(product.name) == _normalize(nameController.text) &&
        _normalize(product.brand) == _normalize(brandController.text);
  }

  Future<ProductModel> _resolveAndSaveProduct({
    required String name,
    required String brand,
    required String taxonomyId,
    required String productCategoryId,
    required String productCategoryName,
    required double unitPrice,
  }) async {
    if (_selectedProductMatchesCurrentFields()) {
      return selectedProduct!;
    }

    final existingProduct = _findExistingProduct(
      name: name,
      brand: brand,
    );

    if (existingProduct != null) {
      return existingProduct;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError(
        'Usuário não autenticado. Entre novamente para salvar o produto.',
      );
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

    await productRepository.saveLearnedProduct(
      userId: user.uid,
      product: newProduct,
    );

    return newProduct;
  }

  String? _validateQuantity(String? value) {
    final quantity = _parseNumber(value ?? '');

    if (quantity == null || quantity <= 0) {
      return 'Informe uma quantidade válida.';
    }

    return null;
  }

  String? _validateUnitPrice(String? value) {
    final unitPrice = _parseNumber(value ?? '');

    if (unitPrice == null || unitPrice <= 0) {
      return 'Informe um preço unitário válido.';
    }

    return null;
  }

  Future<void> _saveItem() async {
    if (_isSavingItem) {
      return;
    }

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

    setState(() {
      _isSavingItem = true;
    });

    try {
      final name = nameController.text.trim();
      final brand = brandController.text.trim();

      final quantity = _parseNumber(quantityController.text)!;

      final unitPrice = _parseNumber(unitPriceController.text)!;

      final totalPrice = quantity * unitPrice;

      final productCategoryId =
          selectedProduct?.productCategoryId ??
          selectedProductCategory?.id ??
          '';

      final productCategoryName =
          selectedProduct?.productCategoryName ??
          selectedProductCategory?.name ??
          '';

      final taxonomyId =
          selectedProduct?.taxonomyId ??
          selectedProductCategory?.id ??
          selectedFinancialSubcategory?.id ??
          selectedFinancialCategory.id;

      final product = await _resolveAndSaveProduct(
        name: name,
        brand: brand,
        taxonomyId: taxonomyId,
        productCategoryId: productCategoryId,
        productCategoryName: productCategoryName,
        unitPrice: unitPrice,
      );

      final originalItem = widget.initialItem;
      final now = DateTime.now();

      final item = TransactionItemModel(
        id: originalItem?.id ?? now.microsecondsSinceEpoch.toString(),
        transactionId: originalItem?.transactionId ?? '',
        productId: product.id,
        merchantId: originalItem?.merchantId,
        name: product.name,
        brand: product.brand,
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        taxonomyId: product.taxonomyId,
        category: selectedFinancialCategory.name,
        subcategory:
            selectedFinancialSubcategory?.name ?? 'Sem subcategoria',
        productCategoryId: product.productCategoryId,
        productCategoryName: product.productCategoryName,
        createdAt: originalItem?.createdAt ?? now,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, item);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível salvar o produto: $error',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingItem = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryProduct = productForSummary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar item' : 'Adicionar item'),
        centerTitle: true,
      ),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
                    helperText:
                        'Opcional. O DuoSpend aprenderá essa variação.',
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                    items: DuoTaxonomy.items
                        .map(
                          (category) => DropdownMenuItem<TaxonomyItem>(
                            value: category,
                            child: Text(
                              '${category.icon} ${category.name}',
                            ),
                          ),
                        )
                        .toList(),
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
                              '${subcategory.icon} ${subcategory.name}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: financialSubcategories.isEmpty
                        ? null
                        : _changeFinancialSubcategory,
                  ),
                  if (productCategories.isNotEmpty) ...[
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
                              child: Text(
                                '${category.icon} ${category.name}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _changeProductCategory,
                    ),
                  ],
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
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
                        items: units
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
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
                  controller: unitPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  validator: _validateUnitPrice,
                  onFieldSubmitted: (_) async {
                    await _saveItem();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Preço unitário *',
                    hintText: '0,00',
                    helperText: 'Informe o preço de uma unidade.',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    key: ValueKey(
                      '${currentQuantity.toStringAsFixed(3)}-'
                      '${currentUnitPrice.toStringAsFixed(2)}-'
                      '$unit',
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Subtotal',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                hasValidSubtotal
                                    ? _formatMoney(currentSubtotal)
                                    : 'Preencha quantidade e preço unitário.',
                                style: TextStyle(
                                  fontSize: hasValidSubtotal ? 18 : 14,
                                  fontWeight: hasValidSubtotal
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: hasValidSubtotal
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (hasValidSubtotal) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${_formatEditableNumber(currentQuantity)} '
                                  '$unit × '
                                  '${_formatMoney(currentUnitPrice)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isSavingItem
                        ? null
                        : () async {
                            await _saveItem();
                          },
                    icon: _isSavingItem
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            widget.isEditing
                                ? Icons.check_outlined
                                : Icons.add,
                          ),
                    label: Text(
                      _isSavingItem
                          ? 'Salvando...'
                          : widget.isEditing
                          ? 'Salvar alterações'
                          : 'Adicionar item',
                    ),
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