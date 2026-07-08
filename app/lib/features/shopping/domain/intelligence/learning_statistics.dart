class LearningStatistics {
  final int purchaseCount;
  final DateTime? firstPurchaseAt;
  final DateTime? lastPurchaseAt;
  final double? averageUnitPrice;
  final double? averageTotalPrice;
  final String? preferredBrandName;
  final String? preferredMerchantName;
  final String? preferredPackageDescription;
  final double? averagePurchaseIntervalInDays;

  const LearningStatistics({
    this.purchaseCount = 0,
    this.firstPurchaseAt,
    this.lastPurchaseAt,
    this.averageUnitPrice,
    this.averageTotalPrice,
    this.preferredBrandName,
    this.preferredMerchantName,
    this.preferredPackageDescription,
    this.averagePurchaseIntervalInDays,
  });

  bool get hasPurchases => purchaseCount > 0;

  LearningStatistics registerPurchase({
    required DateTime purchasedAt,
    double? unitPrice,
    double? totalPrice,
    String? brandName,
    String? merchantName,
    String? packageDescription,
  }) {
    final newPurchaseCount = purchaseCount + 1;

    final newFirstPurchaseAt = firstPurchaseAt == null
        ? purchasedAt
        : _earliest(firstPurchaseAt!, purchasedAt);

    final newLastPurchaseAt = lastPurchaseAt == null
        ? purchasedAt
        : _latest(lastPurchaseAt!, purchasedAt);

    return copyWith(
      purchaseCount: newPurchaseCount,
      firstPurchaseAt: newFirstPurchaseAt,
      lastPurchaseAt: newLastPurchaseAt,
      averageUnitPrice: _calculateAverage(
        currentAverage: averageUnitPrice,
        newValue: unitPrice,
        newCount: newPurchaseCount,
      ),
      averageTotalPrice: _calculateAverage(
        currentAverage: averageTotalPrice,
        newValue: totalPrice,
        newCount: newPurchaseCount,
      ),
      preferredBrandName: _resolvePreference(
        currentValue: preferredBrandName,
        newValue: brandName,
      ),
      preferredMerchantName: _resolvePreference(
        currentValue: preferredMerchantName,
        newValue: merchantName,
      ),
      preferredPackageDescription: _resolvePreference(
        currentValue: preferredPackageDescription,
        newValue: packageDescription,
      ),
      averagePurchaseIntervalInDays: _calculateAverageIntervalInDays(
        firstPurchaseAt: newFirstPurchaseAt,
        lastPurchaseAt: newLastPurchaseAt,
        purchaseCount: newPurchaseCount,
      ),
    );
  }

  LearningStatistics copyWith({
    int? purchaseCount,
    DateTime? firstPurchaseAt,
    DateTime? lastPurchaseAt,
    double? averageUnitPrice,
    double? averageTotalPrice,
    String? preferredBrandName,
    String? preferredMerchantName,
    String? preferredPackageDescription,
    double? averagePurchaseIntervalInDays,
  }) {
    return LearningStatistics(
      purchaseCount: purchaseCount ?? this.purchaseCount,
      firstPurchaseAt: firstPurchaseAt ?? this.firstPurchaseAt,
      lastPurchaseAt: lastPurchaseAt ?? this.lastPurchaseAt,
      averageUnitPrice: averageUnitPrice ?? this.averageUnitPrice,
      averageTotalPrice: averageTotalPrice ?? this.averageTotalPrice,
      preferredBrandName: preferredBrandName ?? this.preferredBrandName,
      preferredMerchantName:
          preferredMerchantName ?? this.preferredMerchantName,
      preferredPackageDescription:
          preferredPackageDescription ?? this.preferredPackageDescription,
      averagePurchaseIntervalInDays:
          averagePurchaseIntervalInDays ?? this.averagePurchaseIntervalInDays,
    );
  }

  DateTime _earliest(DateTime a, DateTime b) {
    return a.isBefore(b) ? a : b;
  }

  DateTime _latest(DateTime a, DateTime b) {
    return a.isAfter(b) ? a : b;
  }

  double? _calculateAverage({
    required double? currentAverage,
    required double? newValue,
    required int newCount,
  }) {
    if (newValue == null) {
      return currentAverage;
    }

    if (currentAverage == null || newCount <= 1) {
      return newValue;
    }

    return ((currentAverage * (newCount - 1)) + newValue) / newCount;
  }

  String? _resolvePreference({
    required String? currentValue,
    required String? newValue,
  }) {
    final cleanedValue = newValue?.trim();

    if (cleanedValue == null || cleanedValue.isEmpty) {
      return currentValue;
    }

    return cleanedValue;
  }

  double? _calculateAverageIntervalInDays({
    required DateTime? firstPurchaseAt,
    required DateTime? lastPurchaseAt,
    required int purchaseCount,
  }) {
    if (firstPurchaseAt == null || lastPurchaseAt == null) {
      return null;
    }

    if (purchaseCount <= 1) {
      return null;
    }

    final totalDays = lastPurchaseAt.difference(firstPurchaseAt).inDays;

    if (totalDays <= 0) {
      return 0;
    }

    return totalDays / (purchaseCount - 1);
  }
}