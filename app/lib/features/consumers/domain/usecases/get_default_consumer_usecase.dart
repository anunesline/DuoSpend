import '../consumer_profile_entity.dart';
import '../services/consumer_lifecycle_service.dart';

class GetDefaultConsumerUseCase {
  final ConsumerLifecycleService _lifecycle;

  const GetDefaultConsumerUseCase(this._lifecycle);

  Future<ConsumerProfileEntity?> call(
    String walletId,
  ) {
    return _lifecycle.getDefaultConsumer(walletId);
  }
}