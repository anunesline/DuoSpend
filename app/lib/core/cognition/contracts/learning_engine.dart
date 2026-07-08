import '../contexts/knowledge_context.dart';

abstract interface class LearningEngine<TMemory> {
  TMemory learn(
    KnowledgeContext context,
    TMemory memory,
  );
}