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
void main() {
  test(
    'D1 D2 D3 D4 D5 D9 D10 D11 D12 D13 comparative thresholds and directions',
    () {
      expect(
        detector
            .comparative(
              type: FinancialSignalType.spendingChanged,
              metric: 'expense',
              comparison: _comparison(180, 100),
              period: period,
              policy: policy,
            )
            .single
            .direction,
        FinancialSignalDirection.increase,
      );
      expect(
        detector
            .comparative(
              type: FinancialSignalType.incomeChanged,
              metric: 'income',
              comparison: _comparison(50, 100),
              period: period,
              policy: policy,
            )
            .single
            .direction,
        FinancialSignalDirection.decrease,
      );
      expect(
        detector.comparative(
          type: FinancialSignalType.cashFlowChanged,
          metric: 'cashInflow',
          comparison: _comparison(20, 10),
          period: period,
          policy: policy,
        ),
        isEmpty,
      );
      expect(
        detector.comparative(
          type: FinancialSignalType.cashFlowChanged,
          metric: 'cashOutflow',
          comparison: _comparison(160, 150),
          period: period,
          policy: policy,
        ),
        isEmpty,
      );
      expect(
        detector.comparative(
          type: FinancialSignalType.cashFlowChanged,
          metric: 'cashNet',
          comparison: _comparison(100, 100),
          period: period,
          policy: policy,
        ),
        isEmpty,
      );
    },
  );
  test('D6 D7 D8 D19 D20 silence and base zero policy', () {
    expect(
      detector.comparative(
        type: FinancialSignalType.spendingChanged,
        metric: 'x',
        comparison: const FinancialComparisonValue.unavailable(
          FinancialComparisonAvailability.unavailable,
        ),
        period: period,
        policy: policy,
      ),
      isEmpty,
    );
    expect(
      detector.comparative(
        type: FinancialSignalType.spendingChanged,
        metric: 'x',
        comparison: _comparison(500, 0),
        period: period,
        policy: policy,
      ),
      isNotEmpty,
    );
    expect(
      detector
          .comparative(
            type: FinancialSignalType.spendingChanged,
            metric: 'x',
            comparison: _comparison(0, 500),
            period: period,
            policy: policy,
          )
          .single
          .direction,
      FinancialSignalDirection.decrease,
    );
  });
  test('D21 D22 D23 D24 evidence uses baseline counts only', () {
    FinancialBaseline base(int count) => FinancialBaseline(
      availability: FinancialComparisonAvailability.available,
      requestedPeriodCount: 3,
      validPeriodCount: count,
      usedPeriods: const [],
      value: 10,
    );
    expect(
      detector
          .comparative(
            type: FinancialSignalType.spendingChanged,
            metric: 'x',
            comparison: _comparison(200, 100),
            period: period,
            policy: policy,
            baseline: base(1),
          )
          .single
          .evidence,
      FinancialSignalEvidence.initial,
    );
    expect(
      detector
          .comparative(
            type: FinancialSignalType.spendingChanged,
            metric: 'x',
            comparison: _comparison(200, 100),
            period: period,
            policy: policy,
            baseline: base(2),
          )
          .single
          .evidence,
      FinancialSignalEvidence.comparable,
    );
    expect(
      detector
          .comparative(
            type: FinancialSignalType.spendingChanged,
            metric: 'x',
            comparison: _comparison(200, 100),
            period: period,
            policy: policy,
            baseline: base(3),
          )
          .single
          .evidence,
      FinancialSignalEvidence.established,
    );
  });
  test('D25 D26 D27 D28 D29 D30 budget and commitments are factual', () {
    expect(
      detector
          .budget(period: period, limit: 1000, consumed: 1050, category: 'food')
          .single
          .absoluteDifference,
      50,
    );
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
      detector.commitments(period: period, inflow: 20, outflow: 100, count: 1),
      isNotEmpty,
    );
    expect(
      detector.commitments(period: period, inflow: 0, outflow: 0, count: 0),
      isEmpty,
    );
  });
  test('D32 D33 D34 D35 D36 D37 D38 D39 D40 invoice dedupe and silence', () {
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
          .direction,
      FinancialSignalDirection.due,
    );
    expect(
      detector
          .invoice(
            period: period,
            invoiceId: 'i',
            dueDate: DateTime(2026, 9, 19),
            isPaid: false,
            referenceAt: DateTime(2026, 9, 20),
          )
          .single
          .direction,
      FinancialSignalDirection.overdue,
    );
    expect(
      detector.invoice(
        period: period,
        invoiceId: 'i',
        dueDate: DateTime(2026, 9, 19),
        isPaid: true,
        referenceAt: DateTime(2026, 9, 20),
      ),
      isEmpty,
    );
    final a = detector
        .comparative(
          type: FinancialSignalType.cardSpendingChanged,
          metric: 'card',
          comparison: _comparison(200, 100),
          period: period,
          policy: policy,
          cardId: 'a',
        )
        .single;
    final b = detector
        .comparative(
          type: FinancialSignalType.cardSpendingChanged,
          metric: 'card',
          comparison: _comparison(200, 100),
          period: period,
          policy: policy,
          cardId: 'a',
        )
        .single;
    expect(a.dedupeKey, b.dedupeKey);
    expect(
      a.dedupeKey,
      isNot(
        detector
            .comparative(
              type: FinancialSignalType.categorySpendingChanged,
              metric: 'card',
              comparison: _comparison(200, 100),
              period: period,
              policy: policy,
              category: 'food',
            )
            .single
            .dedupeKey,
      ),
    );
  });

  test(
    'D14 D15 D16 category comparison preserves only one canonical category',
    () {
      expect(
        detector
            .comparative(
              type: FinancialSignalType.categorySpendingChanged,
              metric: 'category:food',
              comparison: _comparison(200, 100),
              period: period,
              policy: policy,
              category: 'food',
            )
            .single
            .category,
        'food',
      );
      expect(
        detector.comparative(
          type: FinancialSignalType.categorySpendingChanged,
          metric: 'category:food',
          comparison: const FinancialComparisonValue.unavailable(
            FinancialComparisonAvailability.unavailable,
          ),
          period: period,
          policy: policy,
          category: 'food',
        ),
        isEmpty,
      );
      expect(
        detector.comparative(
          type: FinancialSignalType.categorySpendingChanged,
          metric: 'category:food-vs-home',
          comparison: const FinancialComparisonValue.unavailable(
            FinancialComparisonAvailability.unavailable,
          ),
          period: period,
          policy: policy,
          category: 'food',
        ),
        isEmpty,
      );
    },
  );
  test(
    'D17 D18 card spending accepts flow comparison but historical snapshots are unavailable',
    () {
      expect(
        detector
            .comparative(
              type: FinancialSignalType.cardSpendingChanged,
              metric: 'cardPurchase',
              comparison: _comparison(200, 100),
              period: period,
              policy: policy,
              cardId: 'card-a',
            )
            .single
            .cardId,
        'card-a',
      );
      for (final snapshot in ['usedLimit', 'availableLimit', 'creditLimit']) {
        expect(
          detector.comparative(
            type: FinancialSignalType.cardSpendingChanged,
            metric: snapshot,
            comparison: const FinancialComparisonValue.unavailable(
              FinancialComparisonAvailability.notHistoricallyReconstructible,
            ),
            period: period,
            policy: policy,
          ),
          isEmpty,
        );
      }
    },
  );
  test('D31 commitments are current state only', () {
    expect(
      detector
          .commitments(period: period, inflow: 10, outflow: 50, count: 1)
          .single
          .direction,
      FinancialSignalDirection.informational,
    );
    expect(
      detector.comparative(
        type: FinancialSignalType.spendingChanged,
        metric: 'knownCommitments',
        comparison: const FinancialComparisonValue.unavailable(
          FinancialComparisonAvailability.notHistoricallyReconstructible,
        ),
        period: period,
        policy: policy,
      ),
      isEmpty,
    );
  });
  test('D41 D42 decreases use absolute magnitude thresholds', () {
    final threshold = const FinancialSignalPolicy(
      minimumPercentage: .1,
      minimumAbsoluteDifference: 10,
    );
    expect(
      detector
          .comparative(
            type: FinancialSignalType.spendingChanged,
            metric: 'expense',
            comparison: _comparison(80, 100),
            period: period,
            policy: threshold,
          )
          .single
          .direction,
      FinancialSignalDirection.decrease,
    );
    expect(
      detector.comparative(
        type: FinancialSignalType.spendingChanged,
        metric: 'expense',
        comparison: _comparison(95, 100),
        period: period,
        policy: threshold,
      ),
      isEmpty,
    );
  });
  test('D43 D44 D45 D46 D47 evidence has factual baseline levels', () {
    FinancialBaseline baseline(int count) => FinancialBaseline(
      availability: FinancialComparisonAvailability.available,
      requestedPeriodCount: 4,
      validPeriodCount: count,
      usedPeriods: const [],
      value: 1,
    );
    FinancialSignalEvidence evidence(int count) => detector
        .comparative(
          type: FinancialSignalType.spendingChanged,
          metric: 'e',
          comparison: _comparison(200, 100),
          period: period,
          policy: policy,
          baseline: baseline(count),
        )
        .single
        .evidence;
    expect(evidence(0), FinancialSignalEvidence.initial);
    expect(evidence(1), FinancialSignalEvidence.initial);
    expect(evidence(2), FinancialSignalEvidence.comparable);
    expect(evidence(3), FinancialSignalEvidence.established);
    expect(evidence(4), FinancialSignalEvidence.established);
  });
  test('D48 D49 base zero is policy controlled', () {
    const denied = FinancialSignalPolicy(
      minimumPercentage: .1,
      minimumAbsoluteDifference: 50,
    );
    expect(
      detector.comparative(
        type: FinancialSignalType.spendingChanged,
        metric: 'zero',
        comparison: _comparison(500, 0),
        period: period,
        policy: denied,
      ),
      isEmpty,
    );
    final signal = detector
        .comparative(
          type: FinancialSignalType.spendingChanged,
          metric: 'zero',
          comparison: _comparison(500, 0),
          period: period,
          policy: policy,
        )
        .single;
    expect(signal.percentageDifference, isNull);
    expect(signal.direction, FinancialSignalDirection.increase);
  });
  test('D50 D51 D52 D53 D54 dedupe differentiates evidence dimensions', () {
    FinancialSignal signal({
      String wallet = 'w',
      String? category,
      String? card,
    }) => detector
        .comparative(
          type: card == null
              ? FinancialSignalType.categorySpendingChanged
              : FinancialSignalType.cardSpendingChanged,
          metric: 'm',
          comparison: _comparison(200, 100),
          period: FinancialComparablePeriod(
            start: period.start,
            end: period.end,
            walletId: wallet,
            walletScope: period.walletScope,
            completeness: period.completeness,
          ),
          policy: policy,
          category: category,
          cardId: card,
        )
        .single;
    expect(
      signal(category: 'food').dedupeKey,
      signal(category: 'food').dedupeKey,
    );
    expect(
      signal(category: 'food').dedupeKey,
      isNot(signal(wallet: 'other', category: 'food').dedupeKey),
    );
    expect(
      signal(category: 'food').dedupeKey,
      isNot(signal(category: 'home').dedupeKey),
    );
    expect(signal(card: 'a').dedupeKey, isNot(signal(card: 'b').dedupeKey));
    expect(
      detector
          .invoice(
            period: period,
            invoiceId: 'a',
            dueDate: DateTime(2026, 9, 21),
            isPaid: false,
            referenceAt: DateTime(2026, 9, 20),
          )
          .single
          .dedupeKey,
      isNot(
        detector
            .invoice(
              period: period,
              invoiceId: 'b',
              dueDate: DateTime(2026, 9, 21),
              isPaid: false,
              referenceAt: DateTime(2026, 9, 20),
            )
            .single
            .dedupeKey,
      ),
    );
  });
}
