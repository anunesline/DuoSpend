class ProductPriceObservation {
  const ProductPriceObservation({
    required this.productId,
    required this.purchaseId,
    required this.purchasedAt,
    required this.unitPrice,
    required this.quantity,
    this.merchantId,
    this.merchantName,
    this.productCategoryId,
    this.productCategoryName,
    this.totalPrice,
  });

  final String productId;
  final String purchaseId;
  final DateTime purchasedAt;
  final double unitPrice;
  final double quantity;
  final String? merchantId;
  final String? merchantName;
  final String? productCategoryId;
  final String? productCategoryName;

  /// Total efetivamente observado para o item nesta compra.
  ///
  /// Observações legadas não possuem esse campo; nesse caso, o total pode ser
  /// reconstruído sem inferência usando preço unitário × quantidade.
  final double? totalPrice;

  String get id => '${productId}_$purchaseId';

  double get observedTotal {
    final storedTotal = totalPrice;
    if (storedTotal != null && storedTotal > 0) {
      return storedTotal;
    }

    return unitPrice * quantity;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'purchaseId': purchaseId,
      'purchasedAt': purchasedAt.toIso8601String(),
      'unitPrice': unitPrice,
      'quantity': quantity,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'productCategoryId': productCategoryId,
      'productCategoryName': productCategoryName,
      'totalPrice': totalPrice,
    };
  }

  factory ProductPriceObservation.fromMap(
    Map<String, dynamic> map, {
    String? fallbackProductId,
  }) {
    return ProductPriceObservation(
      productId:
          _nullableText(map['productId']) ?? fallbackProductId?.trim() ?? '',
      purchaseId: map['purchaseId']?.toString() ?? '',
      purchasedAt: _dateTime(map['purchasedAt']),
      unitPrice: _double(map['unitPrice']),
      quantity: _double(map['quantity']),
      merchantId: _nullableText(map['merchantId']),
      merchantName: _nullableText(map['merchantName']),
      productCategoryId: _nullableText(map['productCategoryId']),
      productCategoryName: _nullableText(map['productCategoryName']),
      totalPrice: _nullableDouble(map['totalPrice']),
    );
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static double _double(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    final parsed = _double(value);
    return parsed > 0 ? parsed : null;
  }

  static DateTime _dateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
