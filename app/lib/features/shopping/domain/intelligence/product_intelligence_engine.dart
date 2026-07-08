import '../../../../core/cognition/contexts/cognition_scope.dart';
import '../../../../core/cognition/contexts/knowledge_context.dart';
import '../../../../core/cognition/payloads/purchase_knowledge_payload.dart';
import '../repositories/product_memory_repository.dart';
import 'product_classifier.dart';
import 'product_classification_result.dart';
import 'product_learning_engine.dart';
import 'product_matcher.dart';
import 'product_memory.dart';

class ProductIntelligenceEngine {
  final ProductMemoryRepository repository;
  final ProductClassifier classifier;
  final ProductMatcher matcher;
  final ProductLearningEngine learningEngine;

  const ProductIntelligenceEngine({
    required this.repository,
    this.classifier = const ProductClassifier(),
    this.matcher = const ProductMatcher(),
    this.learningEngine = const ProductLearningEngine(),
  });

  Future<ProductIntelligenceResult> process(String input) async {
    final memory = await repository.load();

    final classification = classifier.classify(input);

    final match = matcher.match(
      classification: classification,
      memory: memory,
    );

    final context = KnowledgeContext<PurchaseKnowledgePayload>(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      scope: const CognitionScope(
        type: CognitionScopeType.system,
        ownerId: 'system',
      ),
      source: KnowledgeContextSource.shoppingFlow,
      occurredAt: DateTime.now(),
      payload: PurchaseKnowledgePayload(
        rawText: classification.rawText,
        normalizedText: classification.normalizedText,
        canonicalName: classification.canonicalName,
        brand: classification.brand,
        variant: classification.variant,
        packageQuantity: classification.packageQuantity,
        packageUnit: classification.packageUnit,
        confidence: classification.confidence,
      ),
    );

    final updatedMemory = learningEngine.learn(
      context,
      memory,
    );

    await repository.save(updatedMemory);

    return ProductIntelligenceResult(
      classification: classification,
      match: match,
      previousMemory: memory,
      updatedMemory: updatedMemory,
    );
  }
}

class ProductIntelligenceResult {
  final ProductClassificationResult classification;
  final ProductMatchResult match;
  final ProductMemory previousMemory;
  final ProductMemory updatedMemory;

  const ProductIntelligenceResult({
    required this.classification,
    required this.match,
    required this.previousMemory,
    required this.updatedMemory,
  });
}