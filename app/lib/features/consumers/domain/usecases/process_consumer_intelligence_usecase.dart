import '../intelligence/consumer_intelligence_engine.dart';
import '../intelligence/consumer_knowledge_payload.dart';
import '../intelligence/consumer_memory_loader.dart';
import '../intelligence/consumer_memory.dart';

class ProcessConsumerIntelligenceUseCase {
  final ConsumerMemoryLoader memoryLoader;
  final ConsumerIntelligenceEngine intelligenceEngine;

  const ProcessConsumerIntelligenceUseCase({
    required this.memoryLoader,
    required this.intelligenceEngine,
  });

  Future<ConsumerMemory> execute({
    required ConsumerKnowledgePayload payload,
  }) async {
    final memory = await memoryLoader.load(
      walletId: payload.walletId,
      consumerId: payload.consumerId,
    );

    final updatedMemory = await intelligenceEngine.learn(
      payload: payload,
      memory: memory,
    );

    await memoryLoader.save(updatedMemory);

    return updatedMemory;
  }
}