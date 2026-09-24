import 'package:app/features/receipt_scanner/application/receipt_product_identity_resolver.dart';
import 'package:app/features/receipt_scanner/domain/models/receipt_scan_item.dart';
import 'package:app/features/transactions/data/models/product_model.dart';
import 'package:app/features/transactions/domain/purchase/models/purchase_item_model.dart';
import 'package:app/shared/knowledge/products/product_persistence_repository.dart';
import 'package:app/shared/knowledge/products/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Products implements ProductPersistenceRepository {
  final saved = <String, ProductModel>{};
  @override
  Future<List<ProductModel>> getAll({required String userId}) async =>
      saved.values.toList();
  @override
  Future<ProductModel?> getById({
    required String userId,
    required String productId,
  }) async => saved[productId];
  @override
  Future<void> save({
    required String userId,
    required ProductModel product,
  }) async {
    saved[product.id] = product;
  }

  @override
  Future<void> delete({
    required String userId,
    required String productId,
  }) async {
    saved.remove(productId);
  }
}

ProductModel product(String id, String name, String brand) => ProductModel(
  id: id,
  name: name,
  normalizedName: name.toLowerCase(),
  brand: brand,
  barcode: '',
  defaultUnit: 'UN',
  productCategoryId: 'alimentos',
  productCategoryName: 'Alimentos',
  taxonomyId: 'alimentos',
  averagePrice: 0,
  lastPrice: 0,
  lastMerchantId: '',
  favorite: false,
  createdAt: DateTime(2026, 9, 1),
  updatedAt: DateTime(2026, 9, 1),
);

PurchaseItemModel item(String name, String brand, {String unit = 'UN'}) =>
    PurchaseItemModel(
      id: name,
      purchaseId: '',
      name: name,
      brand: brand,
      quantity: 1,
      unit: unit,
      unitPrice: 12,
      totalPrice: 12,
      taxonomyId: 'alimentos',
      financialCategory: 'Mercado',
      financialSubcategory: '',
      productCategoryId: 'alimentos',
      productCategoryName: 'Alimentos',
      createdAt: DateTime(2026, 9, 18),
    );

void main() {
  test('reutiliza o produto específico e não mescla outra marca', () async {
    final storage = _Products();
    final repository = ProductRepository(persistenceRepository: storage)
      ..clearMemory();
    storage.saved['buriti'] = product('buriti', 'Arroz 5 kg', 'Buriti');
    storage.saved['tiojoao'] = product('tiojoao', 'Arroz 5 kg', 'Tio João');
    await repository.initialize(userId: 'teste');
    final resolver = ReceiptProductIdentityResolver(repository);

    expect(
      resolver
          .existingForScan(
            const ReceiptScanItem(
              description: 'Arroz 5 kg',
              brand: 'Buriti',
              unit: 'UN',
            ),
          )
          ?.id,
      'buriti',
    );
    expect(
      resolver.existingForScan(
        const ReceiptScanItem(
          description: 'Arroz 5 kg',
          brand: 'Outra',
          unit: 'UN',
        ),
      ),
      isNull,
    );
    expect(
      resolver.existingForScan(
        const ReceiptScanItem(description: 'Arroz', unit: null),
      ),
      isNull,
    );
    expect(storage.saved.length, 2);

    final created = await resolver.resolveConfirmedItem(
      userId: 'teste',
      item: item('Arroz 5 kg', 'Outra'),
    );
    expect(created?.id, isNot(anyOf('buriti', 'tiojoao')));
    expect(storage.saved.length, 3);
  });

  test('não cria produto com identidade incompleta', () async {
    final storage = _Products();
    final repository = ProductRepository(persistenceRepository: storage)
      ..clearMemory();
    final resolver = ReceiptProductIdentityResolver(repository);
    expect(
      await resolver.resolveConfirmedItem(
        userId: 'teste',
        item: item('Arroz', '', unit: ''),
      ),
      isNull,
    );
    expect(storage.saved, isEmpty);
  });
}
