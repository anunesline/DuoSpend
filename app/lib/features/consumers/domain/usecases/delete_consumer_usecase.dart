import '../services/consumer_lifecycle_service.dart';

class DeleteConsumerUseCase {
  final ConsumerLifecycleService _lifecycle;

  const DeleteConsumerUseCase(this._lifecycle);

  Future<void> call(
    String id,
  ) {
    return _lifecycle.archive(id);
  }
}