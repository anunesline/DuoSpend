import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/financial_intelligence/domain/comparison/financial_comparison.dart';
import 'package:app/features/financial_intelligence/domain/facts/financial_facts.dart';
import 'package:app/features/financial_intelligence/domain/signals/financial_signal_policies.dart';
import 'package:app/features/financial_intelligence/domain/signals/financial_signals.dart';

void main() {
  final period = FinancialComparablePeriod(
    start: DateTime(2026, 1, 1),
    end: DateTime(2026, 1, 31),
    walletId: 'w',
    walletScope: FinancialWalletScope.individualWallet,
    completeness: FinancialPeriodCompleteness.complete,
  );

  test('approved V1 thresholds are represented as 0.20 and R50', () {
    expect(FinancialSignalPolicies.v1.minimumPercentage, 0.20);
    expect(FinancialSignalPolicies.v1.minimumAbsoluteDifference, 50);
    expect(FinancialSignalPolicies.v1.allowBaseZeroByAbsolute, isTrue);
  });

  test('approved V1 comparative matrix', () {
    const detector = FinancialSignalDetector();
    FinancialComparisonValue value(double current, double comparison) =>
        FinancialComparisonValue.available(
          current: current,
          comparison: comparison,
          percentageDifference: comparison == 0
              ? null
              : (current - comparison) / comparison,
        );
    List<FinancialSignal> detect(FinancialComparisonValue c) =>
        detector.comparative(
          type: FinancialSignalType.spendingChanged,
          metric: FinancialSignalMetric.realizedExpense,
          comparison: c,
          period: period,
          comparisonPeriod: period,
          policy: FinancialSignalPolicies.v1,
        );
    expect(detect(value(1100, 1000)), isEmpty);
    expect(detect(value(130, 100)), isEmpty);
    expect(detect(value(260, 200)), hasLength(1));
    expect(detect(value(800, 1000)), hasLength(1));
    expect(detect(value(20, 0)), isEmpty);
    expect(detect(value(80, 0)), hasLength(1));
  });
}
