import '../consumer_profile_entity.dart';
import '../consumer_type.dart';
import '../repositories/consumer_profile_repository.dart';

class ConsumerLifecycleService {
  final ConsumerProfileRepository repository;

  const ConsumerLifecycleService(this.repository);

  Future<List<ConsumerProfileEntity>> getConsumersByWalletId(
    String walletId,
  ) {
    return repository.getByWalletId(walletId);
  }

  Future<ConsumerProfileEntity?> getById(
    String id,
  ) {
    return repository.getById(id);
  }

  Future<ConsumerProfileEntity> create({
    required String walletId,
    required String name,
    required ConsumerType type,
    String? icon,
    String? color,
  }) async {
    final now = DateTime.now();

    final consumer = ConsumerProfileEntity(
      id: '${walletId}_${now.microsecondsSinceEpoch}',
      walletId: walletId,
      name: name.trim(),
      type: type,
      icon: icon,
      color: color,
      isActive: true,
      createdAt: now,
    );

    await repository.save(consumer);

    return consumer;
  }

  Future<ConsumerProfileEntity> update(
    ConsumerProfileEntity consumer,
  ) async {
    final updated = consumer.copyWith(
      updatedAt: DateTime.now(),
    );

    await repository.save(updated);

    return updated;
  }

  Future<void> archive(
    String id,
  ) async {
    final consumer = await repository.getById(id);

    if (consumer == null) {
      return;
    }

    final archived = consumer.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );

    await repository.save(archived);
  }

  Future<void> restore(
    String id,
  ) async {
    final consumer = await repository.getById(id);

    if (consumer == null) {
      return;
    }

    final restored = consumer.copyWith(
      isActive: true,
      updatedAt: DateTime.now(),
    );

    await repository.save(restored);
  }

  Future<void> delete(
    String id,
  ) async {
    await repository.delete(id);
  }

  Future<ConsumerProfileEntity?> getDefaultConsumer(
    String walletId,
  ) async {
    final consumers = await repository.getByWalletId(walletId);

    final activeConsumers = consumers
        .where((consumer) => consumer.isActive)
        .toList();

    if (activeConsumers.isEmpty) {
      return null;
    }

    final owner = activeConsumers.where(
      (consumer) => consumer.id == '${walletId}_owner',
    );

    if (owner.isNotEmpty) {
      return owner.first;
    }

    return activeConsumers.first;
  }
}