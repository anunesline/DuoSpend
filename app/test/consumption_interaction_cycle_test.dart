import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/consumption/data/repositories/firestore_consumption_event_repository.dart';
import 'package:app/features/consumption/domain/intelligence/consumption_intelligence_engine.dart';
import 'package:app/features/consumption/domain/interactions/consumption_feedback_service.dart';
import 'package:app/features/consumption/domain/interactions/consumption_interaction.dart';
import 'package:app/features/consumption/domain/interactions/consumption_interaction_policy.dart';
import 'package:app/features/consumption/domain/models/consumption_event.dart';
import 'package:app/shared/knowledge/products/product_price_observation.dart';
import 'package:app/shared/knowledge/products/product_purchase_metrics.dart';

void main() {
  final engine = const ConsumptionIntelligenceEngine();
  final policy = const ConsumptionInteractionPolicy();
  final referenceAt = DateTime.utc(2026, 6, 1);

  ConsumptionIntelligenceResult result(List<ConsumptionEvent> events) =>
      engine.analyze(
        productId: 'detergent',
        scopeId: 'user:aline',
        metrics: const ProductPurchaseMetricsCalculator().calculate(
          productId: 'detergent',
          observations: [
            for (final day in [0, 30, 60])
              ProductPriceObservation(
                productId: 'detergent',
                purchaseId: 'purchase-$day',
                purchasedAt: DateTime.utc(2026, 1, 1).add(Duration(days: day)),
                unitPrice: 10,
                quantity: 1,
              ),
          ],
        ),
        events: events,
        referenceAt: referenceAt,
      );

  test(
    'overdue desconhecido pergunta estoque; ainda tenho resolve o ciclo',
    () async {
      final initial = result([]);
      final interaction = policy.decide(initial)!;
      expect(interaction.type, ConsumptionInteractionType.confirmStock);
      final repository = FirestoreConsumptionEventRepository(
        firestore: FakeFirebaseFirestore(),
      );
      final event = await ConsumptionFeedbackService(repository).record(
        ConsumptionFeedbackCommand(
          interaction: interaction,
          response: ConsumptionInteractionResponse.stillHave,
          remainingQuantity: 4,
          remainingUnit: 'un',
          occurredAt: referenceAt,
          recordedAt: referenceAt,
          recordedByUserId: 'aline',
        ),
      );
      expect(event.type, ConsumptionEventType.stillHave);
      expect(event.remainingQuantity, 4);
      final recalculated = result(
        await repository.getByScopeAndProduct(
          scopeId: 'user:aline',
          productId: 'detergent',
        ),
      );
      expect(
        recalculated.state.state,
        ConsumptionState.stockConfirmedRemaining,
      );
      expect(policy.decide(recalculated), isNull);
    },
  );

  test(
    'acabou habilita ação de lista e feedbacks usam fatos existentes',
    () async {
      final interaction = policy.decide(result([]))!;
      final repository = FirestoreConsumptionEventRepository(
        firestore: FakeFirebaseFirestore(),
      );
      final service = ConsumptionFeedbackService(repository);
      final finished = await service.record(
        ConsumptionFeedbackCommand(
          interaction: interaction,
          response: ConsumptionInteractionResponse.finished,
          occurredAt: referenceAt,
          recordedAt: referenceAt,
        ),
      );
      expect(finished.type, ConsumptionEventType.finished);
      final next = policy.decide(
        result(
          await repository.getByScopeAndProduct(
            scopeId: 'user:aline',
            productId: 'detergent',
          ),
        ),
      )!;
      expect(next.type, ConsumptionInteractionType.offerAddToShoppingList);
    },
  );

  test('respostas estruturadas preservam seus tipos factuais', () async {
    final interaction = policy.decide(result([]))!;
    final repository = FirestoreConsumptionEventRepository(
      firestore: FakeFirebaseFirestore(),
    );
    final service = ConsumptionFeedbackService(repository);
    final expected = {
      ConsumptionInteractionResponse.externalPurchase:
          ConsumptionEventType.externalPurchase,
      ConsumptionInteractionResponse.pause: ConsumptionEventType.paused,
      ConsumptionInteractionResponse.discontinued:
          ConsumptionEventType.discontinued,
    };
    for (final entry in expected.entries) {
      final event = await service.record(
        ConsumptionFeedbackCommand(
          interaction: interaction,
          response: entry.key,
          occurredAt: referenceAt,
          recordedAt: referenceAt,
        ),
      );
      expect(event.type, entry.value);
    }
  });

  test(
    'pausa, interrupção e histórico insuficiente permanecem em silêncio',
    () {
      final base = result([]);
      final paused = ConsumptionEvent(
        id: 'pause',
        productId: 'detergent',
        scopeId: 'user:aline',
        type: ConsumptionEventType.paused,
        occurredAt: referenceAt,
        recordedAt: referenceAt,
      );
      expect(policy.decide(result([paused])), isNull);
      final insufficient = const ConsumptionIntelligenceEngine().analyze(
        productId: 'detergent',
        scopeId: 'user:aline',
        metrics: const ProductPurchaseMetricsCalculator().calculate(
          productId: 'detergent',
          observations: const [],
        ),
        events: [],
        referenceAt: referenceAt,
      );
      expect(policy.decide(insufficient), isNull);
      expect(base.state.state, ConsumptionState.overdueRepurchase);
    },
  );
}
