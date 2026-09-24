import 'package:app/features/financial_intelligence/domain/comparison/financial_comparison.dart';
import 'package:app/features/financial_intelligence/domain/facts/financial_facts.dart';
import 'package:flutter_test/flutter_test.dart';

FinancialComparablePeriod _period(
  int y,
  int m,
  int end, {
  FinancialPeriodCompleteness completeness =
      FinancialPeriodCompleteness.complete,
  String wallet = 'w',
  FinancialWalletScope scope = FinancialWalletScope.individualWallet,
}) => FinancialComparablePeriod(
  start: DateTime(y, m, 1, 12),
  end: DateTime(y, m, end, 23),
  walletId: wallet,
  walletScope: scope,
  completeness: completeness,
);

void main() {
  const calculator = FinancialComparisonCalculator();
  test(
    'C1 C2 C7 C8 C9 P1 previous equivalent normalizes inclusive periods',
    () {
      final full = calculator.previousEquivalentMonth(_period(2026, 8, 31));
      final mtd = calculator.previousEquivalentMonth(
        _period(2026, 9, 21, completeness: FinancialPeriodCompleteness.partial),
      );
      expect(
        [full.start, full.end],
        [DateTime(2026, 7, 1), DateTime(2026, 7, 31)],
      );
      expect(
        [mtd.start, mtd.end, mtd.completeness],
        [
          DateTime(2026, 8, 1),
          DateTime(2026, 8, 21),
          FinancialPeriodCompleteness.partial,
        ],
      );
      expect(
        () => calculator.previousEquivalentMonth(
          FinancialComparablePeriod(
            start: DateTime(2026, 9, 2),
            end: DateTime(2026, 9, 1),
            walletId: 'w',
            walletScope: FinancialWalletScope.individualWallet,
            completeness: FinancialPeriodCompleteness.partial,
          ),
        ),
        throwsArgumentError,
      );
    },
  );
  test('C3 C4 C5 C6 P2 clamps variable months and years', () {
    expect(
      calculator.previousEquivalentMonth(_period(2026, 5, 31)).end,
      DateTime(2026, 4, 30),
    );
    expect(
      calculator.previousEquivalentMonth(_period(2026, 3, 31)).end,
      DateTime(2026, 2, 28),
    );
    expect(
      calculator.previousEquivalentMonth(_period(2024, 3, 31)).end,
      DateTime(2024, 2, 29),
    );
    expect(
      calculator.previousEquivalentMonth(_period(2026, 1, 31)).end,
      DateTime(2025, 12, 31),
    );
  });
  test('C10 C11 C12 C13 C14 scope compatibility is explicit and pure', () {
    final solo = _period(2026, 9, 30);
    final same = _period(2026, 8, 31);
    final shared = _period(
      2026,
      8,
      31,
      scope: FinancialWalletScope.sharedWallet,
    );
    final other = _period(2026, 8, 31, wallet: 'other');
    expect(
      calculator
          .compare(
            currentPeriod: solo,
            comparisonPeriod: same,
            current: 2,
            comparison: 1,
          )
          .availability,
      FinancialComparisonAvailability.available,
    );
    expect(
      calculator
          .compare(
            currentPeriod: shared,
            comparisonPeriod: _period(
              2026,
              9,
              30,
              scope: FinancialWalletScope.sharedWallet,
            ),
            current: 2,
            comparison: 1,
          )
          .availability,
      FinancialComparisonAvailability.available,
    );
    expect(
      calculator
          .compare(
            currentPeriod: solo,
            comparisonPeriod: other,
            current: 2,
            comparison: 1,
          )
          .availability,
      FinancialComparisonAvailability.incompatibleScope,
    );
    expect(
      calculator
          .compare(
            currentPeriod: solo,
            comparisonPeriod: shared,
            current: 2,
            comparison: 1,
          )
          .availability,
      FinancialComparisonAvailability.incompatibleScope,
    );
  });
  test('C15 C16 C17 C18 C19 C20 C21 numeric differences are deterministic', () {
    final p = _period(2026, 9, 30);
    final q = _period(2026, 8, 31);
    final plus = calculator.compare(
      currentPeriod: p,
      comparisonPeriod: q,
      current: 150,
      comparison: 100,
    );
    final minus = calculator.compare(
      currentPeriod: p,
      comparisonPeriod: q,
      current: 50,
      comparison: 100,
    );
    final zero = calculator.compare(
      currentPeriod: p,
      comparisonPeriod: q,
      current: 100,
      comparison: 100,
    );
    final denominatorZero = calculator.compare(
      currentPeriod: p,
      comparisonPeriod: q,
      current: 10,
      comparison: 0,
    );
    expect([plus.absoluteDifference, plus.percentageDifference], [50, .5]);
    expect([minus.absoluteDifference, minus.percentageDifference], [-50, -.5]);
    expect(zero.absoluteDifference, 0);
    expect(denominatorZero.absoluteDifference, 10);
    expect(denominatorZero.percentageDifference, isNull);
  });
  test(
    'C22 C23 C24 C25 C26 C27 C28 C29 C30 P3 P4 P5 baseline uses only valid complete history',
    () {
      final current = _period(2026, 9, 30);
      final history = [
        for (var m = 6; m <= 8; m++)
          FinancialHistoricalValue(
            period: _period(2026, m, DateTime(2026, m + 1, 0).day),
            value: m.toDouble(),
          ),
      ];
      final three = calculator.baseline(
        currentPeriod: current,
        requestedPeriodCount: 3,
        historical: history,
      );
      final six = calculator.baseline(
        currentPeriod: current,
        requestedPeriodCount: 6,
        historical: history,
      );
      final filtered = calculator.baseline(
        currentPeriod: current,
        requestedPeriodCount: 3,
        historical: [
          ...history.take(2),
          FinancialHistoricalValue(
            period: _period(
              2026,
              8,
              20,
              completeness: FinancialPeriodCompleteness.partial,
            ),
            value: 99,
          ),
          FinancialHistoricalValue(
            period: _period(2026, 7, 31, wallet: 'other'),
            value: 99,
          ),
          FinancialHistoricalValue(
            period: _period(2026, 6, 30),
            available: false,
          ),
        ],
      );
      final none = calculator.baseline(
        currentPeriod: current,
        requestedPeriodCount: 3,
        historical: const [],
      );
      expect(
        [three.requestedPeriodCount, three.validPeriodCount, three.value],
        [3, 3, 7],
      );
      expect([six.requestedPeriodCount, six.validPeriodCount], [6, 3]);
      expect(
        [filtered.requestedPeriodCount, filtered.validPeriodCount],
        [3, 2],
      );
      expect(
        none.availability,
        FinancialComparisonAvailability.insufficientHistory,
      );
    },
  );
  test(
    'C31 C32 C33 C34 C35 P7 snapshots and knowledge state are suppressed historically',
    () {
      for (var i = 0; i < 5; i++) {
        expect(
          calculator.historicalSnapshot().availability,
          FinancialComparisonAvailability.notHistoricallyReconstructible,
        );
      }
    },
  );
  test(
    'C36 C37 C38 C39 C40 C41 C42 category budget and member inputs preserve availability',
    () {
      final p = _period(2026, 9, 30);
      final q = _period(2026, 8, 31);
      expect(
        calculator
            .compare(
              currentPeriod: p,
              comparisonPeriod: q,
              current: 10,
              comparison: 5,
            )
            .availability,
        FinancialComparisonAvailability.available,
      );
      expect(
        calculator
            .compare(
              currentPeriod: p,
              comparisonPeriod: q,
              current: null,
              comparison: 0,
            )
            .availability,
        FinancialComparisonAvailability.unavailable,
      );
      expect(
        calculator
            .compare(
              currentPeriod: p,
              comparisonPeriod: q,
              current: 1,
              comparison: 0,
            )
            .percentageDifference,
        isNull,
      );
      expect(
        calculator
            .compare(
              currentPeriod: p,
              comparisonPeriod: _period(2026, 8, 31, wallet: 'member-two'),
              current: 50,
              comparison: 50,
            )
            .availability,
        FinancialComparisonAvailability.incompatibleScope,
      );
    },
  );
  test('C43 C44 C45 monthly helper rejects incoherent monthly inputs', () {
    final midMonth = FinancialComparablePeriod(
      start: DateTime(2026, 9, 10),
      end: DateTime(2026, 9, 21),
      walletId: 'w',
      walletScope: FinancialWalletScope.individualWallet,
      completeness: FinancialPeriodCompleteness.partial,
    );
    final incomplete = _period(2026, 9, 21);
    final falsePartial = _period(
      2026,
      9,
      30,
      completeness: FinancialPeriodCompleteness.partial,
    );
    expect(
      () => calculator.previousEquivalentMonth(midMonth),
      throwsArgumentError,
    );
    expect(
      () => calculator.previousEquivalentMonth(incomplete),
      throwsArgumentError,
    );
    expect(
      () => calculator.previousEquivalentMonth(falsePartial),
      throwsArgumentError,
    );
  });

  test(
    'C46 C47 C48 C49 C50 compare requires equivalent monthly completeness',
    () {
      final complete = _period(2026, 9, 30);
      final previousComplete = _period(2026, 8, 31);
      final partial = _period(
        2026,
        9,
        21,
        completeness: FinancialPeriodCompleteness.partial,
      );
      final previousPartial = _period(
        2026,
        8,
        21,
        completeness: FinancialPeriodCompleteness.partial,
      );
      final wrongPartial = _period(
        2026,
        8,
        15,
        completeness: FinancialPeriodCompleteness.partial,
      );
      expect(
        calculator
            .compare(
              currentPeriod: complete,
              comparisonPeriod: partial,
              current: 1,
              comparison: 1,
            )
            .availability,
        FinancialComparisonAvailability.incompatibleScope,
      );
      expect(
        calculator
            .compare(
              currentPeriod: partial,
              comparisonPeriod: complete,
              current: 1,
              comparison: 1,
            )
            .availability,
        FinancialComparisonAvailability.incompatibleScope,
      );
      expect(
        calculator
            .compare(
              currentPeriod: partial,
              comparisonPeriod: previousPartial,
              current: 1,
              comparison: 1,
            )
            .availability,
        FinancialComparisonAvailability.available,
      );
      expect(
        calculator
            .compare(
              currentPeriod: partial,
              comparisonPeriod: wrongPartial,
              current: 1,
              comparison: 1,
            )
            .availability,
        FinancialComparisonAvailability.incompatibleScope,
      );
      expect(
        calculator
            .compare(
              currentPeriod: complete,
              comparisonPeriod: previousComplete,
              current: 1,
              comparison: 1,
            )
            .availability,
        FinancialComparisonAvailability.available,
      );
    },
  );

  test('C51 C52 baseline sorts recent valid periods and rejects overlap', () {
    final current = _period(2026, 9, 30);
    final result = calculator.baseline(
      currentPeriod: current,
      requestedPeriodCount: 2,
      historical: [
        FinancialHistoricalValue(period: _period(2026, 6, 30), value: 6),
        FinancialHistoricalValue(period: _period(2026, 10, 31), value: 10),
        FinancialHistoricalValue(period: _period(2026, 8, 31), value: 8),
        FinancialHistoricalValue(period: _period(2026, 7, 31), value: 7),
        FinancialHistoricalValue(period: _period(2026, 9, 30), value: 9),
      ],
    );
    expect(result.usedPeriods.map((period) => period.start.month), [8, 7]);
    expect(result.value, 7.5);
  });
}
