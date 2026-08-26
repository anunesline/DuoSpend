class ReceiptScanItem {
  final String description;
  final double? quantity;
  final String? unit;
  final double? unitPrice;
  final double? totalPrice;

  const ReceiptScanItem({
    required this.description,
    this.quantity,
    this.unit,
    this.unitPrice,
    this.totalPrice,
  });

  ReceiptScanItem copyWith({
    String? description,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? totalPrice,
    bool clearQuantity = false,
    bool clearUnitPrice = false,
    bool clearTotalPrice = false,
  }) {
    return ReceiptScanItem(
      description: description ?? this.description,
      quantity: clearQuantity ? null : quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: clearUnitPrice ? null : unitPrice ?? this.unitPrice,
      totalPrice: clearTotalPrice ? null : totalPrice ?? this.totalPrice,
    );
  }
}
