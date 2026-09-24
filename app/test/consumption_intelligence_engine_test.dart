import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/consumption/domain/intelligence/consumption_intelligence_engine.dart';
import 'package:app/features/consumption/domain/models/consumption_event.dart';
import 'package:app/shared/knowledge/products/product_price_observation.dart';
import 'package:app/shared/knowledge/products/product_purchase_metrics.dart';

void main() {
  ProductPurchaseMetrics m(
    List<double> prices, {
    List<double>? quantities,
    List<String?>? merchants,
    int days = 30,
  }) => const ProductPurchaseMetricsCalculator().calculate(
    productId: 'p',
    observations: [
      for (var i = 0; i < prices.length; i++)
        ProductPriceObservation(
          productId: 'p',
          purchaseId: '$i',
          purchasedAt: DateTime.utc(2026, 1, 1).add(Duration(days: i * days)),
          unitPrice: prices[i],
          quantity: quantities?[i] ?? 1,
          merchantId: merchants?[i],
        ),
    ],
  );
  test('preço relevante gera sinal estruturado e é determinístico', () {
    final e = const ConsumptionIntelligenceEngine();
    final a = e.analyze(
      productId: 'p',
      scopeId: 'user:a',
      metrics: m([10, 10, 10, 12]),
      events: [],
      referenceAt: DateTime.utc(2026, 5, 1),
    );
    final b = e.analyze(
      productId: 'p',
      scopeId: 'user:a',
      metrics: m([10, 10, 10, 12]),
      events: [],
      referenceAt: DateTime.utc(2026, 5, 1),
    );
    expect(
      a.signals.map((x) => x.type),
      contains(ConsumptionSignalType.priceAboveUsual),
    );
    expect(a.signals.map((x) => x.type), equals(b.signals.map((x) => x.type)));
  });
  test('diferença pequena e histórico insuficiente ficam silenciosos', () {
    final e = const ConsumptionIntelligenceEngine();
    expect(
      e
          .analyze(
            productId: 'p',
            scopeId: 'user:a',
            metrics: m([10, 10.1]),
            events: [],
            referenceAt: DateTime.utc(2026, 3, 1),
          )
          .signals,
      isEmpty,
    );
  });
  test(
    'ainda tenho, pausa, interrupção e compra externa suprimem interpretação de reposição',
    () {
      final e = const ConsumptionIntelligenceEngine();
      final base = m([10, 10, 10]);
      ConsumptionEvent x(ConsumptionEventType t, {DateTime? until}) =>
          ConsumptionEvent(
            id: t.name,
            productId: 'p',
            scopeId: 'user:a',
            type: t,
            occurredAt: DateTime.utc(2026, 6, 1),
            recordedAt: DateTime.utc(2026, 6, 1),
            pauseUntil: until,
          );
      expect(
        e
            .analyze(
              productId: 'p',
              scopeId: 'user:a',
              metrics: base,
              events: [x(ConsumptionEventType.stillHave)],
              referenceAt: DateTime.utc(2027),
            )
            .state
            .state,
        ConsumptionState.stockConfirmedRemaining,
      );
      expect(
        e
            .analyze(
              productId: 'p',
              scopeId: 'user:a',
              metrics: base,
              events: [x(ConsumptionEventType.discontinued)],
              referenceAt: DateTime.utc(2027),
            )
            .state
            .state,
        ConsumptionState.discontinued,
      );
    },
  );
  test('quantidade só é comparada quando explicitamente comparável', () {
    final e = const ConsumptionIntelligenceEngine();
    expect(
      e
          .analyze(
            productId: 'p',
            scopeId: 'user:a',
            metrics: m([10, 10, 10, 10], quantities: [1, 1, 1, 4]),
            events: [],
            referenceAt: DateTime.utc(2026, 5),
            quantityComparable: false,
          )
          .signals
          .where((x) => x.type.name.startsWith('quantity')),
      isEmpty,
    );
  });

  test(
    'recompra antecipada compara a compra atual apenas ao histórico anterior',
    () {
      final earlyMetrics = const ProductPurchaseMetricsCalculator().calculate(
        productId: 'p',
        observations: [
          for (final day in [0, 30, 60, 70])
            ProductPriceObservation(
              productId: 'p',
              purchaseId: 'early-$day',
              purchasedAt: DateTime.utc(2026, 1, 1).add(Duration(days: day)),
              unitPrice: 10,
              quantity: 1,
            ),
        ],
      );
      final result = const ConsumptionIntelligenceEngine().analyze(
        productId: 'p',
        scopeId: 'user:a',
        metrics: earlyMetrics,
        events: [],
        referenceAt: DateTime.utc(2026, 4),
      );
      expect(
        result.signals.map((signal) => signal.type),
        contains(ConsumptionSignalType.repurchaseEarly),
      );
    },
  );

  test('preço histórico por merchant produz comparação conservadora', () {
    final result = const ConsumptionIntelligenceEngine().analyze(
      productId: 'p',
      scopeId: 'user:a',
      metrics: m(
        [12, 12, 8, 8, 12],
        merchants: ['atual', 'atual', 'outro', 'outro', 'atual'],
      ),
      events: [],
      referenceAt: DateTime.utc(2026, 6),
    );
    expect(
      result.signals.map((signal) => signal.type),
      contains(ConsumptionSignalType.betterPriceAtOtherMerchant),
    );
    final better = result.signals.firstWhere(
      (signal) =>
          signal.type == ConsumptionSignalType.betterPriceAtOtherMerchant,
    );
    expect(better.merchantId, 'outro');
    expect(better.factIds, containsAll(['p_4', 'p_2', 'p_3']));
  });

  test(
    'preço e quantidade na mesma compra formam sinal composto sem causa',
    () {
      final result = const ConsumptionIntelligenceEngine().analyze(
        productId: 'p',
        scopeId: 'user:a',
        metrics: m([10, 10, 10, 15], quantities: [1, 1, 1, 4]),
        events: [],
        referenceAt: DateTime.utc(2026, 6),
        quantityComparable: true,
      );
      expect(
        result.signals.map((signal) => signal.type),
        containsAll([
          ConsumptionSignalType.priceAboveUsual,
          ConsumptionSignalType.quantityAboveUsual,
          ConsumptionSignalType.priceAndQuantityChanged,
        ]),
      );
    },
  );

  test(
    'compra excepcional só sai do baseline quando possui vínculo factual',
    () {
      ConsumptionEvent exceptional({String? purchaseId}) => ConsumptionEvent(
        id: 'exceptional',
        productId: 'p',
        scopeId: 'user:a',
        type: ConsumptionEventType.exceptionalPurchase,
        purchaseId: purchaseId,
        occurredAt: DateTime.utc(2026, 4),
        recordedAt: DateTime.utc(2026, 4),
      );
      final metrics = m([10, 10, 10, 50]);
      final engine = const ConsumptionIntelligenceEngine();
      expect(
        engine
            .analyze(
              productId: 'p',
              scopeId: 'user:a',
              metrics: metrics,
              events: [exceptional(purchaseId: '3')],
              referenceAt: DateTime.utc(2026, 6),
            )
            .metrics
            .history
            .length,
        3,
      );
      expect(
        engine
            .analyze(
              productId: 'p',
              scopeId: 'user:a',
              metrics: metrics,
              events: [exceptional()],
              referenceAt: DateTime.utc(2026, 6),
            )
            .metrics
            .history
            .length,
        4,
      );
    },
  );

  test('feedback de estoque mais recente prevalece por cronologia', () {
    ConsumptionEvent event(ConsumptionEventType type, DateTime at) =>
        ConsumptionEvent(
          id: '${type.name}-${at.day}',
          productId: 'p',
          scopeId: 'user:a',
          type: type,
          occurredAt: at,
          recordedAt: at,
        );
    final result = const ConsumptionIntelligenceEngine().analyze(
      productId: 'p',
      scopeId: 'user:a',
      metrics: m([10, 10, 10]),
      events: [
        event(ConsumptionEventType.stillHave, DateTime.utc(2026, 4, 1)),
        event(ConsumptionEventType.finished, DateTime.utc(2026, 4, 10)),
      ],
      referenceAt: DateTime.utc(2026, 4, 10),
    );
    expect(result.state.state, ConsumptionState.finishedConfirmed);
    expect(result.state.confirmedRemainingQuantity, isNull);
  });

  test('nova compra registrada encerra estado de ciclo acabado anterior', () {
    final finished = ConsumptionEvent(
      id: 'finished-old-cycle',
      productId: 'p',
      scopeId: 'user:a',
      type: ConsumptionEventType.finished,
      occurredAt: DateTime.utc(2026, 3, 15),
      recordedAt: DateTime.utc(2026, 3, 15),
    );
    final result = const ConsumptionIntelligenceEngine().analyze(
      productId: 'p',
      scopeId: 'user:a',
      metrics: m([10, 10, 10, 10]),
      events: [finished],
      referenceAt: DateTime.utc(2026, 4, 10),
    );
    expect(result.state.state, isNot(ConsumptionState.finishedConfirmed));
  });

  test('compra externa reinicia relógio e evita overdue do ciclo anterior', () {
    final external = ConsumptionEvent(
      id: 'external-june',
      productId: 'p',
      scopeId: 'user:a',
      type: ConsumptionEventType.externalPurchase,
      occurredAt: DateTime.utc(2026, 6, 1),
      recordedAt: DateTime.utc(2026, 6, 1),
    );
    final result = const ConsumptionIntelligenceEngine().analyze(
      productId: 'p',
      scopeId: 'user:a',
      metrics: m([10, 10, 10]),
      events: [external],
      referenceAt: DateTime.utc(2026, 6, 10),
    );
    expect(result.state.state, ConsumptionState.withinExpectedRhythm);
    expect(
      result.signals.map((signal) => signal.type),
      isNot(contains(ConsumptionSignalType.repurchaseOverdue)),
    );
  });

  test('relógio volta a sinalizar overdue após compra externa', () {
    final external = ConsumptionEvent(
      id: 'external-june',
      productId: 'p',
      scopeId: 'user:a',
      type: ConsumptionEventType.externalPurchase,
      occurredAt: DateTime.utc(2026, 6, 1),
      recordedAt: DateTime.utc(2026, 6, 1),
    );
    final result = const ConsumptionIntelligenceEngine().analyze(
      productId: 'p',
      scopeId: 'user:a',
      metrics: m([10, 10, 10]),
      events: [external],
      referenceAt: DateTime.utc(2026, 8, 10),
    );
    expect(result.state.state, ConsumptionState.overdueRepurchase);
    expect(
      result.signals.map((signal) => signal.type),
      contains(ConsumptionSignalType.repurchaseOverdue),
    );
  });

  test('feedback de estoque anterior à compra externa não domina novo ciclo', () {
    final still = ConsumptionEvent(
      id: 'still-old-cycle',
      productId: 'p',
      scopeId: 'user:a',
      type: ConsumptionEventType.stillHave,
      occurredAt: DateTime.utc(2026, 5, 20),
      recordedAt: DateTime.utc(2026, 5, 20),
      remainingQuantity: 2,
    );
    final external = ConsumptionEvent(
      id: 'external-new-cycle',
      productId: 'p',
      scopeId: 'user:a',
      type: ConsumptionEventType.externalPurchase,
      occurredAt: DateTime.utc(2026, 6, 1),
      recordedAt: DateTime.utc(2026, 6, 1),
    );
    final result = const ConsumptionIntelligenceEngine().analyze(
      productId: 'p',
      scopeId: 'user:a',
      metrics: m([10, 10, 10]),
      events: [still, external],
      referenceAt: DateTime.utc(2026, 6, 10),
    );
    expect(result.state.state, isNot(ConsumptionState.stockConfirmedRemaining));
    expect(result.state.confirmedRemainingQuantity, isNull);
  });

}
