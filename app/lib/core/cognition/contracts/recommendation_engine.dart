import '../contexts/knowledge_context.dart';

abstract interface class RecommendationEngine<TResult> {
  Future<List<TResult>> recommend(
    KnowledgeContext context,
  );
}