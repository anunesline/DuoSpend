import '../../../transactions/domain/purchase/models/purchase_model.dart';

class ConsumerKnowledgePayload {
  final String walletId;
  final String consumerId;
  final PurchaseModel purchase;

  const ConsumerKnowledgePayload({
    required this.walletId,
    required this.consumerId,
    required this.purchase,
  });
}