import 'package:uuid/uuid.dart';

import '../../../shared/knowledge/products/product_repository.dart';
import '../../transactions/data/models/product_model.dart';
import '../../transactions/domain/purchase/models/purchase_item_model.dart';
import '../domain/models/receipt_scan_item.dart';

/// Reaproveita a política de identidade do catálogo sem inferir EAN ou marca.
class ReceiptProductIdentityResolver {
  final ProductRepository repository;

  const ReceiptProductIdentityResolver(this.repository);

  ProductModel? existingForScan(ReceiptScanItem item) {
    final selected = item.productId?.trim();
    if (selected != null && selected.isNotEmpty) {
      return repository.findById(selected);
    }
    return repository.findByIdentity(
      name: item.description,
      brand: item.brand ?? '',
      defaultUnit: item.unit ?? '',
    );
  }

  Future<ProductModel?> resolveConfirmedItem({
    required String userId,
    required PurchaseItemModel item,
  }) async {
    final selected = item.productId?.trim();
    if (selected != null && selected.isNotEmpty) {
      return repository.findById(selected);
    }
    final name = item.name.trim();
    final unit = item.unit.trim();
    if (name.isEmpty || unit.isEmpty) return null;
    final existing = repository.findByIdentity(
      name: name,
      brand: item.brand,
      defaultUnit: unit,
    );
    if (existing != null) return existing;

    final now = DateTime.now();
    return repository.resolveLearnedProduct(
      userId: userId,
      candidate: ProductModel(
        id: const Uuid().v4(),
        name: name,
        normalizedName: repository.normalize(name),
        brand: item.brand,
        barcode: '',
        defaultUnit: unit,
        productCategoryId: item.productCategoryId,
        productCategoryName: item.productCategoryName,
        taxonomyId: item.taxonomyId,
        averagePrice: 0,
        lastPrice: 0,
        lastMerchantId: '',
        favorite: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
