import '../../domain/models/shopping_item_model.dart';
import '../models/shopping_item_entity.dart';

class ShoppingItemMapper {
  const ShoppingItemMapper._();

  static ShoppingItemEntity toEntity(ShoppingItemModel model) {
    return ShoppingItemEntity(
      id: model.id,
      name: model.name,
      normalizedName: model.normalizedName,
      quantity: model.quantity,
      unit: model.unit,
      categoryId: model.categoryId,
      categoryName: model.categoryName,
      estimatedUnitPrice: model.estimatedUnitPrice,
      estimatedTotalPrice: model.estimatedTotalPrice,
      status: model.status.name,
      source: model.source.name,
      priority: model.priority.name,
      isShared: model.isShared,
      walletId: model.walletId,
      createdByUserId: model.createdByUserId,
      assignedToUserId: model.assignedToUserId,
      productMemoryId: model.productMemoryId,
      merchantId: model.merchantId,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      purchasedAt: model.purchasedAt,
      archivedAt: model.archivedAt,
    );
  }

  static ShoppingItemModel toModel(ShoppingItemEntity entity) {
    return ShoppingItemModel(
      id: entity.id,
      name: entity.name,
      normalizedName: entity.normalizedName,
      quantity: entity.quantity,
      unit: entity.unit,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      estimatedUnitPrice: entity.estimatedUnitPrice,
      estimatedTotalPrice: entity.estimatedTotalPrice,
      status: _mapStatus(entity.status),
      source: _mapSource(entity.source),
      priority: _mapPriority(entity.priority),
      isShared: entity.isShared,
      walletId: entity.walletId,
      createdByUserId: entity.createdByUserId,
      assignedToUserId: entity.assignedToUserId,
      productMemoryId: entity.productMemoryId,
      merchantId: entity.merchantId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      purchasedAt: entity.purchasedAt,
      archivedAt: entity.archivedAt,
    );
  }

  static List<ShoppingItemModel> toModelList(
    List<ShoppingItemEntity> entities,
  ) {
    return entities.map(toModel).toList();
  }

  static List<ShoppingItemEntity> toEntityList(
    List<ShoppingItemModel> models,
  ) {
    return models.map(toEntity).toList();
  }

  static ShoppingItemStatus _mapStatus(String value) {
    return ShoppingItemStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ShoppingItemStatus.pending,
    );
  }

  static ShoppingItemSource _mapSource(String value) {
    return ShoppingItemSource.values.firstWhere(
      (source) => source.name == value,
      orElse: () => ShoppingItemSource.manual,
    );
  }

  static ShoppingItemPriority _mapPriority(String value) {
    return ShoppingItemPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => ShoppingItemPriority.normal,
    );
  }
}
