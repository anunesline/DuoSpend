import '../facts/financial_facts.dart';

enum FinancialPeriodCompleteness { complete, partial }

enum FinancialComparisonAvailability {
  available,
  insufficientHistory,
  incompatibleScope,
  unavailable,
  notHistoricallyReconstructible,
}

class FinancialComparablePeriod {
  const FinancialComparablePeriod({
    required this.start,
    required this.end,
    required this.walletId,
    required this.walletScope,
    required this.completeness,
  });
  final DateTime start;
  final DateTime end;
  final String walletId;
  final FinancialWalletScope walletScope;
  final FinancialPeriodCompleteness completeness;
}

class FinancialComparisonValue {
  const FinancialComparisonValue.available({
    required this.current,
    required this.comparison,
    this.percentageDifference,
  }) : availability = FinancialComparisonAvailability.available;
  const FinancialComparisonValue.unavailable(this.availability)
    : current = null,
      comparison = null,
      percentageDifference = null;
  final FinancialComparisonAvailability availability;
  final double? current;
  final double? comparison;
  final double? percentageDifference;
  double? get absoluteDifference =>
      current == null || comparison == null ? null : current! - comparison!;
}

class FinancialBaseline {
  const FinancialBaseline({
    required this.availability,
    required this.requestedPeriodCount,
    required this.validPeriodCount,
    required this.usedPeriods,
    this.value,
  });
  final FinancialComparisonAvailability availability;
  final int requestedPeriodCount;
  final int validPeriodCount;
  final List<FinancialComparablePeriod> usedPeriods;
  final double? value;
}

class FinancialHistoricalValue {
  const FinancialHistoricalValue({
    required this.period,
    this.value,
    this.available = true,
  });
  final FinancialComparablePeriod period;
  final double? value;
  final bool available;
}

class FinancialComparisonCalculator {
  const FinancialComparisonCalculator();

  FinancialComparablePeriod previousEquivalentMonth(
    FinancialComparablePeriod period,
  ) {
    final start = _date(period.start);
    final end = _date(period.end);
    if (end.isBefore(start)) throw ArgumentError('end cannot precede start');
    _validateMonthlyPeriod(period, start, end);
    final previousStart = DateTime(start.year, start.month - 1, 1);
    final previousLast = DateTime(
      previousStart.year,
      previousStart.month + 1,
      0,
    ).day;
    final previousEnd =
        period.completeness == FinancialPeriodCompleteness.complete
        ? DateTime(previousStart.year, previousStart.month, previousLast)
        : DateTime(
            previousStart.year,
            previousStart.month,
            end.day > previousLast ? previousLast : end.day,
          );
    return FinancialComparablePeriod(
      start: previousStart,
      end: previousEnd,
      walletId: period.walletId,
      walletScope: period.walletScope,
      completeness: period.completeness,
    );
  }

  FinancialComparisonValue compare({
    required FinancialComparablePeriod currentPeriod,
    required FinancialComparablePeriod comparisonPeriod,
    required double? current,
    required double? comparison,
  }) {
    if (!_compatible(currentPeriod, comparisonPeriod) ||
        !_temporallyCompatible(currentPeriod, comparisonPeriod))
      return const FinancialComparisonValue.unavailable(
        FinancialComparisonAvailability.incompatibleScope,
      );
    if (current == null || comparison == null)
      return const FinancialComparisonValue.unavailable(
        FinancialComparisonAvailability.unavailable,
      );
    final percentage = comparison == 0
        ? null
        : (current - comparison) / comparison;
    return FinancialComparisonValue.available(
      current: current,
      comparison: comparison,
      percentageDifference: percentage,
    );
  }

  FinancialBaseline baseline({
    required FinancialComparablePeriod currentPeriod,
    required int requestedPeriodCount,
    required Iterable<FinancialHistoricalValue> historical,
  }) {
    if (requestedPeriodCount < 1)
      throw ArgumentError.value(requestedPeriodCount, 'requestedPeriodCount');
    final usable =
        historical
            .where(
              (item) =>
                  item.available &&
                  item.value != null &&
                  item.period.completeness ==
                      FinancialPeriodCompleteness.complete &&
                  _compatible(currentPeriod, item.period) &&
                  item.period.end.isBefore(currentPeriod.start),
            )
            .toList()
          ..sort(
            (first, second) => second.period.end.compareTo(first.period.end),
          );
    final selected = usable.take(requestedPeriodCount).toList();
    if (selected.isEmpty)
      return FinancialBaseline(
        availability: FinancialComparisonAvailability.insufficientHistory,
        requestedPeriodCount: requestedPeriodCount,
        validPeriodCount: 0,
        usedPeriods: const [],
      );
    final average =
        selected.fold<double>(0, (sum, item) => sum + item.value!) /
        selected.length;
    return FinancialBaseline(
      availability: FinancialComparisonAvailability.available,
      requestedPeriodCount: requestedPeriodCount,
      validPeriodCount: selected.length,
      usedPeriods: List.unmodifiable(selected.map((item) => item.period)),
      value: average,
    );
  }

  FinancialComparisonValue historicalSnapshot() =>
      const FinancialComparisonValue.unavailable(
        FinancialComparisonAvailability.notHistoricallyReconstructible,
      );
  bool _compatible(FinancialComparablePeriod a, FinancialComparablePeriod b) =>
      a.walletId == b.walletId && a.walletScope == b.walletScope;
  bool _temporallyCompatible(
    FinancialComparablePeriod current,
    FinancialComparablePeriod comparison,
  ) {
    final currentStart = _date(current.start);
    final currentEnd = _date(current.end);
    final comparisonStart = _date(comparison.start);
    final comparisonEnd = _date(comparison.end);
    try {
      _validateMonthlyPeriod(current, currentStart, currentEnd);
      _validateMonthlyPeriod(comparison, comparisonStart, comparisonEnd);
    } on ArgumentError {
      return false;
    }
    if (current.completeness != comparison.completeness) return false;
    return current.completeness == FinancialPeriodCompleteness.complete ||
        currentEnd.day == comparisonEnd.day;
  }

  void _validateMonthlyPeriod(
    FinancialComparablePeriod period,
    DateTime start,
    DateTime end,
  ) {
    if (start.day != 1)
      throw ArgumentError('monthly period must start on day 1');
    if (start.year != end.year || start.month != end.month)
      throw ArgumentError('monthly period must end in the same month');
    final lastDay = DateTime(start.year, start.month + 1, 0).day;
    if (period.completeness == FinancialPeriodCompleteness.complete &&
        end.day != lastDay)
      throw ArgumentError('complete period must end on the last day');
    if (period.completeness == FinancialPeriodCompleteness.partial &&
        end.day >= lastDay)
      throw ArgumentError('partial period must end before the last day');
  }

  DateTime _date(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
