import '../intelligence/consumption_intelligence_engine.dart';
import 'consumption_interaction.dart';

/// Selects at most one useful structured interaction. It deliberately returns
/// silence for weak evidence and facts which already resolve stock uncertainty.
class ConsumptionInteractionPolicy {
  const ConsumptionInteractionPolicy({this.policyVersion = 1});

  final int policyVersion;

  ConsumptionInteraction? decide(
    ConsumptionIntelligenceResult result, {
    Set<String> handledInteractionIds = const {},
  }) {
    final state = result.state.state;
    if (state == ConsumptionState.paused ||
        state == ConsumptionState.discontinued ||
        state == ConsumptionState.insufficientHistory ||
        state == ConsumptionState.stockConfirmedRemaining) {
      return null;
    }
    ConsumptionInteraction? candidate;
    if (state == ConsumptionState.finishedConfirmed) {
      candidate = _interaction(
        result,
        ConsumptionInteractionType.offerAddToShoppingList,
        priority: 100,
        responses: const [],
        facts: [
          if (result.state.lastHumanFeedback != null)
            result.state.lastHumanFeedback!.id,
        ],
      );
    } else if (state == ConsumptionState.overdueRepurchase) {
      candidate = _interaction(
        result,
        ConsumptionInteractionType.confirmStock,
        priority: 90,
        responses: ConsumptionInteractionResponse.values
            .where(
              (response) =>
                  response !=
                  ConsumptionInteractionResponse.confirmExceptionalPurchase,
            )
            .toList(),
        facts: [
          if (result.state.lastPurchase != null) result.state.lastPurchase!.id,
          ...result.signals
              .where(
                (signal) =>
                    signal.type == ConsumptionSignalType.repurchaseOverdue,
              )
              .expand((signal) => signal.factIds),
        ],
      );
    } else if (_hasPriceOpportunity(result)) {
      candidate = _interaction(
        result,
        ConsumptionInteractionType.acknowledgePriceOpportunity,
        priority: 30,
        responses: const [],
        facts: result.signals
            .where((signal) => _isPriceOpportunity(signal.type))
            .expand((signal) => signal.factIds)
            .toList(),
      );
    } else if (_hasPriceAndQuantityChange(result)) {
      candidate = _interaction(
        result,
        ConsumptionInteractionType.confirmExceptionalPurchase,
        priority: 20,
        responses: const [
          ConsumptionInteractionResponse.confirmExceptionalPurchase,
        ],
        facts: result.signals
            .where(
              (signal) =>
                  signal.type == ConsumptionSignalType.priceAndQuantityChanged,
            )
            .expand((signal) => signal.factIds)
            .toList(),
      );
    }
    return candidate == null || handledInteractionIds.contains(candidate.id)
        ? null
        : candidate;
  }

  bool _hasPriceOpportunity(ConsumptionIntelligenceResult result) =>
      result.signals.any((signal) => _isPriceOpportunity(signal.type));

  bool _isPriceOpportunity(ConsumptionSignalType type) =>
      type == ConsumptionSignalType.priceBelowUsual ||
      type == ConsumptionSignalType.newLowestPrice ||
      type == ConsumptionSignalType.betterPriceAtOtherMerchant;

  bool _hasPriceAndQuantityChange(ConsumptionIntelligenceResult result) =>
      result.signals.any(
        (signal) =>
            signal.type == ConsumptionSignalType.priceAndQuantityChanged,
      );

  ConsumptionInteraction _interaction(
    ConsumptionIntelligenceResult result,
    ConsumptionInteractionType type, {
    required int priority,
    required List<ConsumptionInteractionResponse> responses,
    required List<String> facts,
  }) {
    final uniqueFacts =
        facts.where((fact) => fact.trim().isNotEmpty).toSet().toList()..sort();
    return ConsumptionInteraction(
      id: '${type.name}:${result.productId}:${result.scopeId}:${uniqueFacts.join('|')}',
      type: type,
      productId: result.productId,
      scopeId: result.scopeId,
      priority: priority,
      state: result.state.state,
      evidenceQuality: result.state.evidenceQuality,
      allowedResponses: List.unmodifiable(responses),
      signals: List.unmodifiable(
        result.signals.map((signal) => signal.type).toSet().toList(),
      ),
      triggerFactIds: List.unmodifiable(uniqueFacts),
      policyVersion: policyVersion,
    );
  }
}
