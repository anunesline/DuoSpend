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
    this.currentValue,
    this.comparisonValue,
    this.absoluteDifference,
    this.percentageDifference,
    this.category,
    this.cardId,
    this.invoiceId,
    this.baseline,
  });
  final FinancialSignalType type;
  final FinancialSignalDirection direction;
  final FinancialSignalReason reason;
  final FinancialSignalEvidence evidence;
  final String dedupeKey;
  final String walletId;
  final FinancialWalletScope walletScope;
  final double? currentValue,
      comparisonValue,
      absoluteDifference,
      percentageDifference,
      baseline;
  final String? category, cardId, invoiceId;
}

class FinancialSignalDetector {
  const FinancialSignalDetector();
  List<FinancialSignal> comparative({
    required FinancialSignalType type,
    required String metric,
    required FinancialComparisonValue comparison,
    required FinancialComparablePeriod period,
    required FinancialSignalPolicy policy,
    FinancialBaseline? baseline,
    String? category,
    String? cardId,
  }) {
    if (comparison.availability != FinancialComparisonAvailability.available ||
        comparison.absoluteDifference == null ||
        comparison.absoluteDifference == 0)
      return const [];
    final absolute = comparison.absoluteDifference!.abs();
    final percentage = comparison.percentageDifference?.abs();
    if (absolute < policy.minimumAbsoluteDifference ||
        (percentage == null && !policy.allowBaseZeroByAbsolute) ||
        (percentage != null && percentage < policy.minimumPercentage))
      return const [];
    final direction = comparison.absoluteDifference! > 0
        ? FinancialSignalDirection.increase
        : FinancialSignalDirection.decrease;
    final evidence = baseline == null || baseline.validPeriodCount < 2
        ? FinancialSignalEvidence.initial
        : baseline.validPeriodCount < 3
        ? FinancialSignalEvidence.comparable
        : FinancialSignalEvidence.established;
    final key =
        '${type.name}|$metric|${period.walletId}|${period.start.toIso8601String()}|${category ?? ''}|${cardId ?? ''}';
    return [
      FinancialSignal(
        type: type,
        direction: direction,
        reason: FinancialSignalReason.comparisonThresholdMet,
        evidence: evidence,
        dedupeKey: key,
        walletId: period.walletId,
        walletScope: period.walletScope,
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
        invoiceId: invoiceId,
      ),
    ];
  }
}
