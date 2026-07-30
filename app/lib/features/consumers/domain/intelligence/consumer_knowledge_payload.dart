import '../../../transactions/domain/purchase/models/purchase_item_model.dart';

class ConsumerKnowledgePayload {
  final String walletId;
  final String consumerId;
  final List<PurchaseItemModel> consumedItems;

  const ConsumerKnowledgePayload({
    required this.walletId,
    required this.consumerId,
    required this.consumedItems,
  });

  bool get hasConsumedItems => consumedItems.isNotEmpty;
}