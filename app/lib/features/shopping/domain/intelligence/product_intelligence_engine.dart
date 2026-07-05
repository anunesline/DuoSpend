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

    final updatedMemory = learningEngine.learn(
      classification: classification,
      match: match,
      memory: memory,
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