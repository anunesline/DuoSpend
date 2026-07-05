enum ShoppingItemStatus {
  pending,
  purchased,
  skipped,
  archived,
}

enum ShoppingItemSource {
  manual,
  purchaseMemory,
  productMemory,
  recurring,
  suggestion,
}

enum ShoppingItemPriority {
  low,
  normal,
  high,
  urgent,
}

class ShoppingItemModel {
  final String id;

  final String name;
  final String normalizedName;

  final double quantity;
  final String unit;

  final String? categoryId;
  final String? categoryName;

  final double? estimatedUnitPrice;
  final double? estimatedTotalPrice;

  final ShoppingItemStatus status;
  final ShoppingItemSource source;
  final ShoppingItemPriority priority;

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

  const ShoppingItemModel({
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

  bool get isPending => status == ShoppingItemStatus.pending;

  bool get isPurchased => status == ShoppingItemStatus.purchased;

  bool get isArchived => status == ShoppingItemStatus.archived;

  bool get wasSuggested => source == ShoppingItemSource.suggestion;

  bool get cameFromMemory =>
      source == ShoppingItemSource.purchaseMemory ||
      source == ShoppingItemSource.productMemory;

  ShoppingItemModel copyWith({
    String? id,
    String? name,
    String? normalizedName,
    double? quantity,
    String? unit,
    String? categoryId,
    String? categoryName,
    double? estimatedUnitPrice,
    double? estimatedTotalPrice,
    ShoppingItemStatus? status,
    ShoppingItemSource? source,
    ShoppingItemPriority? priority,
    bool? isShared,
    String? walletId,
    String? createdByUserId,
    String? assignedToUserId,
    String? productMemoryId,
    String? merchantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? purchasedAt,
    DateTime? archivedAt,
  }) {
    return ShoppingItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      estimatedUnitPrice: estimatedUnitPrice ?? this.estimatedUnitPrice,
      estimatedTotalPrice: estimatedTotalPrice ?? this.estimatedTotalPrice,
      status: status ?? this.status,
      source: source ?? this.source,
      priority: priority ?? this.priority,
      isShared: isShared ?? this.isShared,
      walletId: walletId ?? this.walletId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      productMemoryId: productMemoryId ?? this.productMemoryId,
      merchantId: merchantId ?? this.merchantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  factory ShoppingItemModel.create({
    required String id,
    required String name,
    required String normalizedName,
    double quantity = 1,
    String unit = 'un',
    String? categoryId,
    String? categoryName,
    double? estimatedUnitPrice,
    double? estimatedTotalPrice,
    ShoppingItemSource source = ShoppingItemSource.manual,
    ShoppingItemPriority priority = ShoppingItemPriority.normal,
    bool isShared = false,
    String? walletId,
    String? createdByUserId,
    String? assignedToUserId,
    String? productMemoryId,
    String? merchantId,
    DateTime? now,
  }) {
    final currentDate = now ?? DateTime.now();

    return ShoppingItemModel(
      id: id,
      name: name,
      normalizedName: normalizedName,
      quantity: quantity,
      unit: unit,
      categoryId: categoryId,
      categoryName: categoryName,
      estimatedUnitPrice: estimatedUnitPrice,
      estimatedTotalPrice: estimatedTotalPrice,
      status: ShoppingItemStatus.pending,
      source: source,
      priority: priority,
      isShared: isShared,
      walletId: walletId,
      createdByUserId: createdByUserId,
      assignedToUserId: assignedToUserId,
      productMemoryId: productMemoryId,
      merchantId: merchantId,
      createdAt: currentDate,
      updatedAt: currentDate,
    );
  }

  ShoppingItemModel markAsPurchased({DateTime? purchasedDate}) {
    final currentDate = purchasedDate ?? DateTime.now();

    return copyWith(
      status: ShoppingItemStatus.purchased,
      purchasedAt: currentDate,
      updatedAt: currentDate,
    );
  }

  ShoppingItemModel archive({DateTime? archivedDate}) {
    final currentDate = archivedDate ?? DateTime.now();

    return copyWith(
      status: ShoppingItemStatus.archived,
      archivedAt: currentDate,
      updatedAt: currentDate,
    );
  }

  ShoppingItemModel skip({DateTime? skippedDate}) {
    final currentDate = skippedDate ?? DateTime.now();

    return copyWith(
      status: ShoppingItemStatus.skipped,
      updatedAt: currentDate,
    );
  }
}