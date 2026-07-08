import '../contexts/knowledge_context.dart';

abstract interface class ReasoningEngine<TResult> {
  Future<TResult> reason(
    KnowledgeContext context,
  );
}