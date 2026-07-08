import '../memory_scope.dart';
import '../product_classification_result.dart';
import '../product_matcher.dart';
import '../product_memory.dart';

class KnowledgeContext {
  final MemoryScope scope;
  final DateTime occurredAt;

  final ProductClassificationResult classification;
  final ProductMatchResult match;
  final ProductMemory memory;

  final String? merchantId;
  final String? merchantName;

  final double? quantity;
  final double? unitPrice;
  final double? totalPrice;

  const KnowledgeContext({
    required this.scope,
    required this.occurredAt,
    required this.classification,
    required this.match,
    required this.memory,
    this.merchantId,
    this.merchantName,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
  });

  KnowledgeContext copyWith({
    MemoryScope? scope,
    DateTime? occurredAt,
    ProductClassificationResult? classification,
    ProductMatchResult? match,
    ProductMemory? memory,
    String? merchantId,
    String? merchantName,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return KnowledgeContext(
      scope: scope ?? this.scope,
      occurredAt: occurredAt ?? this.occurredAt,
      classification: classification ?? this.classification,
      match: match ?? this.match,
      memory: memory ?? this.memory,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}