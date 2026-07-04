import '../../../data/models/transaction_item_model.dart';
import '../models/purchase_item_model.dart';

class PurchaseItemMapper {
  const PurchaseItemMapper();

  PurchaseItemModel fromTransactionItem(
    TransactionItemModel item, {
    String? purchaseId,
  }) {
    return PurchaseItemModel(
      id: item.id,
      purchaseId: purchaseId ?? item.transactionId,
      productId: item.productId,
      merchantId: item.merchantId,
      name: item.name,
      brand: item.brand,
      quantity: item.quantity,
      unit: item.unit,
      unitPrice: item.unitPrice,
      totalPrice: item.totalPrice,
      taxonomyId: item.taxonomyId,
      financialCategory: item.category,
      financialSubcategory: item.subcategory,
      productCategoryId: item.productCategoryId,
      productCategoryName: item.productCategoryName,
      createdAt: item.createdAt,
    );
  }

  List<PurchaseItemModel> fromTransactionItems(
    List<TransactionItemModel> items, {
    String? purchaseId,
  }) {
    return items
        .map(
          (item) => fromTransactionItem(
            item,
            purchaseId: purchaseId,
          ),
        )
        .toList();
  }

  TransactionItemModel toTransactionItem({
    required PurchaseItemModel item,
    required String transactionId,
  }) {
    return TransactionItemModel(
      id: item.id,
      transactionId: transactionId,
      productId: item.productId,
      merchantId: item.merchantId,
      name: item.name,
      brand: item.brand,
      quantity: item.quantity,
      unit: item.unit,
      unitPrice: item.unitPrice,
      totalPrice: item.totalPrice,
      taxonomyId: item.taxonomyId,
      category: item.financialCategory,
      subcategory: item.financialSubcategory,
      productCategoryId: item.productCategoryId,
      productCategoryName: item.productCategoryName,
      createdAt: item.createdAt,
    );
  }

  List<TransactionItemModel> toTransactionItems({
    required List<PurchaseItemModel> items,
    required String transactionId,
  }) {
    return items
        .map(
          (item) => toTransactionItem(
            item: item,
            transactionId: transactionId,
          ),
        )
        .toList();
  }
}