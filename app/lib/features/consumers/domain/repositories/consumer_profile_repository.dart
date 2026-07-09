import '../consumer_profile_entity.dart';

abstract interface class ConsumerProfileRepository {
  Future<List<ConsumerProfileEntity>> getAll();

  Future<ConsumerProfileEntity?> getById(
    String id,
  );

  Future<void> save(
    ConsumerProfileEntity consumer,
  );

  Future<void> delete(
    String id,
  );
}