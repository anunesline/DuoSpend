import 'dart:math' as math;

import 'product_price_observation.dart';

class ProductSpendingBreakdown {
  const ProductSpendingBreakdown({
    required this.totalSpent,
    this.id,
    this.name,
  });

  final String? id;
  final String? name;
  final double totalSpent;
}

class ProductProbableRecurrence {
  const ProductProbableRecurrence({
    required this.averageInterval,
    required this.nextExpectedPurchaseAt,
    required this.observationCount,
  });

  final Duration averageInterval;
  final DateTime nextExpectedPurchaseAt;
  final int observationCount;
}

class ProductPurchaseMetrics {
  const ProductPurchaseMetrics({
    required this.productId,
    required this.history,
    required this.averageUnitPrice,
    required this.minimumUnitPrice,
    required this.maximumUnitPrice,
    required this.absolutePriceVariation,
    required this.percentagePriceVariation,
    required this.totalQuantity,
    required this.totalSpent,
    required this.purchaseFrequencyPer30Days,
    required this.averagePurchaseInterval,
    required this.spendingByMerchant,
    required this.spendingByCategory,
    required this.probableRecurrence,
  });

  final String productId;

  /// Histórico válido em ordem cronológica crescente.
  final List<ProductPriceObservation> history;
  final double? averageUnitPrice;
  final double? minimumUnitPrice;
  final double? maximumUnitPrice;
  final double? absolutePriceVariation;
  final double? percentagePriceVariation;
  final double totalQuantity;
  final double totalSpent;

  /// Número médio de recompras em uma janela de 30 dias.
  ///
  /// Uma única observação não é suficiente para determinar frequência.
  final double? purchaseFrequencyPer30Days;
  final Duration? averagePurchaseInterval;
  final List<ProductSpendingBreakdown> spendingByMerchant;
  final List<ProductSpendingBreakdown> spendingByCategory;
  final ProductProbableRecurrence? probableRecurrence;

  ProductPriceObservation? get lastPurchase =>
      history.isEmpty ? null : history.last;

  double? get lastUnitPrice => lastPurchase?.unitPrice;

  double? get lastPurchasedQuantity => lastPurchase?.quantity;

  bool get hasPreviousPurchase => history.length >= 2;
}

class ProductPurchaseMetricsCalculator {
  const ProductPurchaseMetricsCalculator({
    this.recurrenceMinimumObservations = 3,
    this.recurrenceMaximumRelativeDeviation = 0.25,
  });

  final int recurrenceMinimumObservations;
  final double recurrenceMaximumRelativeDeviation;

  ProductPurchaseMetrics calculate({
    required String productId,
    required Iterable<ProductPriceObservation> observations,
  }) {
    final history = _validChronologicalHistory(
      productId: productId,
      observations: observations,
    );

    if (history.isEmpty) {
      return ProductPurchaseMetrics(
        productId: productId,
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
        probableRecurrence: null,
      );
    }

    final unitPrices = history.map((observation) => observation.unitPrice);
    final averageUnitPrice =
        unitPrices.reduce((sum, price) => sum + price) / history.length;
    final minimumUnitPrice = unitPrices.reduce(math.min);
    final maximumUnitPrice = unitPrices.reduce(math.max);
    final totalQuantity = history.fold<double>(
      0,
      (sum, observation) => sum + observation.quantity,
    );
    final totalSpent = history.fold<double>(
      0,
      (sum, observation) => sum + observation.observedTotal,
    );

    double? absolutePriceVariation;
    double? percentagePriceVariation;
    if (history.length >= 2) {
      final previousPrice = history[history.length - 2].unitPrice;
      final lastPrice = history.last.unitPrice;
      absolutePriceVariation = lastPrice - previousPrice;
      if (previousPrice > 0) {
        percentagePriceVariation = absolutePriceVariation / previousPrice * 100;
      }
    }

    final intervals = _intervals(history);
    final averageInterval = _averageInterval(intervals);
    final spanInDays = history.length >= 2
        ? history.last.purchasedAt
                  .difference(history.first.purchasedAt)
                  .inMicroseconds /
              Duration.microsecondsPerDay
        : 0.0;
    final frequency = spanInDays > 0
        ? (history.length - 1) * 30 / spanInDays
        : null;

    return ProductPurchaseMetrics(
      productId: productId,
      history: List.unmodifiable(history),
      averageUnitPrice: averageUnitPrice,
      minimumUnitPrice: minimumUnitPrice,
      maximumUnitPrice: maximumUnitPrice,
      absolutePriceVariation: absolutePriceVariation,
      percentagePriceVariation: percentagePriceVariation,
      totalQuantity: totalQuantity,
      totalSpent: totalSpent,
      purchaseFrequencyPer30Days: frequency,
      averagePurchaseInterval: averageInterval,
      spendingByMerchant: _spendingBreakdown(
        history: history,
        idOf: (observation) => observation.merchantId,
        nameOf: (observation) => observation.merchantName,
      ),
      spendingByCategory: _spendingBreakdown(
        history: history,
        idOf: (observation) => observation.productCategoryId,
        nameOf: (observation) => observation.productCategoryName,
      ),
      probableRecurrence: _probableRecurrence(
        history: history,
        intervals: intervals,
        averageInterval: averageInterval,
      ),
    );
  }

  List<ProductPriceObservation> _validChronologicalHistory({
    required String productId,
    required Iterable<ProductPriceObservation> observations,
  }) {
    final byPurchase = <String, ProductPriceObservation>{};

    for (final observation in observations) {
      if (observation.productId != productId ||
          observation.purchaseId.trim().isEmpty ||
          observation.purchasedAt.millisecondsSinceEpoch <= 0 ||
          observation.unitPrice <= 0 ||
          observation.quantity <= 0) {
        continue;
      }

      byPurchase[observation.purchaseId] = observation;
    }

    final result = byPurchase.values.toList()
      ..sort((left, right) {
        final dateComparison = left.purchasedAt.compareTo(right.purchasedAt);
        if (dateComparison != 0) {
          return dateComparison;
        }

        return left.purchaseId.compareTo(right.purchaseId);
      });

    return result;
  }

  List<Duration> _intervals(List<ProductPriceObservation> history) {
    final result = <Duration>[];
    for (var index = 1; index < history.length; index++) {
      result.add(
        history[index].purchasedAt.difference(history[index - 1].purchasedAt),
      );
    }
    return result;
  }

  Duration? _averageInterval(List<Duration> intervals) {
    if (intervals.isEmpty) {
      return null;
    }

    final totalMicroseconds = intervals.fold<int>(
      0,
      (sum, interval) => sum + interval.inMicroseconds,
    );
    return Duration(
      microseconds: (totalMicroseconds / intervals.length).round(),
    );
  }

  ProductProbableRecurrence? _probableRecurrence({
    required List<ProductPriceObservation> history,
    required List<Duration> intervals,
    required Duration? averageInterval,
  }) {
    if (history.length < recurrenceMinimumObservations ||
        intervals.length < recurrenceMinimumObservations - 1 ||
        averageInterval == null ||
        averageInterval.inMicroseconds <= 0) {
      return null;
    }

    final averageMicroseconds = averageInterval.inMicroseconds.toDouble();
    final maximumRelativeDeviation = intervals
        .map(
          (interval) =>
              (interval.inMicroseconds - averageMicroseconds).abs() /
              averageMicroseconds,
        )
        .reduce(math.max);

    if (maximumRelativeDeviation > recurrenceMaximumRelativeDeviation) {
      return null;
    }

    return ProductProbableRecurrence(
      averageInterval: averageInterval,
      nextExpectedPurchaseAt: history.last.purchasedAt.add(averageInterval),
      observationCount: history.length,
    );
  }

  List<ProductSpendingBreakdown> _spendingBreakdown({
    required List<ProductPriceObservation> history,
    required String? Function(ProductPriceObservation) idOf,
    required String? Function(ProductPriceObservation) nameOf,
  }) {
    final entries = <String, _MutableSpendingBreakdown>{};

    for (final observation in history) {
      final id = _nullableText(idOf(observation));
      final name = _nullableText(nameOf(observation));
      if (id == null && name == null) {
        continue;
      }

      final key = id != null
          ? 'id:${id.toLowerCase()}'
          : 'name:${name!.toLowerCase()}';
      final current = entries.putIfAbsent(
        key,
        () => _MutableSpendingBreakdown(id: id, name: name),
      );
      current.totalSpent += observation.observedTotal;
    }

    final result =
        entries.values
            .map(
              (entry) => ProductSpendingBreakdown(
                id: entry.id,
                name: entry.name,
                totalSpent: entry.totalSpent,
              ),
            )
            .toList()
          ..sort((left, right) {
            final amountComparison = right.totalSpent.compareTo(
              left.totalSpent,
            );
            if (amountComparison != 0) {
              return amountComparison;
            }

            return (left.name ?? left.id ?? '').compareTo(
              right.name ?? right.id ?? '',
            );
          });

    return List.unmodifiable(result);
  }

  String? _nullableText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

class _MutableSpendingBreakdown {
  _MutableSpendingBreakdown({required this.id, required this.name});

  final String? id;
  final String? name;
  double totalSpent = 0;
}
