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

ProductModel _product({double averagePrice = 8.79}) {
  final now = DateTime(2026, 9, 1);
  return ProductModel(
    id: 'arroz',
    name: 'Arroz Integral',
    normalizedName: 'arroz integral',
    brand: 'Marca',
    barcode: '',
    defaultUnit: 'un',
    productCategoryId: 'grains',
    productCategoryName: 'Grãos',
    taxonomyId: 'grains',
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
}) {
  final date = DateTime(2026, 9, 2);
  final item = PurchaseItemModel(
    id: 'item-$id',
    purchaseId: id,
    productId: 'arroz',
    merchantId: 'merchant',
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
    createdAt: date,
  );
  return PurchaseModel(
    id: id,
    userId: 'user',
    walletId: 'wallet',
    merchantId: 'merchant',
    merchantName: 'Mercado',
    financialCategory: 'Alimentação',
    financialSubcategory: 'Mercado',
    items: [item],
    subtotal: item.totalPrice,
    discount: 0,
    total: item.totalPrice,
    purchaseDate: date,
    createdAt: date,
    updatedAt: date,
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
}
