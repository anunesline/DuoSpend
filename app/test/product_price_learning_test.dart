import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/transactions/data/models/product_model.dart';
import 'package:app/features/transactions/domain/purchase/models/purchase_item_model.dart';
import 'package:app/features/transactions/domain/purchase/models/purchase_model.dart';
import 'package:app/shared/knowledge/products/product_memory.dart';
import 'package:app/shared/knowledge/products/product_persistence_repository.dart';
import 'package:app/shared/knowledge/products/product_price_history_repository.dart';
import 'package:app/shared/knowledge/products/product_price_observation.dart';
import 'package:app/shared/knowledge/products/product_repository.dart';

class _ProductPersistence implements ProductPersistenceRepository {
  final Map<String, ProductModel> products = {};

  @override
  Future<List<ProductModel>> getAll({required String userId}) async {
    return products.values.toList();
  }

  @override
  Future<ProductModel?> getById({
    required String userId,
    required String productId,
  }) async {
    return products[productId];
  }

  @override
  Future<void> save({
    required String userId,
    required ProductModel product,
  }) async {
    products[product.id] = product;
  }

  @override
  Future<void> delete({
    required String userId,
    required String productId,
  }) async {
    products.remove(productId);
  }
}

class _PriceHistory implements ProductPriceHistoryRepository {
  final Map<String, ProductPriceObservation> observations = {};

  @override
  Future<List<ProductPriceObservation>> getByProductId({
    required String userId,
    required String productId,
  }) async {
    return observations.values
        .where((observation) => observation.productId == productId)
        .toList();
  }

  @override
  Future<void> saveObservation({
    required String userId,
    required ProductPriceObservation observation,
  }) async {
    observations[observation.id] = observation;
  }
}

ProductModel _product({
  String id = 'arroz',
  String name = 'Arroz Integral',
  String brand = 'Marca',
  String barcode = '',
  String defaultUnit = 'un',
  String productCategoryId = 'grains',
  String productCategoryName = 'Grãos',
  String taxonomyId = 'grains',
  String? normalizedName,
  DateTime? createdAt,
  double averagePrice = 8.79,
}) {
  final now = createdAt ?? DateTime(2026, 9, 1);
  return ProductModel(
    id: id,
    name: name,
    normalizedName: normalizedName ?? name.toLowerCase(),
    brand: brand,
    barcode: barcode,
    defaultUnit: defaultUnit,
    productCategoryId: productCategoryId,
    productCategoryName: productCategoryName,
    taxonomyId: taxonomyId,
    averagePrice: averagePrice,
    lastPrice: averagePrice,
    lastMerchantId: '',
    favorite: false,
    createdAt: now,
    updatedAt: now,
  );
}

PurchaseModel _purchase({
  required String id,
  required double unitPrice,
  double quantity = 1,
  DateTime? date,
  String merchantId = 'merchant',
  String merchantName = 'Mercado',
}) {
  final purchaseDate = date ?? DateTime(2026, 9, 2);
  final item = PurchaseItemModel(
    id: 'item-$id',
    purchaseId: id,
    productId: 'arroz',
    merchantId: merchantId,
    name: 'Arroz Integral',
    brand: 'Marca',
    quantity: quantity,
    unit: 'un',
    unitPrice: unitPrice,
    totalPrice: unitPrice * quantity,
    taxonomyId: 'grains',
    financialCategory: 'Alimentação',
    financialSubcategory: 'Mercado',
    productCategoryId: 'grains',
    productCategoryName: 'Grãos',
    createdAt: purchaseDate,
  );
  return PurchaseModel(
    id: id,
    userId: 'user',
    walletId: 'wallet',
    merchantId: merchantId,
    merchantName: merchantName,
    financialCategory: 'Alimentação',
    financialSubcategory: 'Mercado',
    items: [item],
    subtotal: item.totalPrice,
    discount: 0,
    total: item.totalPrice,
    purchaseDate: purchaseDate,
    createdAt: purchaseDate,
    updatedAt: purchaseDate,
  );
}

void main() {
  late _ProductPersistence persistence;
  late _PriceHistory history;
  late ProductRepository repository;

  setUp(() {
    ProductMemory.clear();
    persistence = _ProductPersistence()..products['arroz'] = _product();
    history = _PriceHistory();
    repository = ProductRepository(
      persistenceRepository: persistence,
      priceHistoryRepository: history,
    );
  });

  test(
    'primeira compra real atualiza preço e cria observação unitária',
    () async {
      await repository.learnFromPurchase(
        userId: 'user',
        purchase: _purchase(id: 'purchase-1', unitPrice: 9.49, quantity: 2),
      );

      final product = persistence.products['arroz']!;
      expect(product.lastPrice, 9.49);
      expect(product.averagePrice, 9.49);
      expect(history.observations, hasLength(1));
      expect(history.observations.values.single.quantity, 2);
      expect(history.observations.values.single.unitPrice, 9.49);
    },
  );

  test(
    'segunda compra atualiza lastPrice e média aritmética unitária',
    () async {
      await repository.learnFromPurchase(
        userId: 'user',
        purchase: _purchase(id: 'purchase-1', unitPrice: 8),
      );
      await repository.learnFromPurchase(
        userId: 'user',
        purchase: _purchase(
          id: 'purchase-2',
          unitPrice: 10,
          quantity: 5,
        ).copyWith(purchaseDate: DateTime(2026, 9, 3)),
      );

      expect(persistence.products['arroz']!.lastPrice, 10);
      expect(persistence.products['arroz']!.averagePrice, 9);
    },
  );

  test('processamento repetido é idempotente e não duplica a média', () async {
    final purchase = _purchase(id: 'purchase-1', unitPrice: 9.49);
    await repository.learnFromPurchase(userId: 'user', purchase: purchase);
    await repository.learnFromPurchase(userId: 'user', purchase: purchase);

    expect(history.observations, hasLength(1));
    expect(persistence.products['arroz']!.averagePrice, 9.49);
  });

  test('reprocessar compra antiga não regride o último preço', () async {
    final older = _purchase(id: 'purchase-1', unitPrice: 8);
    final newer = _purchase(
      id: 'purchase-2',
      unitPrice: 10,
    ).copyWith(purchaseDate: DateTime(2026, 9, 3));
    await repository.learnFromPurchase(userId: 'user', purchase: older);
    await repository.learnFromPurchase(userId: 'user', purchase: newer);
    await repository.learnFromPurchase(userId: 'user', purchase: older);

    expect(persistence.products['arroz']!.lastPrice, 10);
    expect(history.observations, hasLength(2));
  });

  test(
    'preço cadastral de produto inline não vira observação duplicada',
    () async {
      persistence.products['arroz'] = _product(averagePrice: 9.49);
      await repository.learnFromPurchase(
        userId: 'user',
        purchase: _purchase(id: 'purchase-inline', unitPrice: 9.49),
      );

      expect(history.observations, hasLength(1));
      expect(persistence.products['arroz']!.averagePrice, 9.49);
    },
  );

  test('compra não concluída não gera observação', () async {
    // A página só chama learnFromPurchase quando saveTransaction retorna com
    // sucesso. Um cancelamento não chama este método.
    expect(history.observations, isEmpty);
  });

  test(
    'observação mantém estabelecimento, categoria, quantidade e total',
    () async {
      await repository.learnFromPurchase(
        userId: 'user',
        purchase: _purchase(
          id: 'purchase-details',
          unitPrice: 7.5,
          quantity: 4,
          merchantId: 'market-a',
          merchantName: 'Mercado A',
        ),
      );

      final observation = history.observations.values.single;
      expect(observation.merchantId, 'market-a');
      expect(observation.merchantName, 'Mercado A');
      expect(observation.productCategoryId, 'grains');
      expect(observation.productCategoryName, 'Grãos');
      expect(observation.quantity, 4);
      expect(observation.totalPrice, 30);
    },
  );

  test(
    'linhas repetidas do produto na mesma compra viram uma observação',
    () async {
      final base = _purchase(
        id: 'purchase-grouped',
        unitPrice: 10,
        quantity: 2,
      );
      final secondItem = base.items.single.copyWith(
        id: 'second-line',
        quantity: 3,
        unitPrice: 12,
        totalPrice: 36,
      );

      await repository.learnFromPurchase(
        userId: 'user',
        purchase: base.copyWith(items: [base.items.single, secondItem]),
      );

      final observation = history.observations.values.single;
      expect(history.observations, hasLength(1));
      expect(observation.quantity, 5);
      expect(observation.totalPrice, 56);
      expect(observation.unitPrice, 11.2);
    },
  );

  test(
    'métricas expostas pelo repositório usam histórico cronológico',
    () async {
      await repository.learnFromPurchase(
        userId: 'user',
        purchase: _purchase(
          id: 'newer',
          unitPrice: 12,
          date: DateTime(2026, 9, 15),
        ),
      );
      await repository.learnFromPurchase(
        userId: 'user',
        purchase: _purchase(
          id: 'older',
          unitPrice: 10,
          date: DateTime(2026, 9, 1),
        ),
      );

      final metrics = await repository.getPurchaseMetrics(
        userId: 'user',
        productId: 'arroz',
      );

      expect(metrics.history.map((observation) => observation.purchaseId), [
        'older',
        'newer',
      ]);
      expect(metrics.lastUnitPrice, 12);
      expect(metrics.percentagePriceVariation, 20);
    },
  );

  test('identidade forte reaproveita produto e evita duplicação', () async {
    final candidate = _product(
      id: 'candidate',
      name: '  ARROZ integral ',
      brand: 'MÁRCA',
    );

    final resolved = await repository.resolveLearnedProduct(
      userId: 'user',
      candidate: candidate,
    );

    expect(resolved.id, 'arroz');
    expect(persistence.products, hasLength(1));
  });

  test(
    'mudança de categoria preserva identidade de produto sem marca',
    () async {
      persistence.products['unbranded'] = _product(
        id: 'unbranded',
        name: 'Papel toalha',
        brand: '',
        defaultUnit: 'pacote',
        productCategoryId: 'cleaning',
        productCategoryName: 'Limpeza',
        taxonomyId: 'cleaning',
      );
      final candidate = _product(
        id: 'candidate',
        name: 'Papel toalha',
        brand: '',
        defaultUnit: 'pacote',
        productCategoryId: 'home',
        productCategoryName: 'Casa',
        taxonomyId: 'home',
      );

      final resolved = await repository.resolveLearnedProduct(
        userId: 'user',
        candidate: candidate,
      );

      expect(resolved.id, 'unbranded');
      expect(resolved.productCategoryId, 'home');
      expect(resolved.productCategoryName, 'Casa');
      expect(persistence.products['unbranded']?.productCategoryId, 'home');
      expect(persistence.products, hasLength(2));
    },
  );

  test('5kg e 5 kg resolvem a mesma medida', () async {
    persistence.products['unbranded'] = _product(
      id: 'unbranded',
      name: 'Arroz 5kg',
      brand: '',
      defaultUnit: 'pacote',
    );
    final candidate = _product(
      id: 'candidate',
      name: 'Arroz 5 kg',
      brand: '',
      defaultUnit: 'pacote',
    );

    final resolved = await repository.resolveLearnedProduct(
      userId: 'user',
      candidate: candidate,
    );

    expect(resolved.id, 'unbranded');
  });

  test('5kg e 5000g resolvem a mesma medida', () async {
    persistence.products['unbranded'] = _product(
      id: 'unbranded',
      name: 'Arroz 5kg',
      brand: '',
      defaultUnit: 'pacote',
    );
    final candidate = _product(
      id: 'candidate',
      name: 'Arroz 5000g',
      brand: '',
      defaultUnit: 'pacote',
    );

    final resolved = await repository.resolveLearnedProduct(
      userId: 'user',
      candidate: candidate,
    );

    expect(resolved.id, 'unbranded');
  });

  test('1l e 1000ml resolvem o mesmo volume', () async {
    persistence.products['unbranded'] = _product(
      id: 'unbranded',
      name: 'Leite 1l',
      brand: '',
      defaultUnit: 'garrafa',
    );
    final candidate = _product(
      id: 'candidate',
      name: 'Leite 1000ml',
      brand: '',
      defaultUnit: 'garrafa',
    );

    final resolved = await repository.resolveLearnedProduct(
      userId: 'user',
      candidate: candidate,
    );

    expect(resolved.id, 'unbranded');
  });

  test('medidas diferentes continuam sendo identidades diferentes', () async {
    persistence.products['unbranded'] = _product(
      id: 'unbranded',
      name: 'Arroz 5kg',
      brand: '',
      defaultUnit: 'pacote',
    );
    final candidate = _product(
      id: 'candidate',
      name: 'Arroz 2kg',
      brand: '',
      defaultUnit: 'pacote',
    );

    final resolved = await repository.resolveLearnedProduct(
      userId: 'user',
      candidate: candidate,
    );

    expect(resolved.id, 'candidate');
  });

  test('unidades de dimensões incompatíveis não são convertidas', () async {
    persistence.products['unbranded'] = _product(
      id: 'unbranded',
      name: 'Produto 1kg',
      brand: '',
      defaultUnit: 'pacote',
    );
    final candidate = _product(
      id: 'candidate',
      name: 'Produto 1l',
      brand: '',
      defaultUnit: 'pacote',
    );

    final resolved = await repository.resolveLearnedProduct(
      userId: 'user',
      candidate: candidate,
    );

    expect(resolved.id, 'candidate');
  });

  test('unidades comerciais diferentes não são equivalentes', () async {
    persistence.products['package'] = _product(
      id: 'package',
      name: 'Papel toalha',
      brand: '',
      defaultUnit: 'pacote',
    );
    final box = _product(
      id: 'box',
      name: 'Papel toalha',
      brand: '',
      defaultUnit: 'caixa',
    );
    final unit = _product(
      id: 'unit',
      name: 'Papel toalha',
      brand: '',
      defaultUnit: 'unidade',
    );

    final resolvedBox = await repository.resolveLearnedProduct(
      userId: 'user',
      candidate: box,
    );
    final resolvedUnit = await repository.resolveLearnedProduct(
      userId: 'user',
      candidate: unit,
    );

    expect(resolvedBox.id, 'box');
    expect(resolvedUnit.id, 'unit');
  });

  test('barcode tem prioridade sobre nome e marca', () async {
    persistence.products
      ..['name-match'] = _product(
        id: 'name-match',
        name: 'Café Especial',
        brand: 'Marca',
        barcode: 'other',
        createdAt: DateTime(2020),
      )
      ..['barcode-match'] = _product(
        id: 'barcode-match',
        name: 'Outro Produto',
        brand: 'Outra Marca',
        barcode: '789123',
        createdAt: DateTime(2025),
      );
    final candidate = _product(
      id: 'candidate',
      name: 'Café Especial',
      brand: 'Marca',
      barcode: '789123',
    );

    final resolved = await repository.resolveLearnedProduct(
      userId: 'user',
      candidate: candidate,
    );

    expect(resolved.id, 'barcode-match');
  });

  test('nome isolado continua insuficiente sem unidade', () async {
    persistence.products['unbranded'] = _product(
      id: 'unbranded',
      name: 'Banana',
      brand: '',
      defaultUnit: '',
    );
    final candidate = _product(
      id: 'candidate',
      name: 'Banana',
      brand: '',
      defaultUnit: '',
    );

    final resolved = await repository.resolveLearnedProduct(
      userId: 'user',
      candidate: candidate,
    );

    expect(resolved.id, 'candidate');
  });

  test('produto legado sem normalizedName preserva identidade', () async {
    persistence.products['legacy'] = _product(
      id: 'legacy',
      name: 'Papel toalha',
      normalizedName: '',
      brand: '',
      defaultUnit: 'pacote',
      productCategoryId: 'old-category',
    );
    final candidate = _product(
      id: 'candidate',
      name: 'PAPEL  TOALHA',
      brand: '',
      defaultUnit: 'PACOTE',
      productCategoryId: 'new-category',
    );

    final resolved = await repository.resolveLearnedProduct(
      userId: 'user',
      candidate: candidate,
    );

    expect(resolved.id, 'legacy');
  });
}
