import '../consumer_profile_entity.dart';
import '../repositories/consumer_profile_repository.dart';

class SaveConsumerUseCase {
  final ConsumerProfileRepository _repository;

  const SaveConsumerUseCase(this._repository);

  Future<void> call(
    ConsumerProfileEntity consumer,
  ) {
    return _repository.save(consumer);
  }
}