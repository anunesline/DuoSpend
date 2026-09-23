class ReceiptScanItem {
  final String description;
  final String? originalDescription;
  final double? quantity;
  final String? unit;
  final String? brand;
  final String? productId;
  final double? unitPrice;
  final double? totalPrice;

  const ReceiptScanItem({
    required this.description,
    this.originalDescription,
    this.quantity,
    this.unit,
    this.brand,
    this.productId,
    this.unitPrice,
    this.totalPrice,
  });

  ReceiptScanItem copyWith({
    String? description,
    String? originalDescription,
    double? quantity,
    String? unit,
    String? brand,
    String? productId,
    double? unitPrice,
    double? totalPrice,
    bool clearQuantity = false,
    bool clearUnitPrice = false,
    bool clearTotalPrice = false,
    bool clearProductId = false,
  }) {
    return ReceiptScanItem(
      description: description ?? this.description,
      originalDescription: originalDescription ?? this.originalDescription,
      quantity: clearQuantity ? null : quantity ?? this.quantity,
      unit: unit ?? this.unit,
      brand: brand ?? this.brand,
      productId: clearProductId ? null : productId ?? this.productId,
      unitPrice: clearUnitPrice ? null : unitPrice ?? this.unitPrice,
      totalPrice: clearTotalPrice ? null : totalPrice ?? this.totalPrice,
    );
  }
}
