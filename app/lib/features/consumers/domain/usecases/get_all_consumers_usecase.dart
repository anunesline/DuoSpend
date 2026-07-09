import '../consumer_profile_entity.dart';
import '../repositories/consumer_profile_repository.dart';

class GetAllConsumersUseCase {
  final ConsumerProfileRepository _repository;

  const GetAllConsumersUseCase(this._repository);

  Future<List<ConsumerProfileEntity>> call() {
    return _repository.getAll();
  }
}