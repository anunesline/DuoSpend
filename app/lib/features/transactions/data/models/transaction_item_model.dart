class TransactionItemModel {
  final String id;
  final String transactionId;
  final String name;
  final String brand;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;
  final String taxonomyId;
  final DateTime createdAt;

  TransactionItemModel({
    required this.id,
    required this.transactionId,
    required this.name,
    required this.brand,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    required this.taxonomyId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'taxonomyId': taxonomyId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map['id'] ?? '',
      transactionId: map['transactionId'] ?? '',
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'un',
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      taxonomyId: map['taxonomyId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}