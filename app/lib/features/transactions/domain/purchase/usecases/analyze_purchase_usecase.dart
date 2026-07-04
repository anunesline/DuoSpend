import '../models/purchase_model.dart';

class AnalyzePurchaseResult {
  final PurchaseModel purchase;
  final String merchantName;
  final int itemCount;
  final double total;
  final List<String> productNames;

  const AnalyzePurchaseResult({
    required this.purchase,
    required this.merchantName,
    required this.itemCount,
    required this.total,
    required this.productNames,
  });
}

class AnalyzePurchaseUseCase {
  const AnalyzePurchaseUseCase();

  AnalyzePurchaseResult call(PurchaseModel purchase) {
    if (!purchase.hasItems) {
      throw Exception('Não é possível analisar uma compra sem itens.');
    }

    final productNames = purchase.items
        .map((item) => item.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    return AnalyzePurchaseResult(
      purchase: purchase,
      merchantName: purchase.merchantName.trim(),
      itemCount: purchase.itemCount,
      total: purchase.total,
      productNames: productNames,
    );
  }
}