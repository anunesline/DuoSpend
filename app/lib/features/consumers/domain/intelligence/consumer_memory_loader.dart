import '../repositories/consumer_memory_repository.dart';
import 'consumer_memory.dart';

class ConsumerMemoryLoader {
  final ConsumerMemoryRepository repository;

  const ConsumerMemoryLoader({
    required this.repository,
  });

  Future<ConsumerMemory> load({
    required String walletId,
    required String consumerId,
  }) {
    return repository.load(
      walletId: walletId,
      consumerId: consumerId,
    );
  }

  Future<void> save(
    ConsumerMemory memory,
  ) {
    return repository.save(memory);
  }

  Future<void> reset({
    required String walletId,
    required String consumerId,
  }) {
    return repository.reset(
      walletId: walletId,
      consumerId: consumerId,
    );
  }
}