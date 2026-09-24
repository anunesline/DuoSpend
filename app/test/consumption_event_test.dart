import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/consumption/data/repositories/firestore_consumption_event_repository.dart';
import 'package:app/features/consumption/domain/models/consumption_event.dart';
import 'package:app/features/household_routines/domain/services/household_scope_id.dart';

void main() {
  final occurredAt = DateTime.utc(2026, 9, 1, 9);
  final recordedAt = DateTime.utc(2026, 9, 2, 10);

  ConsumptionEvent event({
    String id = 'event-1',
    String? scopeId = 'household:aline|matheus',
    ConsumptionEventType type = ConsumptionEventType.stillHave,
    double? remainingQuantity,
    String? remainingUnit,
    ExceptionalPurchaseReason? exceptionalReason,
    String? purchaseId,
    String? supersedesEventId,
  }) => ConsumptionEvent(
    id: id,
    productId: 'iogurte-natural',
    scopeId: scopeId,
    type: type,
    occurredAt: occurredAt,
    recordedAt: recordedAt,
    recordedByUserId: 'aline',
    remainingQuantity: remainingQuantity,
    remainingUnit: remainingUnit,
    exceptionalReason: exceptionalReason,
    purchaseId: purchaseId,
    supersedesEventId: supersedesEventId,
  );

  test(
    'household é canônico, independente da ordem, e não colide com solo',
    () {
      expect(
        HouseholdScopeId.shared(const ['matheus', 'aline']),
        HouseholdScopeId.shared(const ['aline', 'matheus']),
      );
      expect(
        HouseholdScopeId.personal('aline'),
        isNot('household:aline|matheus'),
      );
    },
  );

  test('autoria, carteira e cartão não alteram a identidade do scope', () {
    final scope = HouseholdScopeId.shared(const ['aline', 'matheus']);
    final first = event(scopeId: scope);
    final second = ConsumptionEvent(
      id: 'event-2',
      productId: first.productId,
      scopeId: scope,
      type: first.type,
      occurredAt: first.occurredAt,
      recordedAt: first.recordedAt,
      recordedByUserId: 'matheus',
    );
    expect(first.scopeId, second.scopeId);
  });

  test('scope ausente permanece desconhecido e não entra em consulta por scope',
      () async {
    final repository = FirestoreConsumptionEventRepository(
      firestore: FakeFirebaseFirestore(),
    );
    final unknownScope = ConsumptionEvent(
      id: 'unknown-scope',
      productId: 'iogurte-natural',
      type: ConsumptionEventType.stillHave,
      occurredAt: occurredAt,
      recordedAt: recordedAt,
      recordedByUserId: 'aline',
    );
    await repository.record(unknownScope);
    await repository.record(event(id: 'household-scope'));

    expect(unknownScope.hasKnownScope, isFalse);
    expect(
      (await repository.getByScope(scopeId: 'household:aline|matheus'))
          .map((item) => item.id),
      ['household-scope'],
    );
    expect(
      (await repository.getByProduct(productId: 'iogurte-natural'))
          .map((item) => item.id),
      ['household-scope', 'unknown-scope'],
    );
  });

  test('ainda tenho aceita confirmação com e sem quantidade', () {
    expect(event().hasRemainingQuantity, isFalse);
    final quantified = event(remainingQuantity: 4, remainingUnit: 'un');
    expect(quantified.remainingQuantity, 4);
    expect(quantified.remainingUnit, 'un');
  });

  test('tipos factuais permanecem semanticamente distintos', () {
    expect(ConsumptionEventType.finished, isNot(ConsumptionEventType.spoiled));
    expect(ConsumptionEventType.spoiled, isNot(ConsumptionEventType.discarded));
    expect(
      ConsumptionEventType.externalPurchase,
      isNot(ConsumptionEventType.exceptionalPurchase),
    );
    expect(
      ConsumptionEventType.paused,
      isNot(ConsumptionEventType.discontinued),
    );
  });

  test('compra externa não cria uma transação financeira implícita', () {
    final external = event(
      type: ConsumptionEventType.externalPurchase,
      scopeId: null,
    );
    expect(external.purchaseId, isNull);
    expect(external.purchaseItemId, isNull);
    expect(external.priceObservationId, isNull);
  });

  test('pausa temporária e interrupção definitiva são fatos distintos', () {
    final paused = ConsumptionEvent(
      id: 'pause',
      productId: 'iogurte-natural',
      scopeId: 'user:aline',
      type: ConsumptionEventType.paused,
      occurredAt: occurredAt,
      recordedAt: recordedAt,
      pauseUntil: occurredAt.add(const Duration(days: 30)),
    );
    final discontinued = ConsumptionEvent(
      id: 'discontinued',
      productId: 'iogurte-natural',
      scopeId: 'user:aline',
      type: ConsumptionEventType.discontinued,
      occurredAt: occurredAt,
      recordedAt: recordedAt,
    );
    expect(paused.pauseUntil, occurredAt.add(const Duration(days: 30)));
    expect(discontinued.pauseUntil, isNull);
  });

  test('compra excepcional só registra promoção quando ela é explícita', () {
    final withoutReason = event(type: ConsumptionEventType.exceptionalPurchase);
    final confirmedPromotion = event(
      id: 'promotion',
      type: ConsumptionEventType.exceptionalPurchase,
      exceptionalReason: ExceptionalPurchaseReason.promotion,
    );
    expect(withoutReason.exceptionalReason, isNull);
    expect(
      confirmedPromotion.exceptionalReason,
      ExceptionalPurchaseReason.promotion,
    );
  });

  test('serialização preserva proveniência, datas e vínculos opcionais', () {
    final original = event(
      remainingQuantity: 4,
      remainingUnit: 'un',
      purchaseId: 'purchase-1',
    );
    final restored = ConsumptionEvent.fromMap(original.toMap());
    expect(restored.productId, original.productId);
    expect(restored.scopeId, original.scopeId);
    expect(restored.recordedByUserId, 'aline');
    expect(restored.occurredAt, occurredAt);
    expect(restored.recordedAt, recordedAt);
    expect(restored.purchaseId, 'purchase-1');
  });

  test('leitura legada tolera campos factuais opcionais ausentes', () {
    final restored = ConsumptionEvent.fromMap({
      'id': 'legacy',
      'productId': 'arroz',
      'type': 'finished',
      'occurredAt': occurredAt.toIso8601String(),
    });
    expect(restored.scopeId, isNull);
    expect(restored.recordedAt, occurredAt);
    expect(restored.remainingQuantity, isNull);
    expect(restored.isActive, isTrue);
    expect(restored.schemaVersion, 1);
  });

  test('inativação preserva o evento e uma correção pode apontar para ele', () {
    final original = event();
    final inactive = original.invalidate(
      at: recordedAt.add(const Duration(days: 1)),
      byUserId: 'matheus',
      reason: 'correção',
    );
    final correction = event(
      id: 'event-2',
      type: ConsumptionEventType.finished,
      supersedesEventId: original.id,
    );
    expect(inactive.isActive, isFalse);
    expect(inactive.invalidatedByUserId, 'matheus');
    expect(correction.supersedesEventId, original.id);
  });

  test('repositório persiste, ordena, filtra e inativa sem apagar', () async {
    final repository = FirestoreConsumptionEventRepository(
      firestore: FakeFirebaseFirestore(),
    );
    final later = ConsumptionEvent(
      id: 'later',
      productId: 'iogurte-natural',
      scopeId: 'household:aline|matheus',
      type: ConsumptionEventType.externalPurchase,
      occurredAt: occurredAt.add(const Duration(days: 2)),
      recordedAt: recordedAt,
    );
    await repository.record(later);
    await repository.record(event());
    await repository.record(event());

    final beforeInvalidation = await repository.getByScopeAndProduct(
      scopeId: 'household:aline|matheus',
      productId: 'iogurte-natural',
    );
    expect(beforeInvalidation.map((item) => item.id), ['event-1', 'later']);

    await repository.invalidate(
      eventId: 'event-1',
      invalidatedAt: recordedAt,
      invalidatedByUserId: 'aline',
    );
    expect((await repository.getById('event-1'))!.isActive, isFalse);
    expect(
      (await repository.getByProduct(
        productId: 'iogurte-natural',
      )).map((item) => item.id),
      ['later'],
    );
    expect(
      (await repository.getByProduct(
        productId: 'iogurte-natural',
        includeInactive: true,
      )).map((item) => item.id),
      ['event-1', 'later'],
    );
  });
}
