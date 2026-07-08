import '../contexts/knowledge_context.dart';

abstract interface class PredictionEngine<TResult> {
  Future<TResult> predict(
    KnowledgeContext context,
  );
}