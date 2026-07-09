import '../consumer_profile_entity.dart';
import '../services/consumer_lifecycle_service.dart';

class GetConsumerByIdUseCase {
  final ConsumerLifecycleService _lifecycle;

  const GetConsumerByIdUseCase(this._lifecycle);

  Future<ConsumerProfileEntity?> call(String id) {
    return _lifecycle.getById(id);
  }
}