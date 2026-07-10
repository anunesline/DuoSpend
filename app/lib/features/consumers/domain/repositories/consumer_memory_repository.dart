import '../intelligence/consumer_memory.dart';

abstract class ConsumerMemoryRepository {
  Future<ConsumerMemory> load({
    required String walletId,
    required String consumerId,
  });

  Future<void> save(
    ConsumerMemory memory,
  );

  Future<void> reset({
    required String walletId,
    required String consumerId,
  });
}