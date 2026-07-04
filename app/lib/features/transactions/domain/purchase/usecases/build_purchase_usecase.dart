import '../models/purchase_item_model.dart';
import '../models/purchase_model.dart';

class BuildPurchaseUseCase {
  const BuildPurchaseUseCase();

  PurchaseModel call({
    required String id,
    required String userId,
    required String walletId,
    required List<PurchaseItemModel> items,
    String? merchantId,
    required String merchantName,
    required String financialCategory,
    required String financialSubcategory,
    required DateTime purchaseDate,
    double discount = 0,
  }) {
    final normalizedFinancialCategory = _normalizeText(
      financialCategory,
      fallback: 'Sem categoria',
    );

    final normalizedFinancialSubcategory = _normalizeText(
      financialSubcategory,
      fallback: 'Sem subcategoria',
    );

    final normalizedMerchantName = merchantName.trim();

    final normalizedItems = _normalizeItems(
      purchaseId: id,
      merchantId: merchantId,
      financialCategory: normalizedFinancialCategory,
      financialSubcategory: normalizedFinancialSubcategory,
      items: items,
    );

    _validateItems(normalizedItems);
    _validateDiscount(discount);

    final subtotal = _calculateSubtotal(normalizedItems);
    final total = subtotal - discount;
    final now = DateTime.now();

    if (total <= 0) {
      throw Exception('O total da compra deve ser maior que zero.');
    }

    return PurchaseModel(
      id: id,
      userId: userId,
      walletId: walletId,
      merchantId: merchantId,
      merchantName: normalizedMerchantName,
      financialCategory: normalizedFinancialCategory,
      financialSubcategory: normalizedFinancialSubcategory,
      items: List.unmodifiable(normalizedItems),
      subtotal: subtotal,
      discount: discount,
      total: total,
      purchaseDate: purchaseDate,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<PurchaseItemModel> _normalizeItems({
    required String purchaseId,
    required String? merchantId,
    required String financialCategory,
    required String financialSubcategory,
    required List<PurchaseItemModel> items,
  }) {
    return items.map((item) {
      return item.copyWith(
        purchaseId: purchaseId,
        merchantId: merchantId ?? item.merchantId,
        financialCategory: financialCategory,
        financialSubcategory: financialSubcategory,
      );
    }).toList();
  }

  double _calculateSubtotal(List<PurchaseItemModel> items) {
    return items.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  void _validateItems(List<PurchaseItemModel> items) {
    if (items.isEmpty) {
      throw Exception('Adicione pelo menos um produto à compra.');
    }

    for (final item in items) {
      if (item.purchaseId.trim().isEmpty) {
        throw Exception('Todos os itens precisam estar vinculados à compra.');
      }

      if (item.name.trim().isEmpty) {
        throw Exception('Todos os produtos precisam ter nome.');
      }

      if (item.quantity <= 0) {
        throw Exception('A quantidade dos produtos deve ser maior que zero.');
      }

      if (item.unitPrice <= 0) {
        throw Exception('O preço unitário dos produtos deve ser maior que zero.');
      }

      if (item.totalPrice <= 0) {
        throw Exception('O valor total dos produtos deve ser maior que zero.');
      }
    }
  }

  void _validateDiscount(double discount) {
    if (discount < 0) {
      throw Exception('O desconto não pode ser negativo.');
    }
  }

  String _normalizeText(
    String value, {
    required String fallback,
  }) {
    final normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      return fallback;
    }

    return normalizedValue;
  }
}