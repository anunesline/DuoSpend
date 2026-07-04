class PurchaseItemModel {
  final String id;
  final String purchaseId;
  final String? productId;
  final String? merchantId;

  final String name;
  final String brand;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;

  final String taxonomyId;

  final String financialCategory;
  final String financialSubcategory;

  final String productCategoryId;
  final String productCategoryName;

  final DateTime createdAt;

  const PurchaseItemModel({
    required this.id,
    required this.purchaseId,
    this.productId,
    this.merchantId,
    required this.name,
    required this.brand,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    required this.taxonomyId,
    required this.financialCategory,
    required this.financialSubcategory,
    required this.productCategoryId,
    required this.productCategoryName,
    required this.createdAt,
  });

  PurchaseItemModel copyWith({
    String? id,
    String? purchaseId,
    String? productId,
    String? merchantId,
    String? name,
    String? brand,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? totalPrice,
    String? taxonomyId,
    String? financialCategory,
    String? financialSubcategory,
    String? productCategoryId,
    String? productCategoryName,
    DateTime? createdAt,
  }) {
    return PurchaseItemModel(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      taxonomyId: taxonomyId ?? this.taxonomyId,
      financialCategory: financialCategory ?? this.financialCategory,
      financialSubcategory: financialSubcategory ?? this.financialSubcategory,
      productCategoryId: productCategoryId ?? this.productCategoryId,
      productCategoryName: productCategoryName ?? this.productCategoryName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchaseId': purchaseId,
      'productId': productId,
      'merchantId': merchantId,
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'taxonomyId': taxonomyId,
      'financialCategory': financialCategory,
      'financialSubcategory': financialSubcategory,
      'productCategoryId': productCategoryId,
      'productCategoryName': productCategoryName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PurchaseItemModel.fromMap(Map<String, dynamic> map) {
    return PurchaseItemModel(
      id: map['id'] ?? '',
      purchaseId: map['purchaseId'] ?? '',
      productId: map['productId'],
      merchantId: map['merchantId'],
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'un',
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      taxonomyId: map['taxonomyId'] ?? '',
      financialCategory: map['financialCategory'] ?? 'Sem categoria',
      financialSubcategory:
          map['financialSubcategory'] ?? 'Sem subcategoria',
      productCategoryId: map['productCategoryId'] ?? '',
      productCategoryName: map['productCategoryName'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}