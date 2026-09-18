class ProductPriceObservation {
  const ProductPriceObservation({
    required this.productId,
    required this.purchaseId,
    required this.purchasedAt,
    required this.unitPrice,
    required this.quantity,
    this.merchantId,
  });

  final String productId;
  final String purchaseId;
  final DateTime purchasedAt;
  final double unitPrice;
  final double quantity;
  final String? merchantId;

  String get id => '${productId}_$purchaseId';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'purchaseId': purchaseId,
      'purchasedAt': purchasedAt.toIso8601String(),
      'unitPrice': unitPrice,
      'quantity': quantity,
      'merchantId': merchantId,
    };
  }

  factory ProductPriceObservation.fromMap(Map<String, dynamic> map) {
    return ProductPriceObservation(
      productId: map['productId']?.toString() ?? '',
      purchaseId: map['purchaseId']?.toString() ?? '',
      purchasedAt:
          DateTime.tryParse(map['purchasedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      merchantId: map['merchantId']?.toString(),
    );
  }
}
