class MerchantMemoryModel {
  const MerchantMemoryModel({
    required this.merchantId,
    required this.merchantName,
    required this.timesVisited,
    required this.totalSpent,
    required this.averageTicket,
    required this.lastPurchaseAt,
    this.lastProducts = const [],
  });

  final String merchantId;
  final String merchantName;
  final int timesVisited;
  final double totalSpent;
  final double averageTicket;
  final DateTime lastPurchaseAt;
  final List<String> lastProducts;

  MerchantMemoryModel copyWith({
    String? merchantId,
    String? merchantName,
    int? timesVisited,
    double? totalSpent,
    double? averageTicket,
    DateTime? lastPurchaseAt,
    List<String>? lastProducts,
  }) {
    return MerchantMemoryModel(
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      timesVisited: timesVisited ?? this.timesVisited,
      totalSpent: totalSpent ?? this.totalSpent,
      averageTicket: averageTicket ?? this.averageTicket,
      lastPurchaseAt: lastPurchaseAt ?? this.lastPurchaseAt,
      lastProducts: lastProducts ?? this.lastProducts,
    );
  }

  factory MerchantMemoryModel.fromMap(Map<String, dynamic> map) {
    return MerchantMemoryModel(
      merchantId: map['merchantId'] ?? '',
      merchantName: map['merchantName'] ?? '',
      timesVisited: map['timesVisited'] ?? 0,
      totalSpent: (map['totalSpent'] ?? 0).toDouble(),
      averageTicket: (map['averageTicket'] ?? 0).toDouble(),
      lastPurchaseAt: DateTime.tryParse(map['lastPurchaseAt'] ?? '') ??
          DateTime.now(),
      lastProducts: List<String>.from(map['lastProducts'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'merchantName': merchantName,
      'timesVisited': timesVisited,
      'totalSpent': totalSpent,
      'averageTicket': averageTicket,
      'lastPurchaseAt': lastPurchaseAt.toIso8601String(),
      'lastProducts': lastProducts,
    };
  }
}