import '../../../features/transactions/data/models/product_model.dart';
import '../../../features/transactions/domain/purchase/models/purchase_model.dart';
import 'product_memory.dart';
import 'product_price_history_repository.dart';
import 'product_persistence_repository.dart';
import 'product_price_observation.dart';

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

    for (final item in purchase.items) {
      final productId = item.productId?.trim();
      if (productId == null ||
          productId.isEmpty ||
          item.unitPrice <= 0 ||
          item.quantity <= 0) {
        continue;
      }

      final observation = ProductPriceObservation(
        productId: productId,
        purchaseId: purchase.id,
        purchasedAt: purchase.purchaseDate,
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        merchantId: item.merchantId ?? purchase.merchantId,
      );
      final observations = List<ProductPriceObservation>.of(
        await historyRepository.getByProductId(
          userId: userId,
          productId: productId,
        ),
      );
      final alreadyRecorded = observations.any(
        (current) => current.id == observation.id,
      );

      if (!alreadyRecorded) {
        await historyRepository.saveObservation(
          userId: userId,
          observation: observation,
        );
        observations.add(observation);
      }

      final product = await _findPersistedProduct(
        userId: userId,
        productId: productId,
      );
      if (product == null) {
        continue;
      }

      final averagePrice = observations.isEmpty
          ? item.unitPrice
          : observations.fold<double>(
                  0,
                  (sum, price) => sum + price.unitPrice,
                ) /
                observations.length;
      final latestObservation = observations.reduce(
        (current, candidate) =>
            candidate.purchasedAt.isAfter(current.purchasedAt)
            ? candidate
            : current,
      );
      final updatedProduct = product.copyWith(
        lastPrice: latestObservation.unitPrice,
        averagePrice: averagePrice,
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

    return historyRepository.getByProductId(
      userId: userId,
      productId: productId,
    );
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
