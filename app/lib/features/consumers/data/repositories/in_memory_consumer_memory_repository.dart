import '../../domain/intelligence/consumer_memory.dart';
import '../../domain/repositories/consumer_memory_repository.dart';

class InMemoryConsumerMemoryRepository
    implements ConsumerMemoryRepository {
  final Map<String, ConsumerMemory> _memories = {};

  String _key({
    required String walletId,
    required String consumerId,
  }) {
    return '$walletId::$consumerId';
  }

  @override
  Future<ConsumerMemory> load({
    required String walletId,
    required String consumerId,
  }) async {
    final key = _key(
      walletId: walletId,
      consumerId: consumerId,
    );

    return _memories.putIfAbsent(
      key,
      () => ConsumerMemory.empty(
        walletId: walletId,
        consumerId: consumerId,
      ),
    );
  }

  @override
  Future<void> save(
    ConsumerMemory memory,
  ) async {
    final key = _key(
      walletId: memory.walletId,
      consumerId: memory.consumerId,
    );

    _memories[key] = memory;
  }

  @override
  Future<void> reset({
    required String walletId,
    required String consumerId,
  }) async {
    final key = _key(
      walletId: walletId,
      consumerId: consumerId,
    );

    _memories.remove(key);
  }
}