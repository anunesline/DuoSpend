import '../models/purchase_model.dart';

class PurchaseMemoryService {
  const PurchaseMemoryService();

  List<PurchaseModel> sortByMostRecent(List<PurchaseModel> purchases) {
    final sortedPurchases = List<PurchaseModel>.from(purchases);

    sortedPurchases.sort(
      (a, b) => b.purchaseDate.compareTo(a.purchaseDate),
    );

    return sortedPurchases;
  }

  List<PurchaseModel> filterByMerchant({
    required List<PurchaseModel> purchases,
    required String merchantId,
  }) {
    return purchases
        .where((purchase) => purchase.merchantId == merchantId)
        .toList();
  }

  List<PurchaseModel> filterByProductName({
    required List<PurchaseModel> purchases,
    required String productName,
  }) {
    final normalizedProductName = productName.trim().toLowerCase();

    if (normalizedProductName.isEmpty) {
      return [];
    }

    return purchases.where((purchase) {
      return purchase.items.any(
        (item) => item.name.toLowerCase().contains(normalizedProductName),
      );
    }).toList();
  }

  List<String> getFrequentProductNames(List<PurchaseModel> purchases) {
    final productCounter = <String, int>{};

    for (final purchase in purchases) {
      for (final item in purchase.items) {
        final productName = item.name.trim();

        if (productName.isEmpty) {
          continue;
        }

        productCounter[productName] = (productCounter[productName] ?? 0) + 1;
      }
    }

    final sortedEntries = productCounter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((entry) => entry.key).toList();
  }

  double getAveragePurchaseTotal(List<PurchaseModel> purchases) {
    if (purchases.isEmpty) {
      return 0;
    }

    final total = purchases.fold<double>(
      0,
      (sum, purchase) => sum + purchase.total,
    );

    return total / purchases.length;
  }

  double getAverageProductPrice({
    required List<PurchaseModel> purchases,
    required String productName,
  }) {
    final normalizedProductName = productName.trim().toLowerCase();

    if (normalizedProductName.isEmpty) {
      return 0;
    }

    final prices = <double>[];

    for (final purchase in purchases) {
      for (final item in purchase.items) {
        if (item.name.toLowerCase() == normalizedProductName) {
          prices.add(item.unitPrice);
        }
      }
    }

    if (prices.isEmpty) {
      return 0;
    }

    final total = prices.fold<double>(0, (sum, price) => sum + price);

    return total / prices.length;
  }
}