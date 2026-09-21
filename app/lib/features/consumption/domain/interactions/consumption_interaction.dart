import '../intelligence/consumption_intelligence_engine.dart';
import '../models/consumption_event.dart';

enum ConsumptionInteractionType {
  confirmStock,
  offerAddToShoppingList,
  acknowledgePriceOpportunity,
  confirmExceptionalPurchase,
}

enum ConsumptionInteractionResponse {
  stillHave,
  finished,
  externalPurchase,
  discontinued,
  pause,
  confirmExceptionalPurchase,
}

class ConsumptionInteraction {
  const ConsumptionInteraction({
    required this.id,
    required this.type,
    required this.productId,
    required this.scopeId,
    required this.priority,
    required this.state,
    required this.evidenceQuality,
    required this.allowedResponses,
    required this.triggerFactIds,
    required this.policyVersion,
    this.signals = const [],
  });

  /// Stable deterministic workflow identity, never user-facing text.
  final String id;
  final ConsumptionInteractionType type;
  final String productId;
  final String scopeId;
  final int priority;
  final ConsumptionState state;
  final ConsumptionEvidenceQuality evidenceQuality;
  final List<ConsumptionInteractionResponse> allowedResponses;
  final List<ConsumptionSignalType> signals;
  final List<String> triggerFactIds;
  final int policyVersion;
}

class ConsumptionFeedbackCommand {
  const ConsumptionFeedbackCommand({
    required this.interaction,
    required this.response,
    required this.occurredAt,
    required this.recordedAt,
    this.recordedByUserId,
    this.remainingQuantity,
    this.remainingUnit,
    this.pauseUntil,
    this.exceptionalReason,
    this.exceptionalReasonNote,
    this.purchaseId,
    this.purchaseItemId,
    this.priceObservationId,
  });

  final ConsumptionInteraction interaction;
  final ConsumptionInteractionResponse response;
  final DateTime occurredAt;
  final DateTime recordedAt;
  final String? recordedByUserId;
  final double? remainingQuantity;
  final String? remainingUnit;
  final DateTime? pauseUntil;
  final ExceptionalPurchaseReason? exceptionalReason;
  final String? exceptionalReasonNote;
  final String? purchaseId;
  final String? purchaseItemId;
  final String? priceObservationId;
}
