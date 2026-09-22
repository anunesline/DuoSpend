import '../comparison/financial_comparison.dart';
import '../facts/financial_facts.dart';

enum FinancialSignalType {
  spendingChanged,
  incomeChanged,
  cashFlowChanged,
  categorySpendingChanged,
  cardSpendingChanged,
  budgetExceeded,
  knownCommitment,
  invoiceDue,
  invoiceOverdue,
}

enum FinancialSignalDirection {
  increase,
  decrease,
  exceeded,
  informational,
  due,
  overdue,
}

enum FinancialSignalEvidence { initial, comparable, established, currentState }

enum FinancialSignalMetric {
  realizedExpense,
  realizedIncome,
  cashInflow,
  cashOutflow,
  cashNet,
  categorySpending,
  cardSpending,
}

class FinancialSignalPeriod {
  const FinancialSignalPeriod({
    required this.start,
    required this.end,
    required this.completeness,
  });

  factory FinancialSignalPeriod.fromComparable(
    FinancialComparablePeriod period,
  ) => FinancialSignalPeriod(
    start: period.start,
    end: period.end,
    completeness: period.completeness,
  );

  final DateTime start;
  final DateTime end;
  final FinancialPeriodCompleteness completeness;
}

enum FinancialSignalReason {
  comparisonThresholdMet,
  budgetExceeded,
  knownCommitmentsPresent,
  invoiceDue,
  invoiceOverdue,
}

class FinancialSignalPolicy {
  const FinancialSignalPolicy({
    required this.minimumPercentage,
    required this.minimumAbsoluteDifference,
    this.allowBaseZeroByAbsolute = false,
  });
  final double minimumPercentage;
  final double minimumAbsoluteDifference;
  final bool allowBaseZeroByAbsolute;
}

class FinancialSignal {
  const FinancialSignal({
    required this.type,
    required this.direction,
    required this.reason,
    required this.evidence,
    required this.dedupeKey,
    required this.walletId,
    required this.walletScope,
    required this.period,
    this.currentValue,
    this.comparisonValue,
    this.absoluteDifference,
    this.percentageDifference,
    this.category,
    this.cardId,
    this.invoiceId,
    this.baseline,
    this.sourceMetric,
    this.comparisonPeriod,
    this.commitmentRangeEnd,
    this.dueDate,
    this.referenceAt,
  });
  final FinancialSignalType type;
  final FinancialSignalDirection direction;
  final FinancialSignalReason reason;
  final FinancialSignalEvidence evidence;
  final String dedupeKey;
  final String walletId;
  final FinancialWalletScope walletScope;
  final FinancialSignalPeriod period;
  final double? currentValue,
      comparisonValue,
      absoluteDifference,
      percentageDifference,
      baseline;
  final String? category, cardId, invoiceId;
  final FinancialSignalMetric? sourceMetric;
  final FinancialSignalPeriod? comparisonPeriod;
  final DateTime? commitmentRangeEnd, dueDate, referenceAt;
}

class FinancialSignalDetector {
  const FinancialSignalDetector();
  List<FinancialSignal> comparative({
    required FinancialSignalType type,
    required FinancialSignalMetric metric,
    required FinancialComparisonValue comparison,
    required FinancialComparablePeriod period,
    required FinancialComparablePeriod comparisonPeriod,
    required FinancialSignalPolicy policy,
    FinancialBaseline? baseline,
    String? category,
    String? cardId,
  }) {
    _validateMetric(type, metric);
    if (comparison.availability != FinancialComparisonAvailability.available ||
        comparison.absoluteDifference == null ||
        comparison.absoluteDifference == 0) {
      return const [];
    }
    final absolute = comparison.absoluteDifference!.abs();
    final percentage = comparison.percentageDifference?.abs();
    if (absolute < policy.minimumAbsoluteDifference ||
        (percentage == null && !policy.allowBaseZeroByAbsolute) ||
        (percentage != null && percentage < policy.minimumPercentage)) {
      return const [];
    }
    final direction = comparison.absoluteDifference! > 0
        ? FinancialSignalDirection.increase
        : FinancialSignalDirection.decrease;
    final evidence = baseline == null || baseline.validPeriodCount < 2
        ? FinancialSignalEvidence.initial
        : baseline.validPeriodCount < 3
        ? FinancialSignalEvidence.comparable
        : FinancialSignalEvidence.established;
    final key =
        '${type.name}|${_metricToken(metric)}|${period.walletId}|${period.start.toIso8601String()}|${category ?? ''}|${cardId ?? ''}';
    return [
      FinancialSignal(
        type: type,
        direction: direction,
        reason: FinancialSignalReason.comparisonThresholdMet,
        evidence: evidence,
        dedupeKey: key,
        walletId: period.walletId,
        walletScope: period.walletScope,
        period: FinancialSignalPeriod.fromComparable(period),
        comparisonPeriod: FinancialSignalPeriod.fromComparable(
          comparisonPeriod,
        ),
        sourceMetric: metric,
        currentValue: comparison.current,
        comparisonValue: comparison.comparison,
        absoluteDifference: comparison.absoluteDifference,
        percentageDifference: comparison.percentageDifference,
        baseline: baseline?.value,
        category: category,
        cardId: cardId,
      ),
    ];
  }

  List<FinancialSignal> budget({
    required FinancialComparablePeriod period,
    required double limit,
    required double consumed,
    required String category,
  }) {
    if (consumed <= limit) return const [];
    return [
      FinancialSignal(
        type: FinancialSignalType.budgetExceeded,
        direction: FinancialSignalDirection.exceeded,
        reason: FinancialSignalReason.budgetExceeded,
        evidence: FinancialSignalEvidence.currentState,
        dedupeKey:
            'budgetExceeded|${period.walletId}|${period.start.toIso8601String()}|$category',
        walletId: period.walletId,
        walletScope: period.walletScope,
        period: FinancialSignalPeriod.fromComparable(period),
        currentValue: consumed,
        comparisonValue: limit,
        absoluteDifference: consumed - limit,
        category: category,
      ),
    ];
  }

  List<FinancialSignal> commitments({
    required FinancialComparablePeriod period,
    required double inflow,
    required double outflow,
    required int count,
    required DateTime commitmentRangeEnd,
  }) {
    if (count <= 0) return const [];
    return [
      FinancialSignal(
        type: FinancialSignalType.knownCommitment,
        direction: FinancialSignalDirection.informational,
        reason: FinancialSignalReason.knownCommitmentsPresent,
        evidence: FinancialSignalEvidence.currentState,
        dedupeKey:
            'knownCommitment|${period.walletId}|${period.start.toIso8601String()}',
        walletId: period.walletId,
        walletScope: period.walletScope,
        period: FinancialSignalPeriod.fromComparable(period),
        commitmentRangeEnd: commitmentRangeEnd,
        currentValue: outflow - inflow,
        comparisonValue: outflow,
        absoluteDifference: inflow,
      ),
    ];
  }

  List<FinancialSignal> invoice({
    required FinancialComparablePeriod period,
    required String invoiceId,
    required DateTime dueDate,
    required bool isPaid,
    required DateTime referenceAt,
  }) {
    if (isPaid) return const [];
    final overdue = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    ).isBefore(DateTime(referenceAt.year, referenceAt.month, referenceAt.day));
    return [
      FinancialSignal(
        type: overdue
            ? FinancialSignalType.invoiceOverdue
            : FinancialSignalType.invoiceDue,
        direction: overdue
            ? FinancialSignalDirection.overdue
            : FinancialSignalDirection.due,
        reason: overdue
            ? FinancialSignalReason.invoiceOverdue
            : FinancialSignalReason.invoiceDue,
        evidence: FinancialSignalEvidence.currentState,
        dedupeKey:
            '${overdue ? 'invoiceOverdue' : 'invoiceDue'}|${period.walletId}|$invoiceId',
        walletId: period.walletId,
        walletScope: period.walletScope,
        period: FinancialSignalPeriod.fromComparable(period),
        invoiceId: invoiceId,
        dueDate: dueDate,
        referenceAt: referenceAt,
      ),
    ];
  }

  void _validateMetric(FinancialSignalType type, FinancialSignalMetric metric) {
    final valid = switch (type) {
      FinancialSignalType.spendingChanged =>
        metric == FinancialSignalMetric.realizedExpense,
      FinancialSignalType.incomeChanged =>
        metric == FinancialSignalMetric.realizedIncome,
      FinancialSignalType.cashFlowChanged =>
        metric == FinancialSignalMetric.cashInflow ||
            metric == FinancialSignalMetric.cashOutflow ||
            metric == FinancialSignalMetric.cashNet,
      FinancialSignalType.categorySpendingChanged =>
        metric == FinancialSignalMetric.categorySpending,
      FinancialSignalType.cardSpendingChanged =>
        metric == FinancialSignalMetric.cardSpending,
      _ => false,
    };
    if (!valid) throw ArgumentError.value(metric, 'metric');
  }

  String _metricToken(FinancialSignalMetric metric) => switch (metric) {
    FinancialSignalMetric.realizedExpense => 'expense',
    FinancialSignalMetric.realizedIncome => 'income',
    FinancialSignalMetric.cashInflow => 'cashInflow',
    FinancialSignalMetric.cashOutflow => 'cashOutflow',
    FinancialSignalMetric.cashNet => 'cashNet',
    FinancialSignalMetric.categorySpending => 'categorySpending',
    FinancialSignalMetric.cardSpending => 'cardPurchase',
  };
}
