import '../../../features/transactions/data/models/product_model.dart';
import '../../../features/transactions/domain/purchase/models/purchase_item_model.dart';
import '../../../features/transactions/domain/purchase/models/purchase_model.dart';
import 'product_memory.dart';
import 'product_price_history_repository.dart';
import 'product_persistence_repository.dart';
import 'product_price_observation.dart';
import 'product_purchase_metrics.dart';

class ProductRepository {
  final ProductPersistenceRepository? _persistenceRepository;
  final ProductPriceHistoryRepository? _priceHistoryRepository;

  ProductRepository({
    ProductPersistenceRepository? persistenceRepository,
    ProductPriceHistoryRepository? priceHistoryRepository,
  }) : _persistenceRepository = persistenceRepository,
       _priceHistoryRepository = priceHistoryRepository;

  ProductModel? findById(String id) {
    return ProductMemory.findById(id);
  }

  String normalize(String value) {
    var normalized = value.trim().toLowerCase();

    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
    };

    replacements.forEach((character, replacement) {
      normalized = normalized.replaceAll(character, replacement);
    });

    normalized = normalized
        .replaceAll(RegExp(r'[^a-z0-9\s\-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return normalized;
  }

  List<ProductModel> search(String query) {
    final normalizedQuery = normalize(query);

    if (normalizedQuery.isEmpty) {
      return ProductMemory.all;
    }

    return ProductMemory.all.where((product) {
      final normalizedName = normalize(product.name);
      final normalizedStoredName = normalize(product.normalizedName);
      final normalizedBrand = normalize(product.brand);

      return normalizedName.contains(normalizedQuery) ||
          normalizedStoredName.contains(normalizedQuery) ||
          normalizedBrand.contains(normalizedQuery);
    }).toList();
  }

  Future<void> initialize({required String userId}) async {
    final persistenceRepository = _requirePersistenceRepository();

    final persistedProducts = await persistenceRepository.getAll(
      userId: userId,
    );

    for (final product in persistedProducts) {
      ProductMemory.remember(product);
    }
  }

  void saveSeedProduct(ProductModel product) {
    ProductMemory.remember(product);
  }

  Future<void> saveLearnedProduct({
    required String userId,
    required ProductModel product,
  }) async {
    final persistenceRepository = _requirePersistenceRepository();

    ProductMemory.remember(product);

    try {
      await persistenceRepository.save(userId: userId, product: product);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deleteLearnedProduct({
    required String userId,
    required String productId,
  }) async {
    final persistenceRepository = _requirePersistenceRepository();

    await persistenceRepository.delete(userId: userId, productId: productId);

    await _reloadMemory(userId: userId);
  }

  void clearMemory() {
    ProductMemory.clear();
  }

  void save(ProductModel product) {
    saveSeedProduct(product);
  }

  bool exists(String name) {
    final normalizedName = normalize(name);

    return ProductMemory.all.any(
      (product) =>
          normalize(product.normalizedName) == normalizedName ||
          normalize(product.name) == normalizedName,
    );
  }

  ProductModel? findByName(String name) {
    final normalizedName = normalize(name);

    try {
      return ProductMemory.all.firstWhere(
        (product) =>
            normalize(product.normalizedName) == normalizedName ||
            normalize(product.name) == normalizedName,
      );
    } catch (_) {
      return null;
    }
  }

  /// Localiza somente identidades fortes o bastante para reaproveitar um
  /// produto: código de barras, nome + marca, ou, para itens sem marca, nome +
  /// unidade. A categoria é classificação mutável e não participa da
  /// identidade. Nome isolado não é suficiente.
  ProductModel? findByIdentity({
    required String name,
    String brand = '',
    String barcode = '',
    String defaultUnit = '',
  }) {
    return _findByIdentityIn(
      ProductMemory.all,
      name: name,
      brand: brand,
      barcode: barcode,
      defaultUnit: defaultUnit,
    );
  }

  Future<ProductModel> resolveLearnedProduct({
    required String userId,
    required ProductModel candidate,
  }) async {
    final persistenceRepository = _requirePersistenceRepository();
    final persistedProducts = await persistenceRepository.getAll(
      userId: userId,
    );
    final knownProducts = <ProductModel>[
      ...persistedProducts,
      ...ProductMemory.all,
    ];
    final existing = _findByIdentityIn(
      knownProducts,
      name: candidate.name,
      brand: candidate.brand,
      barcode: candidate.barcode,
      defaultUnit: candidate.defaultUnit,
    );

    if (existing != null) {
      final resolved = _withUpdatedClassification(
        existing: existing,
        candidate: candidate,
      );
      if (!identical(resolved, existing)) {
        await saveLearnedProduct(userId: userId, product: resolved);
      } else {
        ProductMemory.remember(existing);
      }
      return resolved;
    }

    await saveLearnedProduct(userId: userId, product: candidate);
    return candidate;
  }

  /// Registers prices only after the purchase and its financial transaction
  /// have already been persisted by the caller.
  Future<void> learnFromPurchase({
    required String userId,
    required PurchaseModel purchase,
  }) async {
    final historyRepository = _priceHistoryRepository;
    if (historyRepository == null) {
      return;
    }

    if (purchase.id.trim().isEmpty ||
        purchase.purchaseDate.millisecondsSinceEpoch <= 0) {
      return;
    }

    final itemsByProduct = <String, List<PurchaseItemModel>>{};
    for (final item in purchase.items) {
      final productId = item.productId?.trim();
      if (productId == null ||
          productId.isEmpty ||
          item.unitPrice <= 0 ||
          item.quantity <= 0) {
        continue;
      }

      itemsByProduct.putIfAbsent(productId, () => []).add(item);
    }

    for (final entry in itemsByProduct.entries) {
      final productId = entry.key;
      final items = entry.value;
      final quantity = items.fold<double>(
        0,
        (sum, item) => sum + item.quantity,
      );
      final totalPrice = items.fold<double>(0, (sum, item) {
        final itemTotal = item.totalPrice;
        return sum +
            (itemTotal > 0 ? itemTotal : item.unitPrice * item.quantity);
      });
      if (quantity <= 0 || totalPrice <= 0) {
        continue;
      }

      final observation = ProductPriceObservation(
        productId: productId,
        purchaseId: purchase.id,
        purchasedAt: purchase.purchaseDate,
        unitPrice: totalPrice / quantity,
        quantity: quantity,
        merchantId: _singleNonEmptyValue(
          items.map((item) => item.merchantId),
          fallback: purchase.merchantId,
        ),
        merchantName: _nullableText(purchase.merchantName),
        productCategoryId: _singleNonEmptyValue(
          items.map((item) => item.productCategoryId),
        ),
        productCategoryName: _singleNonEmptyValue(
          items.map((item) => item.productCategoryName),
        ),
        totalPrice: totalPrice,
      );
      final observations = List<ProductPriceObservation>.of(
        await historyRepository.getByProductId(
          userId: userId,
          productId: productId,
        ),
      );
      final existingIndex = observations.indexWhere(
        (current) => current.purchaseId == observation.purchaseId,
      );

      await historyRepository.saveObservation(
        userId: userId,
        observation: observation,
      );
      if (existingIndex >= 0) {
        observations[existingIndex] = observation;
      } else {
        observations.add(observation);
      }

      final product = await _findPersistedProduct(
        userId: userId,
        productId: productId,
      );
      if (product == null) {
        continue;
      }

      final metrics = const ProductPurchaseMetricsCalculator().calculate(
        productId: productId,
        observations: observations,
      );
      final latestObservation = metrics.lastPurchase;
      if (latestObservation == null) {
        continue;
      }
      final updatedProduct = product.copyWith(
        lastPrice: latestObservation.unitPrice,
        averagePrice: metrics.averageUnitPrice ?? product.averagePrice,
        lastMerchantId: latestObservation.merchantId ?? product.lastMerchantId,
        updatedAt: DateTime.now(),
      );

      await saveLearnedProduct(userId: userId, product: updatedProduct);
    }
  }

  Future<List<ProductPriceObservation>> getPriceHistory({
    required String userId,
    required String productId,
  }) async {
    final historyRepository = _priceHistoryRepository;
    if (historyRepository == null) {
      return const [];
    }

    final observations = await historyRepository.getByProductId(
      userId: userId,
      productId: productId,
    );

    return const ProductPurchaseMetricsCalculator()
        .calculate(productId: productId, observations: observations)
        .history;
  }

  Future<ProductPurchaseMetrics> getPurchaseMetrics({
    required String userId,
    required String productId,
  }) async {
    final historyRepository = _priceHistoryRepository;
    final observations = historyRepository == null
        ? const <ProductPriceObservation>[]
        : await historyRepository.getByProductId(
            userId: userId,
            productId: productId,
          );

    return const ProductPurchaseMetricsCalculator().calculate(
      productId: productId,
      observations: observations,
    );
  }

  ProductModel? _findByIdentityIn(
    Iterable<ProductModel> products, {
    required String name,
    required String brand,
    required String barcode,
    required String defaultUnit,
  }) {
    final normalizedBarcode = barcode.trim().toLowerCase();
    final normalizedName = _normalizeIdentityName(name);
    final normalizedBrand = normalize(brand);
    final normalizedUnit = normalize(defaultUnit);
    final hasNameAndBrand =
        normalizedName.isNotEmpty && normalizedBrand.isNotEmpty;
    final hasUnbrandedUnitIdentity =
        normalizedName.isNotEmpty &&
        normalizedBrand.isEmpty &&
        normalizedUnit.isNotEmpty;

    if (normalizedBarcode.isNotEmpty) {
      final barcodeMatch = _oldestMatch(
        products.where(
          (product) =>
              product.barcode.trim().toLowerCase() == normalizedBarcode,
        ),
      );
      if (barcodeMatch != null) {
        return barcodeMatch;
      }
    }

    if (hasNameAndBrand) {
      final nameAndBrandMatch = _oldestMatch(
        products.where(
          (product) =>
              _knownIdentityNames(product).contains(normalizedName) &&
              normalize(product.brand) == normalizedBrand,
        ),
      );
      if (nameAndBrandMatch != null) {
        return nameAndBrandMatch;
      }
    }

    if (!hasUnbrandedUnitIdentity) {
      return null;
    }

    return _oldestMatch(
      products.where(
        (product) =>
            _knownIdentityNames(product).contains(normalizedName) &&
            normalize(product.brand).isEmpty &&
            normalize(product.defaultUnit) == normalizedUnit,
      ),
    );
  }

  ProductModel _withUpdatedClassification({
    required ProductModel existing,
    required ProductModel candidate,
  }) {
    final categoryId = candidate.productCategoryId.trim().isEmpty
        ? existing.productCategoryId
        : candidate.productCategoryId;
    final categoryName = candidate.productCategoryName.trim().isEmpty
        ? existing.productCategoryName
        : candidate.productCategoryName;
    final taxonomyId = candidate.taxonomyId.trim().isEmpty
        ? existing.taxonomyId
        : candidate.taxonomyId;
    if (categoryId == existing.productCategoryId &&
        categoryName == existing.productCategoryName &&
        taxonomyId == existing.taxonomyId) {
      return existing;
    }

    return existing.copyWith(
      productCategoryId: categoryId,
      productCategoryName: categoryName,
      taxonomyId: taxonomyId,
      updatedAt: DateTime.now(),
    );
  }

  ProductModel? _oldestMatch(Iterable<ProductModel> products) {
    final matchesById = <String, ProductModel>{
      for (final product in products) product.id: product,
    };
    if (matchesById.isEmpty) {
      return null;
    }

    final sorted = matchesById.values.toList()
      ..sort((left, right) {
        final createdComparison = left.createdAt.compareTo(right.createdAt);
        return createdComparison != 0
            ? createdComparison
            : left.id.compareTo(right.id);
      });
    return sorted.first;
  }

  Set<String> _knownIdentityNames(ProductModel product) {
    return <String>{
      _normalizeIdentityName(product.name),
      _normalizeIdentityName(product.normalizedName),
    }..remove('');
  }

  String _normalizeIdentityName(String value) {
    final decimalProtected = value.replaceAllMapped(
      RegExp(r'(\d)[\.,](\d)'),
      (match) => '${match.group(1)}decimalmarker${match.group(2)}',
    );
    final normalized = normalize(decimalProtected);
    final withCanonicalMeasures = normalized.replaceAllMapped(
      RegExp(r'(^|\s)(\d+)\s*(kg|mg|ml|g|l)(?=\s|$)'),
      (match) {
        final prefix = match.group(1) ?? '';
        final amount = BigInt.tryParse(match.group(2) ?? '');
        final unit = match.group(3);
        if (amount == null || unit == null) {
          return match.group(0) ?? '';
        }

        final canonical = switch (unit) {
          'kg' => (amount * BigInt.from(1000000), 'mg'),
          'g' => (amount * BigInt.from(1000), 'mg'),
          'mg' => (amount, 'mg'),
          'l' => (amount * BigInt.from(1000), 'ml'),
          'ml' => (amount, 'ml'),
          _ => (amount, unit),
        };
        return '$prefix${canonical.$1}${canonical.$2}';
      },
    );

    return withCanonicalMeasures;
  }

  String? _singleNonEmptyValue(Iterable<Object?> values, {String? fallback}) {
    final normalizedValues = values
        .map((value) => _nullableText(value?.toString()))
        .whereType<String>()
        .toSet();
    if (normalizedValues.length == 1) {
      return normalizedValues.single;
    }

    return _nullableText(fallback);
  }

  String? _nullableText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  Future<ProductModel?> _findPersistedProduct({
    required String userId,
    required String productId,
  }) async {
    final persistenceRepository = _persistenceRepository;
    if (persistenceRepository != null) {
      final persisted = await persistenceRepository.getById(
        userId: userId,
        productId: productId,
      );
      if (persisted != null) {
        return persisted;
      }
    }

    return findById(productId);
  }

  Future<void> _reloadMemory({required String userId}) async {
    final persistenceRepository = _requirePersistenceRepository();

    final persistedProducts = await persistenceRepository.getAll(
      userId: userId,
    );

    ProductMemory.clear();

    for (final product in persistedProducts) {
      ProductMemory.remember(product);
    }
  }

  ProductPersistenceRepository _requirePersistenceRepository() {
    final persistenceRepository = _persistenceRepository;

    if (persistenceRepository == null) {
      throw StateError(
        'ProductRepository precisa receber um '
        'ProductPersistenceRepository para executar operações persistentes.',
      );
    }

    return persistenceRepository;
  }
}
