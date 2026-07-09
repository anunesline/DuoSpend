import '../../data/models/consumer_profile_model.dart';
import '../../../transactions/data/models/transaction_model.dart';

class ConsumerKnowledgePayload {
  final String walletId;
  final String consumerId;

  final ConsumerProfileModel consumer;

  final TransactionModel transaction;

  const ConsumerKnowledgePayload({
    required this.walletId,
    required this.consumerId,
    required this.consumer,
    required this.transaction,
  });
}