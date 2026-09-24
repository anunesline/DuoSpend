import '../../transactions/data/models/transaction_item_model.dart';
import '../domain/models/receipt_scan_item.dart';

/// Converte itens temporários do scanner para a estrutura real de compra.
/// O resultado ainda fica apenas nos controllers, até a confirmação normal da
/// Nova Transação.
class ReceiptTransactionItemMapper {
  const ReceiptTransactionItemMapper();

  List<TransactionItemModel> map({
    required List<ReceiptScanItem> items,
    required String category,
    required String subcategory,
    required String taxonomyId,
    required DateTime createdAt,
  }) {
    final mappedItems = <TransactionItemModel>[];
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final name = item.description.trim();
      final quantity = item.quantity;
      if (quantity == null ||
          quantity <= 0 ||
          item.unit?.trim().isNotEmpty != true ||
          item.unitPrice == null)
        continue;
      final totalPrice = _resolveTotalPrice(item, quantity);
      if (name.isEmpty || totalPrice == null || totalPrice <= 0) continue;

      final unitPrice = item.unitPrice != null && item.unitPrice! > 0
          ? item.unitPrice!
          : totalPrice / quantity;
      mappedItems.add(
        TransactionItemModel(
          id: '${createdAt.microsecondsSinceEpoch}-$index',
          transactionId: '',
          productId: item.productId,
          name: name,
          brand: item.brand ?? '',
          quantity: quantity,
          unit: item.unit!.trim(),
          unitPrice: unitPrice,
          totalPrice: totalPrice,
          taxonomyId: taxonomyId,
          category: category,
          subcategory: subcategory,
          productCategoryId: '',
          productCategoryName: '',
          createdAt: createdAt,
        ),
      );
    }

    return List.unmodifiable(mappedItems);
  }

  double? _resolveTotalPrice(ReceiptScanItem item, double quantity) {
    if (item.totalPrice != null && item.totalPrice! > 0) {
      return item.totalPrice;
    }
    if (item.unitPrice != null && item.unitPrice! > 0) {
      return item.unitPrice! * quantity;
    }
    return null;
  }
}
