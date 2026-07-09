import '../consumer_profile_entity.dart';
import '../repositories/consumer_profile_repository.dart';

class GetConsumerByIdUseCase {
  final ConsumerProfileRepository _repository;

  const GetConsumerByIdUseCase(this._repository);

  Future<ConsumerProfileEntity?> call(String id) {
    return _repository.getById(id);
  }
}