import 'package:app/features/financial_intelligence/domain/comparison/financial_comparison.dart';
import 'package:app/features/financial_intelligence/domain/facts/financial_facts.dart';
import 'package:app/features/financial_intelligence/domain/signals/financial_signals.dart';
import 'package:flutter_test/flutter_test.dart';

final period = FinancialComparablePeriod(
  start: DateTime(2026, 9, 1),
  end: DateTime(2026, 9, 21),
  walletId: 'w',
  walletScope: FinancialWalletScope.individualWallet,
  completeness: FinancialPeriodCompleteness.partial,
);
final comparisonPeriod = FinancialComparablePeriod(
  start: DateTime(2026, 8, 1),
  end: DateTime(2026, 8, 21),
  walletId: 'w',
  walletScope: FinancialWalletScope.individualWallet,
  completeness: FinancialPeriodCompleteness.partial,
);
const detector = FinancialSignalDetector();
const policy = FinancialSignalPolicy(
  minimumPercentage: .1,
  minimumAbsoluteDifference: 50,
  allowBaseZeroByAbsolute: true,
);

FinancialComparisonValue _comparison(double current, double prior) =>
    FinancialComparisonValue.available(
      current: current,
      comparison: prior,
      percentageDifference: prior == 0 ? null : (current - prior) / prior,
    );

FinancialSignal _comparative({
  FinancialSignalType type = FinancialSignalType.spendingChanged,
  FinancialSignalMetric metric = FinancialSignalMetric.realizedExpense,
  FinancialComparisonValue? comparison,
  FinancialBaseline? baseline,
  String? category,
  String? cardId,
  String wallet = 'w',
}) => detector
    .comparative(
      type: type,
      metric: metric,
      comparison: comparison ?? _comparison(200, 100),
      period: wallet == 'w'
          ? period
          : FinancialComparablePeriod(
              start: period.start,
              end: period.end,
              walletId: wallet,
              walletScope: period.walletScope,
              completeness: period.completeness,
            ),
      comparisonPeriod: wallet == 'w'
          ? comparisonPeriod
          : FinancialComparablePeriod(
              start: comparisonPeriod.start,
              end: comparisonPeriod.end,
              walletId: wallet,
              walletScope: comparisonPeriod.walletScope,
              completeness: comparisonPeriod.completeness,
            ),
      policy: policy,
      baseline: baseline,
      category: category,
      cardId: cardId,
    )
    .single;

void main() {
  test('M1-M5 comparative preserves metric and both periods', () {
    final signal = _comparative();
    expect(signal.sourceMetric, FinancialSignalMetric.realizedExpense);
    expect(signal.period.start, DateTime(2026, 9, 1));
    expect(signal.period.end, DateTime(2026, 9, 21));
    expect(signal.period.completeness, FinancialPeriodCompleteness.partial);
    expect(signal.comparisonPeriod!.start, DateTime(2026, 8, 1));
    expect(signal.comparisonPeriod!.end, DateTime(2026, 8, 21));
    expect(
      signal.comparisonPeriod!.completeness,
      FinancialPeriodCompleteness.partial,
    );
  });

  test('M6-M8 cash flow metrics remain structurally distinguishable', () {
    for (final metric in [
      FinancialSignalMetric.cashInflow,
      FinancialSignalMetric.cashOutflow,
      FinancialSignalMetric.cashNet,
    ]) {
      final signal = _comparative(
        type: FinancialSignalType.cashFlowChanged,
        metric: metric,
      );
      expect(signal.sourceMetric, metric);
    }
  });

  test('M9-M13 type and metric combinations are validated', () {
    expect(
      () => _comparative(
        type: FinancialSignalType.spendingChanged,
        metric: FinancialSignalMetric.realizedIncome,
      ),
      throwsArgumentError,
    );
    expect(
      () => _comparative(
        type: FinancialSignalType.incomeChanged,
        metric: FinancialSignalMetric.cashNet,
      ),
      throwsArgumentError,
    );
    expect(
      () => _comparative(
        type: FinancialSignalType.cashFlowChanged,
        metric: FinancialSignalMetric.realizedExpense,
      ),
      throwsArgumentError,
    );
    expect(
      () => _comparative(
        type: FinancialSignalType.categorySpendingChanged,
        metric: FinancialSignalMetric.realizedExpense,
      ),
      throwsArgumentError,
    );
    expect(
      () => _comparative(
        type: FinancialSignalType.cardSpendingChanged,
        metric: FinancialSignalMetric.categorySpending,
      ),
      throwsArgumentError,
    );
  });

  test('M14 budget preserves period without a synthetic source metric', () {
    final signal = detector
        .budget(period: period, limit: 1000, consumed: 1050, category: 'food')
        .single;
    expect(signal.period.start, period.start);
    expect(signal.period.end, period.end);
    expect(signal.sourceMetric, isNull);
    expect(signal.absoluteDifference, 50);
  });

  test('M15-M16 commitment preserves period and supplied horizon', () {
    final rangeEnd = DateTime(2026, 10, 15);
    final signal = detector
        .commitments(
          period: period,
          inflow: 20,
          outflow: 100,
          count: 1,
          commitmentRangeEnd: rangeEnd,
        )
        .single;
    expect(signal.period.start, period.start);
    expect(signal.commitmentRangeEnd, rangeEnd);
  });

  test('M17-M21 invoice preserves context and classification', () {
    final dueDate = DateTime(2026, 9, 21);
    final referenceAt = DateTime(2026, 9, 20);
    final due = detector
        .invoice(
          period: period,
          invoiceId: 'i',
          dueDate: dueDate,
          isPaid: false,
          referenceAt: referenceAt,
        )
        .single;
    final overdue = detector
        .invoice(
          period: period,
          invoiceId: 'i',
          dueDate: DateTime(2026, 9, 19),
          isPaid: false,
          referenceAt: referenceAt,
        )
        .single;
    expect(due.period.start, period.start);
    expect(due.dueDate, dueDate);
    expect(due.referenceAt, referenceAt);
    expect(overdue.dueDate, DateTime(2026, 9, 19));
    expect(overdue.referenceAt, referenceAt);
    expect(due.type, FinancialSignalType.invoiceDue);
    expect(overdue.type, FinancialSignalType.invoiceOverdue);
    expect(
      detector.invoice(
        period: period,
        invoiceId: 'i',
        dueDate: dueDate,
        isPaid: true,
        referenceAt: referenceAt,
      ),
      isEmpty,
    );
  });

  test('M22-M28 dedupe tokens remain compatible with the prior contract', () {
    expect(
      _comparative().dedupeKey,
      'spendingChanged|expense|w|2026-09-01T00:00:00.000||',
    );
    for (final metric in [
      FinancialSignalMetric.cashInflow,
      FinancialSignalMetric.cashOutflow,
      FinancialSignalMetric.cashNet,
    ]) {
      expect(
        _comparative(
          type: FinancialSignalType.cashFlowChanged,
          metric: metric,
        ).dedupeKey,
        'cashFlowChanged|${switch (metric) {
          FinancialSignalMetric.cashInflow => 'cashInflow',
          FinancialSignalMetric.cashOutflow => 'cashOutflow',
          FinancialSignalMetric.cashNet => 'cashNet',
          _ => throw StateError('unreachable'),
        }}|w|2026-09-01T00:00:00.000||',
      );
    }
    expect(
      detector
          .budget(period: period, limit: 100, consumed: 101, category: 'food')
          .single
          .dedupeKey,
      'budgetExceeded|w|2026-09-01T00:00:00.000|food',
    );
    expect(
      detector
          .commitments(
            period: period,
            inflow: 0,
            outflow: 100,
            count: 1,
            commitmentRangeEnd: DateTime(2026, 10, 1),
          )
          .single
          .dedupeKey,
      'knownCommitment|w|2026-09-01T00:00:00.000',
    );
    expect(
      detector
          .invoice(
            period: period,
            invoiceId: 'i',
            dueDate: DateTime(2026, 9, 21),
            isPaid: false,
            referenceAt: DateTime(2026, 9, 20),
          )
          .single
          .dedupeKey,
      'invoiceDue|w|i',
    );
  });

  test('M29-M30 evidence and numeric baseline remain unchanged', () {
    FinancialBaseline baseline(int count) => FinancialBaseline(
      availability: FinancialComparisonAvailability.available,
      requestedPeriodCount: 4,
      validPeriodCount: count,
      usedPeriods: const [],
      value: 120,
    );
    expect(
      _comparative(baseline: baseline(1)).evidence,
      FinancialSignalEvidence.initial,
    );
    expect(
      _comparative(baseline: baseline(2)).evidence,
      FinancialSignalEvidence.comparable,
    );
    final established = _comparative(baseline: baseline(3));
    expect(established.evidence, FinancialSignalEvidence.established);
    expect(established.baseline, 120);
  });

  test(
    'comparative thresholds, directions, and base-zero policy remain intact',
    () {
      expect(
        _comparative(comparison: _comparison(0, 100)).direction,
        FinancialSignalDirection.decrease,
      );
      expect(
        detector
            .comparative(
              type: FinancialSignalType.spendingChanged,
              metric: FinancialSignalMetric.realizedExpense,
              comparison: _comparison(500, 0),
              period: period,
              comparisonPeriod: comparisonPeriod,
              policy: policy,
            )
            .single
            .percentageDifference,
        isNull,
      );
      expect(
        detector.comparative(
          type: FinancialSignalType.spendingChanged,
          metric: FinancialSignalMetric.realizedExpense,
          comparison: const FinancialComparisonValue.unavailable(
            FinancialComparisonAvailability.unavailable,
          ),
          period: period,
          comparisonPeriod: comparisonPeriod,
          policy: policy,
        ),
        isEmpty,
      );
    },
  );

  test('category and card signals preserve their canonical references', () {
    expect(
      _comparative(
        type: FinancialSignalType.categorySpendingChanged,
        metric: FinancialSignalMetric.categorySpending,
        category: 'food',
      ).category,
      'food',
    );
    final card = _comparative(
      type: FinancialSignalType.cardSpendingChanged,
      metric: FinancialSignalMetric.cardSpending,
      cardId: 'card-a',
    );
    expect(card.cardId, 'card-a');
    expect(
      card.dedupeKey,
      'cardSpendingChanged|cardPurchase|w|2026-09-01T00:00:00.000||card-a',
    );
  });

  test('D1 D2 D3 D4 D5 D9 D10 D11 D12 D13 thresholds and directions', () {
    expect(_comparative().direction, FinancialSignalDirection.increase);
    expect(
      _comparative(
        type: FinancialSignalType.incomeChanged,
        metric: FinancialSignalMetric.realizedIncome,
        comparison: _comparison(50, 100),
      ).direction,
      FinancialSignalDirection.decrease,
    );
    for (final metric in [
      FinancialSignalMetric.cashInflow,
      FinancialSignalMetric.cashOutflow,
      FinancialSignalMetric.cashNet,
    ]) {
      expect(
        detector.comparative(
          type: FinancialSignalType.cashFlowChanged,
          metric: metric,
          comparison: _comparison(20, 10),
          period: period,
          comparisonPeriod: comparisonPeriod,
          policy: policy,
        ),
        isEmpty,
      );
      expect(
        detector.comparative(
          type: FinancialSignalType.cashFlowChanged,
          metric: metric,
          comparison: _comparison(100, 10),
          period: period,
          comparisonPeriod: comparisonPeriod,
          policy: policy,
        ),
        hasLength(1),
      );
    }
    expect(
      detector.comparative(
        type: FinancialSignalType.spendingChanged,
        metric: FinancialSignalMetric.realizedExpense,
        comparison: const FinancialComparisonValue.unavailable(
          FinancialComparisonAvailability.unavailable,
        ),
        period: period,
        comparisonPeriod: comparisonPeriod,
        policy: policy,
      ),
      isEmpty,
    );
  });

  test(
    'D6 D7 D8 D19 D20 unavailable and base-zero policy are deterministic',
    () {
      expect(
        detector.comparative(
          type: FinancialSignalType.spendingChanged,
          metric: FinancialSignalMetric.realizedExpense,
          comparison: const FinancialComparisonValue.unavailable(
            FinancialComparisonAvailability.insufficientHistory,
          ),
          period: period,
          comparisonPeriod: comparisonPeriod,
          policy: policy,
        ),
        isEmpty,
      );
      expect(
        _comparative(comparison: _comparison(500, 0)).direction,
        FinancialSignalDirection.increase,
      );
    },
  );

  test('D14 D15 D16 category unavailable and incompatible are silent', () {
    for (final availability in [
      FinancialComparisonAvailability.unavailable,
      FinancialComparisonAvailability.incompatibleScope,
    ]) {
      expect(
        detector.comparative(
          type: FinancialSignalType.categorySpendingChanged,
          metric: FinancialSignalMetric.categorySpending,
          comparison: FinancialComparisonValue.unavailable(availability),
          period: period,
          comparisonPeriod: comparisonPeriod,
          policy: policy,
          category: 'food',
        ),
        isEmpty,
      );
    }
  });

  test('D17 D18 card historical snapshots are not reconstructible', () {
    for (final metric in [FinancialSignalMetric.cardSpending]) {
      expect(
        detector.comparative(
          type: FinancialSignalType.cardSpendingChanged,
          metric: metric,
          comparison: const FinancialComparisonValue.unavailable(
            FinancialComparisonAvailability.notHistoricallyReconstructible,
          ),
          period: period,
          comparisonPeriod: comparisonPeriod,
          policy: policy,
          cardId: 'card-a',
        ),
        isEmpty,
      );
    }
  });

  test('D21 D22 D23 D24 baseline evidence covers all valid counts', () {
    FinancialBaseline baseline(int count) => FinancialBaseline(
      availability: FinancialComparisonAvailability.available,
      requestedPeriodCount: 4,
      validPeriodCount: count,
      usedPeriods: const [],
      value: 10,
    );
    expect(
      _comparative(baseline: baseline(0)).evidence,
      FinancialSignalEvidence.initial,
    );
    expect(
      _comparative(baseline: baseline(1)).evidence,
      FinancialSignalEvidence.initial,
    );
    expect(
      _comparative(baseline: baseline(2)).evidence,
      FinancialSignalEvidence.comparable,
    );
    expect(
      _comparative(baseline: baseline(3)).evidence,
      FinancialSignalEvidence.established,
    );
    expect(
      _comparative(baseline: baseline(4)).evidence,
      FinancialSignalEvidence.established,
    );
  });

  test('D25 D26 D27 D28 D29 D30 budget and commitments are factual', () {
    expect(
      detector.budget(
        period: period,
        limit: 1000,
        consumed: 1000,
        category: 'food',
      ),
      isEmpty,
    );
    expect(
      detector.budget(
        period: period,
        limit: 1000,
        consumed: 1001,
        category: 'food',
      ),
      hasLength(1),
    );
    expect(
      detector.commitments(
        period: period,
        inflow: 0,
        outflow: 100,
        count: 0,
        commitmentRangeEnd: DateTime(2026, 10, 1),
      ),
      isEmpty,
    );
    expect(
      detector.commitments(
        period: period,
        inflow: 20,
        outflow: 100,
        count: 1,
        commitmentRangeEnd: DateTime(2026, 10, 1),
      ),
      hasLength(1),
    );
  });

  test('D31 commitments are not a comparative signal path', () {
    expect(
      detector.comparative(
        type: FinancialSignalType.spendingChanged,
        metric: FinancialSignalMetric.realizedExpense,
        comparison: const FinancialComparisonValue.unavailable(
          FinancialComparisonAvailability.notHistoricallyReconstructible,
        ),
        period: period,
        comparisonPeriod: comparisonPeriod,
        policy: policy,
      ),
      isEmpty,
    );
  });

  test('D32 D33 D34 D35 D36 D37 D38 D39 D40 invoice silence and identity', () {
    final due = detector
        .invoice(
          period: period,
          invoiceId: 'a',
          dueDate: DateTime(2026, 9, 21),
          isPaid: false,
          referenceAt: DateTime(2026, 9, 20),
        )
        .single;
    final overdue = detector
        .invoice(
          period: period,
          invoiceId: 'a',
          dueDate: DateTime(2026, 9, 19),
          isPaid: false,
          referenceAt: DateTime(2026, 9, 20),
        )
        .single;
    expect(due.type, FinancialSignalType.invoiceDue);
    expect(overdue.type, FinancialSignalType.invoiceOverdue);
    expect(
      detector.invoice(
        period: period,
        invoiceId: 'a',
        dueDate: DateTime(2026, 9, 21),
        isPaid: true,
        referenceAt: DateTime(2026, 9, 20),
      ),
      isEmpty,
    );
    expect(due.dedupeKey, 'invoiceDue|w|a');
  });

  test('D41 D42 decrease thresholds use absolute magnitude', () {
    final threshold = const FinancialSignalPolicy(
      minimumPercentage: .1,
      minimumAbsoluteDifference: 10,
    );
    expect(
      detector
          .comparative(
            type: FinancialSignalType.spendingChanged,
            metric: FinancialSignalMetric.realizedExpense,
            comparison: _comparison(80, 100),
            period: period,
            comparisonPeriod: comparisonPeriod,
            policy: threshold,
          )
          .single
          .direction,
      FinancialSignalDirection.decrease,
    );
    expect(
      detector.comparative(
        type: FinancialSignalType.spendingChanged,
        metric: FinancialSignalMetric.realizedExpense,
        comparison: _comparison(95, 100),
        period: period,
        comparisonPeriod: comparisonPeriod,
        policy: threshold,
      ),
      isEmpty,
    );
  });

  test('D48 base-zero remains policy controlled', () {
    const denied = FinancialSignalPolicy(
      minimumPercentage: .1,
      minimumAbsoluteDifference: 50,
    );
    expect(
      detector.comparative(
        type: FinancialSignalType.spendingChanged,
        metric: FinancialSignalMetric.realizedExpense,
        comparison: _comparison(500, 0),
        period: period,
        comparisonPeriod: comparisonPeriod,
        policy: denied,
      ),
      isEmpty,
    );
  });

  test('D50 D51 D52 D53 D54 dedupe differentiates dimensions', () {
    FinancialSignal category(String wallet, String value) => _comparative(
      type: FinancialSignalType.categorySpendingChanged,
      metric: FinancialSignalMetric.categorySpending,
      category: value,
      wallet: wallet,
    );
    final base = category('w', 'food').dedupeKey;
    expect(category('w', 'home').dedupeKey, isNot(base));
    final otherWallet = category('other', 'food').dedupeKey;
    expect(otherWallet, isNot(base));
    final cardA = _comparative(
      type: FinancialSignalType.cardSpendingChanged,
      metric: FinancialSignalMetric.cardSpending,
      cardId: 'a',
    ).dedupeKey;
    final cardB = _comparative(
      type: FinancialSignalType.cardSpendingChanged,
      metric: FinancialSignalMetric.cardSpending,
      cardId: 'b',
    ).dedupeKey;
    expect(cardA, isNot(cardB));
    final invoiceA = detector
        .invoice(
          period: period,
          invoiceId: 'a',
          dueDate: DateTime(2026, 9, 21),
          isPaid: false,
          referenceAt: DateTime(2026, 9, 20),
        )
        .single
        .dedupeKey;
    final invoiceB = detector
        .invoice(
          period: period,
          invoiceId: 'b',
          dueDate: DateTime(2026, 9, 21),
          isPaid: false,
          referenceAt: DateTime(2026, 9, 20),
        )
        .single
        .dedupeKey;
    expect(invoiceA, isNot(invoiceB));
  });
}
