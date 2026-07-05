class ShoppingItemEntity {
  final String id;

  final String name;
  final String normalizedName;

  final double quantity;
  final String unit;

  final String? categoryId;
  final String? categoryName;

  final double? estimatedUnitPrice;
  final double? estimatedTotalPrice;

  final String status;
  final String source;
  final String priority;

  final bool isShared;

  final String? walletId;
  final String? createdByUserId;
  final String? assignedToUserId;

  final String? productMemoryId;
  final String? merchantId;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? purchasedAt;
  final DateTime? archivedAt;

  const ShoppingItemEntity({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.quantity,
    required this.unit,
    required this.status,
    required this.source,
    required this.priority,
    required this.isShared,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.categoryName,
    this.estimatedUnitPrice,
    this.estimatedTotalPrice,
    this.walletId,
    this.createdByUserId,
    this.assignedToUserId,
    this.productMemoryId,
    this.merchantId,
    this.purchasedAt,
    this.archivedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'normalizedName': normalizedName,
      'quantity': quantity,
      'unit': unit,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'estimatedUnitPrice': estimatedUnitPrice,
      'estimatedTotalPrice': estimatedTotalPrice,
      'status': status,
      'source': source,
      'priority': priority,
      'isShared': isShared,
      'walletId': walletId,
      'createdByUserId': createdByUserId,
      'assignedToUserId': assignedToUserId,
      'productMemoryId': productMemoryId,
      'merchantId': merchantId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'purchasedAt': purchasedAt,
      'archivedAt': archivedAt,
    };
  }

  factory ShoppingItemEntity.fromMap(Map<String, dynamic> map) {
    return ShoppingItemEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      normalizedName: map['normalizedName'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      categoryId: map['categoryId'] as String?,
      categoryName: map['categoryName'] as String?,
      estimatedUnitPrice: (map['estimatedUnitPrice'] as num?)?.toDouble(),
      estimatedTotalPrice: (map['estimatedTotalPrice'] as num?)?.toDouble(),
      status: map['status'] as String,
      source: map['source'] as String,
      priority: map['priority'] as String,
      isShared: map['isShared'] as bool? ?? false,
      walletId: map['walletId'] as String?,
      createdByUserId: map['createdByUserId'] as String?,
      assignedToUserId: map['assignedToUserId'] as String?,
      productMemoryId: map['productMemoryId'] as String?,
      merchantId: map['merchantId'] as String?,
      createdAt: map['createdAt'] as DateTime,
      updatedAt: map['updatedAt'] as DateTime,
      purchasedAt: map['purchasedAt'] as DateTime?,
      archivedAt: map['archivedAt'] as DateTime?,
    );
  }
}