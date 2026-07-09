import '../consumer_profile_entity.dart';
import '../services/consumer_lifecycle_service.dart';

class GetConsumersByWalletIdUseCase {
  final ConsumerLifecycleService _lifecycle;

  const GetConsumersByWalletIdUseCase(this._lifecycle);

  Future<List<ConsumerProfileEntity>> call(
    String walletId,
  ) {
    return _lifecycle.getConsumersByWalletId(walletId);
  }
}