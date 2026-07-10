import 'consumer_knowledge_payload.dart';
import 'consumer_memory.dart';

abstract interface class ConsumerIntelligenceEngine {
  Future<ConsumerMemory> learn({
    required ConsumerKnowledgePayload payload,
    required ConsumerMemory memory,
  });
}