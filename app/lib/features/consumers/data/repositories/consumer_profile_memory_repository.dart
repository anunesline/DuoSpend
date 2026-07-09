import '../../domain/consumer_profile_entity.dart';
import '../../domain/repositories/consumer_profile_repository.dart';

class ConsumerProfileMemoryRepository
    implements ConsumerProfileRepository {
  final Map<String, ConsumerProfileEntity> _consumers = {};

  @override
  Future<List<ConsumerProfileEntity>> getAll() async {
    return _consumers.values.toList();
  }

  @override
  Future<ConsumerProfileEntity?> getById(
    String id,
  ) async {
    return _consumers[id];
  }

  @override
  Future<void> save(
    ConsumerProfileEntity consumer,
  ) async {
    _consumers[consumer.id] = consumer;
  }

  @override
  Future<void> delete(
    String id,
  ) async {
    _consumers.remove(id);
  }
}