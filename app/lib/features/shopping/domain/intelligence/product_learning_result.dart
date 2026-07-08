class ProductLearningResult {
  final bool memoryUpdated;
  final bool statisticsUpdated;

  final int purchaseCount;

  final DateTime? firstPurchaseAt;
  final DateTime? lastPurchaseAt;

  const ProductLearningResult({
    required this.memoryUpdated,
    required this.statisticsUpdated,
    required this.purchaseCount,
    this.firstPurchaseAt,
    this.lastPurchaseAt,
  });

  bool get hasLearning =>
      memoryUpdated || statisticsUpdated;
}