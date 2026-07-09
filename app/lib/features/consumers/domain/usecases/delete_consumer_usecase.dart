import '../repositories/consumer_profile_repository.dart';

class DeleteConsumerUseCase {
  final ConsumerProfileRepository _repository;

  const DeleteConsumerUseCase(this._repository);

  Future<void> call(
    String id,
  ) {
    return _repository.delete(id);
  }
}