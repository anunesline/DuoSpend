import '../consumer_profile_entity.dart';
import '../consumer_type.dart';
import '../services/consumer_lifecycle_service.dart';

class CreateConsumerUseCase {
  final ConsumerLifecycleService _lifecycle;

  const CreateConsumerUseCase(this._lifecycle);

  Future<ConsumerProfileEntity> call({
    required String walletId,
    required String name,
    required ConsumerType type,
    String? icon,
    String? color,
  }) {
    return _lifecycle.create(
      walletId: walletId,
      name: name,
      type: type,
      icon: icon,
      color: color,
    );
  }
}