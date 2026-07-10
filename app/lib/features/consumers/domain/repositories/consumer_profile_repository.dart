import '../consumer_profile_entity.dart';

abstract class ConsumerProfileRepository {
  Future<List<ConsumerProfileEntity>> getAll();

  Future<List<ConsumerProfileEntity>> getByWalletId(
    String walletId,
  );

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