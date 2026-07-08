import '../contexts/knowledge_context.dart';

abstract interface class LearningEngine<TMemory> {
  Future<TMemory> learn(
    KnowledgeContext context,
    TMemory memory,
  );
}