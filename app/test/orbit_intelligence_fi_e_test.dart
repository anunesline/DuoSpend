import 'package:app/features/consumption/domain/intelligence/consumption_intelligence_engine.dart';
import 'package:app/features/consumption/domain/interactions/consumption_interaction.dart';
import 'package:app/features/consumption/domain/models/consumption_event.dart';
import 'package:app/features/consumption/domain/repositories/consumption_event_repository.dart';
import 'package:app/features/consumption/presentation/controllers/orbit_intelligence_controller.dart';
import 'package:app/features/consumption/presentation/pages/orbit_intelligence_page.dart';
import 'package:app/features/financial_intelligence/domain/comparison/financial_comparison.dart';
import 'package:app/features/financial_intelligence/domain/facts/financial_facts.dart';
import 'package:app/features/financial_intelligence/domain/signals/financial_signals.dart';
import 'package:app/features/orbit_intelligence/domain/orbit_intelligence_item.dart';
import 'package:app/shared/knowledge/products/product_purchase_metrics.dart';
import 'package:app/shared/knowledge/products/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _period = FinancialComparablePeriod(
  start: DateTime(2026, 9, 1),
  end: DateTime(2026, 9, 21),
  walletId: 'wallet',
  walletScope: FinancialWalletScope.individualWallet,
  completeness: FinancialPeriodCompleteness.partial,
);

FinancialSignal _signal(FinancialSignalType type) {
  if (type == FinancialSignalType.budgetExceeded) {
    return FinancialSignal(
      type: FinancialSignalType.budgetExceeded,
      direction: FinancialSignalDirection.exceeded,
      reason: FinancialSignalReason.budgetExceeded,
      evidence: FinancialSignalEvidence.currentState,
      dedupeKey: 'budgetExceeded|wallet|2026-09-01T00:00:00.000|food',
      walletId: 'wallet',
      walletScope: FinancialWalletScope.individualWallet,
      period: FinancialSignalPeriod(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 21),
        completeness: FinancialPeriodCompleteness.partial,
      ),
      currentValue: 120,
      comparisonValue: 100,
      absoluteDifference: 20,
      category: 'food',
    );
  }
  return FinancialSignal(
    type: type,
    direction: type == FinancialSignalType.invoiceOverdue
        ? FinancialSignalDirection.overdue
        : FinancialSignalDirection.increase,
    reason: type == FinancialSignalType.invoiceOverdue
        ? FinancialSignalReason.invoiceOverdue
        : FinancialSignalReason.comparisonThresholdMet,
    evidence: FinancialSignalEvidence.comparable,
    dedupeKey: '${type.name}|metric|wallet|period',
    walletId: 'wallet',
    walletScope: FinancialWalletScope.individualWallet,
    period: FinancialSignalPeriod.fromComparable(_period),
    comparisonPeriod: FinancialSignalPeriod.fromComparable(_period),
    sourceMetric: switch (type) {
      FinancialSignalType.spendingChanged =>
        FinancialSignalMetric.realizedExpense,
      FinancialSignalType.incomeChanged => FinancialSignalMetric.realizedIncome,
      FinancialSignalType.cashFlowChanged => FinancialSignalMetric.cashNet,
      FinancialSignalType.categorySpendingChanged =>
        FinancialSignalMetric.categorySpending,
      FinancialSignalType.cardSpendingChanged =>
        FinancialSignalMetric.cardSpending,
      _ => null,
    },
    category: type == FinancialSignalType.categorySpendingChanged
        ? 'food'
        : null,
    cardId: type == FinancialSignalType.cardSpendingChanged ? 'card' : null,
    invoiceId:
        type == FinancialSignalType.invoiceDue ||
            type == FinancialSignalType.invoiceOverdue
        ? 'invoice'
        : null,
    dueDate:
        type == FinancialSignalType.invoiceDue ||
            type == FinancialSignalType.invoiceOverdue
        ? DateTime(2026, 9, 21)
        : null,
    referenceAt:
        type == FinancialSignalType.invoiceDue ||
            type == FinancialSignalType.invoiceOverdue
        ? DateTime(2026, 9, 20)
        : null,
    currentValue: 120,
    comparisonValue: 100,
    absoluteDifference: 20,
    percentageDifference: .2,
    baseline: 100,
  );
}

OrbitIntelligenceEntry _entry({
  ConsumptionInteractionType? interactionType,
  bool learned = false,
}) {
  final interaction = interactionType == null
      ? null
      : ConsumptionInteraction(
          id: 'interaction:${interactionType.name}',
          type: interactionType,
          productId: 'product',
          scopeId: 'scope',
          priority:
              interactionType ==
                  ConsumptionInteractionType.offerAddToShoppingList
              ? 100
              : 20,
          state: ConsumptionState.withinExpectedRhythm,
          evidenceQuality: ConsumptionEvidenceQuality.strong,
          allowedResponses: const [],
          triggerFactIds: const [],
          policyVersion: 1,
        );
  return OrbitIntelligenceEntry(
    productId: 'product',
    productName: 'Produto',
    result: ConsumptionIntelligenceResult(
      productId: 'product',
      scopeId: 'scope',
      metrics: ProductPurchaseMetrics(
        productId: 'product',
        history: const [],
        averageUnitPrice: null,
        minimumUnitPrice: null,
        maximumUnitPrice: null,
        absolutePriceVariation: null,
        percentagePriceVariation: null,
        totalQuantity: 0,
        totalSpent: 0,
        purchaseFrequencyPer30Days: null,
        averagePurchaseInterval: null,
        spendingByMerchant: const [],
        spendingByCategory: const [],
        probableRecurrence: learned
            ? ProductProbableRecurrence(
                averageInterval: const Duration(days: 30),
                nextExpectedPurchaseAt: DateTime(2026, 10, 1),
                observationCount: 3,
              )
            : null,
      ),
      state: const ConsumptionDerivedState(
        state: ConsumptionState.withinExpectedRhythm,
        evidenceQuality: ConsumptionEvidenceQuality.strong,
      ),
      signals: const [],
      activeEvents: const [],
      policyVersion: 1,
    ),
    interaction: interaction,
  );
}

void main() {
  test('E1-E6 common item has domain, kind, scope, action and no severity', () {
    final item = const FinancialCentralAdapter().adapt([
      _signal(FinancialSignalType.spendingChanged),
    ]).single;
    expect(item.domain, OrbitIntelligenceDomain.financial);
    expect(item.kind, OrbitIntelligenceKind.insight);
    expect(item.scope.id, 'wallet');
    expect(item.action, isNull);
    expect(item.dedupeKey, startsWith('financial:'));
  });

  test(
    'E7-E12 consumption adapter preserves action, insight, learned and identity',
    () {
      final adapter = const ConsumptionCentralAdapter();
      final action = adapter.adapt([
        _entry(interactionType: ConsumptionInteractionType.confirmStock),
      ]).single;
      final insight = adapter.adapt([
        _entry(
          interactionType:
              ConsumptionInteractionType.acknowledgePriceOpportunity,
        ),
      ]).single;
      final learned = adapter.adapt([_entry(learned: true)]).single;
      expect(action.kind, OrbitIntelligenceKind.action);
      expect(action.action?.payload, isA<ConsumptionInteraction>());
      expect(insight.kind, OrbitIntelligenceKind.insight);
      expect(learned.kind, OrbitIntelligenceKind.learned);
      expect(action.dedupeKey, startsWith('consumption:'));
    },
  );

  test(
    'E13-E21 financial mapping is insight-only and preserves references',
    () {
      final adapter = const FinancialCentralAdapter();
      for (final type in FinancialSignalType.values) {
        final item = adapter.adapt([_signal(type)]).single;
        expect(item.kind, OrbitIntelligenceKind.insight);
        expect(item.action, isNull);
        expect(item.source, isA<FinancialSignal>());
      }
      expect(
        adapter
            .adapt([_signal(FinancialSignalType.categorySpendingChanged)])
            .single
            .scope
            .walletScope,
        FinancialWalletScope.individualWallet,
      );
    },
  );

  test('E22-E29 adapter uses structured signal and leaves it unchanged', () {
    final signal = _signal(FinancialSignalType.cashFlowChanged);
    final item = const FinancialCentralAdapter().adapt([signal]).single;
    expect(
      (item.source as FinancialSignal).sourceMetric,
      FinancialSignalMetric.cashNet,
    );
    expect((item.source as FinancialSignal).period.start, _period.start);
    expect((item.source as FinancialSignal).comparisonPeriod, isNotNull);
    expect((item.source as FinancialSignal).dedupeKey, signal.dedupeKey);
  });

  test(
    'E30-E40 orchestrator coexists, namespaces, dedupes and orders deterministically',
    () {
      final consumption = const ConsumptionCentralAdapter().adapt([
        _entry(
          interactionType: ConsumptionInteractionType.offerAddToShoppingList,
        ),
      ]);
      final financial = const FinancialCentralAdapter().adapt([
        _signal(FinancialSignalType.invoiceOverdue),
        _signal(FinancialSignalType.invoiceOverdue),
      ]);
      final orchestrator = const OrbitIntelligenceOrchestrator();
      final first = orchestrator.build(
        consumption: consumption,
        financial: financial,
      );
      final second = orchestrator.build(
        consumption: consumption,
        financial: financial,
      );
      expect(first, hasLength(2));
      expect(
        first.map((item) => item.domain),
        containsAll([
          OrbitIntelligenceDomain.consumption,
          OrbitIntelligenceDomain.financial,
        ]),
      );
      expect(
        first.map((item) => item.id).toList(),
        second.map((item) => item.id).toList(),
      );
      expect(first.map((item) => item.dedupeKey).toSet(), hasLength(2));
    },
  );

  testWidgets(
    'E41-E50 financial-only feed replaces insight placeholder and preserves others',
    (tester) async {
      final controller = OrbitIntelligenceController(
        userId: 'user',
        scopeId: 'scope',
        products: ProductRepository(),
        events: _Events(),
        financialSignals: [_signal(FinancialSignalType.budgetExceeded)],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: OrbitIntelligencePage(
            userId: 'user',
            scopeId: 'scope',
            products: ProductRepository(),
            controller: controller,
          ),
        ),
      );
      expect(find.text('Orçamento excedido'), findsOneWidget);
      expect(find.text('Nada por enquanto'), findsOneWidget);
      expect(find.text('Construindo sua memória de consumo'), findsOneWidget);
    },
  );
}

class _Events implements ConsumptionEventRepository {
  @override
  Future<void> record(ConsumptionEvent event) async {}

  @override
  Future<ConsumptionEvent?> getById(String eventId) async => null;

  @override
  Future<List<ConsumptionEvent>> getByScope({
    required String scopeId,
    DateTime? from,
    DateTime? until,
    bool includeInactive = false,
  }) async => [];

  @override
  Future<List<ConsumptionEvent>> getByProduct({
    required String productId,
    DateTime? from,
    DateTime? until,
    bool includeInactive = false,
  }) async => [];

  @override
  Future<List<ConsumptionEvent>> getByScopeAndProduct({
    required String scopeId,
    required String productId,
    DateTime? from,
    DateTime? until,
    bool includeInactive = false,
  }) async => [];

  @override
  Future<void> invalidate({
    required String eventId,
    required DateTime invalidatedAt,
    String? invalidatedByUserId,
    String? reason,
  }) async {}
}
