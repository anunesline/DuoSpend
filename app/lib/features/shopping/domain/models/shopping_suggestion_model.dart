class ShoppingSuggestionModel {
  final String productName;

  final String normalizedName;

  final double suggestedQuantity;

  final String suggestedUnit;

  final String? suggestedCategoryId;
  final String? suggestedCategoryName;

  final double? averagePrice;

  final List<String> recentMerchants;

  final int purchaseCount;

  final int? averageDaysBetweenPurchases;

  final bool alreadyInShoppingList;

  const ShoppingSuggestionModel({
    required this.productName,
    required this.normalizedName,
    required this.suggestedQuantity,
    required this.suggestedUnit,
    required this.recentMerchants,
    required this.purchaseCount,
    required this.alreadyInShoppingList,
    this.suggestedCategoryId,
    this.suggestedCategoryName,
    this.averagePrice,
    this.averageDaysBetweenPurchases,
  });
}