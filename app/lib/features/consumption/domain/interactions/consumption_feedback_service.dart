import '../models/consumption_event.dart';
import '../repositories/consumption_event_repository.dart';
import 'consumption_interaction.dart';

/// Converts an explicit human response into the existing factual event model.
/// The deterministic ID makes a retried response idempotent at the repository.
class ConsumptionFeedbackService {
  const ConsumptionFeedbackService(this._events);
  final ConsumptionEventRepository _events;

  Future<ConsumptionEvent> record(ConsumptionFeedbackCommand command) async {
    if (!command.interaction.allowedResponses.contains(command.response)) {
      throw ArgumentError('Resposta não permitida para esta interação.');
    }
    final event = ConsumptionEvent(
      id: 'feedback:${command.interaction.id}:${command.response.name}',
      productId: command.interaction.productId,
      scopeId: command.interaction.scopeId,
      type: _type(command.response),
      occurredAt: command.occurredAt,
      recordedAt: command.recordedAt,
      recordedByUserId: command.recordedByUserId,
      remainingQuantity:
          command.response == ConsumptionInteractionResponse.stillHave
          ? command.remainingQuantity
          : null,
      remainingUnit:
          command.response == ConsumptionInteractionResponse.stillHave
          ? command.remainingUnit
          : null,
      pauseUntil: command.response == ConsumptionInteractionResponse.pause
          ? command.pauseUntil
          : null,
      exceptionalReason:
          command.response ==
              ConsumptionInteractionResponse.confirmExceptionalPurchase
          ? command.exceptionalReason
          : null,
      exceptionalReasonNote:
          command.response ==
              ConsumptionInteractionResponse.confirmExceptionalPurchase
          ? command.exceptionalReasonNote
          : null,
      purchaseId: command.purchaseId,
      purchaseItemId: command.purchaseItemId,
      priceObservationId: command.priceObservationId,
    );
    await _events.record(event);
    return event;
  }

  ConsumptionEventType _type(ConsumptionInteractionResponse response) {
    switch (response) {
      case ConsumptionInteractionResponse.stillHave:
        return ConsumptionEventType.stillHave;
      case ConsumptionInteractionResponse.finished:
        return ConsumptionEventType.finished;
      case ConsumptionInteractionResponse.externalPurchase:
        return ConsumptionEventType.externalPurchase;
      case ConsumptionInteractionResponse.discontinued:
        return ConsumptionEventType.discontinued;
      case ConsumptionInteractionResponse.pause:
        return ConsumptionEventType.paused;
      case ConsumptionInteractionResponse.confirmExceptionalPurchase:
        return ConsumptionEventType.exceptionalPurchase;
    }
  }
}
