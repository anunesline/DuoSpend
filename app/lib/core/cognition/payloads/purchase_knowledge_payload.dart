import '../contexts/knowledge_context.dart';

class PurchaseKnowledgePayload extends KnowledgePayload {
  final String rawText;
  final String normalizedText;
  final String canonicalName;

  final String? brand;
  final String? variant;

  final double? packageQuantity;
  final String? packageUnit;

  final String? merchantId;
  final String? merchantName;

  /// Financial Scope (quem pagou)
  final String? walletId;

  /// Consumer (quem consome)
  final String? consumerId;

  final double? quantity;
  final double? unitPrice;
  final double? totalPrice;

  final double confidence;

  const PurchaseKnowledgePayload({
    required this.rawText,
    required this.normalizedText,
    required this.canonicalName,
    this.brand,
    this.variant,
    this.packageQuantity,
    this.packageUnit,
    this.merchantId,
    this.merchantName,
    this.walletId,
    this.consumerId,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
    this.confidence = 0.0,
  });
}