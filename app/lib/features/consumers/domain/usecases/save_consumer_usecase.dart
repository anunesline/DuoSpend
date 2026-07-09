import '../consumer_profile_entity.dart';
import '../services/consumer_lifecycle_service.dart';

class SaveConsumerUseCase {
  final ConsumerLifecycleService _lifecycle;

  const SaveConsumerUseCase(this._lifecycle);

  Future<ConsumerProfileEntity> call(
    ConsumerProfileEntity consumer,
  ) {
    return _lifecycle.update(consumer);
  }
}