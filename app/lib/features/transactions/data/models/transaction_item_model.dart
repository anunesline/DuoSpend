import '../../domain/purchase/models/item_consumption.dart';

class TransactionItemModel {
  final String id;
  final String transactionId;
  final String? productId;
  final String? merchantId;

  final String name;
  final String brand;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;

  final String taxonomyId;

  // Classificação financeira/contextual
  final String category;
  final String subcategory;

  // Classificação real do produto
  final String productCategoryId;
  final String productCategoryName;

  final List<ItemConsumption> consumptions;

  final DateTime createdAt;

  const TransactionItemModel({
    required this.id,
    required this.transactionId,
    this.productId,
    this.merchantId,
    required this.name,
    required this.brand,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    required this.taxonomyId,
    required this.category,
    required this.subcategory,
    required this.productCategoryId,
    required this.productCategoryName,
    this.consumptions = const [],
    required this.createdAt,
  });

  bool get hasConsumptionData => consumptions.isNotEmpty;

  List<String> get consumerIds => consumptions
      .map((consumption) => consumption.consumerId)
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  TransactionItemModel copyWith({
    String? transactionId,
    String? productId,
    String? merchantId,
    List<ItemConsumption>? consumptions,
  }) {
    return TransactionItemModel(
      id: id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      merchantId: merchantId ?? this.merchantId,
      name: name,
      brand: brand,
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      taxonomyId: taxonomyId,
      category: category,
      subcategory: subcategory,
      productCategoryId: productCategoryId,
      productCategoryName: productCategoryName,
      consumptions: consumptions ?? this.consumptions,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'productId': productId,
      'merchantId': merchantId,
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'taxonomyId': taxonomyId,
      'category': category,
      'subcategory': subcategory,
      'productCategoryId': productCategoryId,
      'productCategoryName': productCategoryName,
      'consumptions':
          consumptions.map((consumption) => consumption.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map['id'] ?? '',
      transactionId: map['transactionId'] ?? '',
      productId: map['productId'],
      merchantId: map['merchantId'],
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'un',
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      taxonomyId: map['taxonomyId'] ?? '',
      category: map['category'] ?? 'Sem categoria',
      subcategory: map['subcategory'] ?? 'Sem subcategoria',
      productCategoryId: map['productCategoryId'] ?? '',
      productCategoryName: map['productCategoryName'] ?? '',
      consumptions: (map['consumptions'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                (consumption) => ItemConsumption.fromMap(
                  Map<String, dynamic>.from(consumption),
                ),
              )
              .toList() ??
          const [],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}