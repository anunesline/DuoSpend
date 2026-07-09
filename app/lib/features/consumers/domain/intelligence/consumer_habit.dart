class ConsumerHabit {
  final String id;
  final String consumerId;
  final String walletId;

  final String productName;
  final String? normalizedProductName;
  final String? category;
  final String? subcategory;
  final String? brand;
  final String? variant;
  final String? packageDescription;

  final int occurrences;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  final double confidence;
  final int? averageIntervalInDays;

  const ConsumerHabit({
    required this.id,
    required this.consumerId,
    required this.walletId,
    required this.productName,
    this.normalizedProductName,
    this.category,
    this.subcategory,
    this.brand,
    this.variant,
    this.packageDescription,
    required this.occurrences,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.confidence,
    this.averageIntervalInDays,
  });

  ConsumerHabit copyWith({
    String? id,
    String? consumerId,
    String? walletId,
    String? productName,
    String? normalizedProductName,
    String? category,
    String? subcategory,
    String? brand,
    String? variant,
    String? packageDescription,
    int? occurrences,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    double? confidence,
    int? averageIntervalInDays,
  }) {
    return ConsumerHabit(
      id: id ?? this.id,
      consumerId: consumerId ?? this.consumerId,
      walletId: walletId ?? this.walletId,
      productName: productName ?? this.productName,
      normalizedProductName:
          normalizedProductName ?? this.normalizedProductName,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      brand: brand ?? this.brand,
      variant: variant ?? this.variant,
      packageDescription:
          packageDescription ?? this.packageDescription,
      occurrences: occurrences ?? this.occurrences,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      confidence: confidence ?? this.confidence,
      averageIntervalInDays:
          averageIntervalInDays ?? this.averageIntervalInDays,
    );
  }

  bool get isRecurring => occurrences >= 2;

  bool get isStrongHabit => confidence >= 0.7 && occurrences >= 3;
}