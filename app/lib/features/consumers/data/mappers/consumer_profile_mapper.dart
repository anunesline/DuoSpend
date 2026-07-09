import '../../domain/consumer_profile_entity.dart';
import '../../domain/consumer_type.dart';
import '../models/consumer_profile_model.dart';

class ConsumerProfileMapper {
  const ConsumerProfileMapper();

  ConsumerProfileEntity toEntity(
    ConsumerProfileModel model,
  ) {
    return ConsumerProfileEntity(
      id: model.id,
      walletId: model.walletId,
      name: model.name,
      type: ConsumerType.fromValue(model.type),
      icon: model.icon,
      color: model.color,
      isActive: model.isActive,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  ConsumerProfileModel toModel(
    ConsumerProfileEntity entity,
  ) {
    return ConsumerProfileModel(
      id: entity.id,
      walletId: entity.walletId,
      name: entity.name,
      type: entity.type.value,
      icon: entity.icon,
      color: entity.color,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}