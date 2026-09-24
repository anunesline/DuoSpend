import 'dart:math' as math;

import '../../../../shared/knowledge/products/product_price_observation.dart';
import '../../../../shared/knowledge/products/product_purchase_metrics.dart';
import '../models/consumption_event.dart';

enum ConsumptionEvidenceQuality { insufficient, low, moderate, strong }

enum ConsumptionSignalType {
  priceBelowUsual,
  priceAboveUsual,
  newLowestPrice,
  newHighestPrice,
  quantityAboveUsual,
  quantityBelowUsual,
  repurchaseApproaching,
  repurchaseOverdue,
  repurchaseEarly,
  consumptionPatternChanged,
  betterPriceAtOtherMerchant,
  merchantPricePattern,
  priceAndQuantityChanged,
}

enum ConsumptionState {
  insufficientHistory,
  withinExpectedRhythm,
  approachingRepurchase,
  overdueRepurchase,
  stockConfirmedRemaining,
  finishedConfirmed,
  paused,
  discontinued,
  unknown,
}

class ConsumptionPolicy {
  const ConsumptionPolicy({
    this.minimumObservations = 3,
    this.minimumPriceAbsoluteDifference = .50,
    this.minimumRelativeDifference = .05,
    this.repurchaseTolerance = .25,
    this.minimumMerchantObservations = 2,
    this.policyVersion = 1,
  });
  final int minimumObservations;
  final double minimumPriceAbsoluteDifference;
  final double minimumRelativeDifference;
  final double repurchaseTolerance;
  final int minimumMerchantObservations;
  final int policyVersion;
}

class ConsumptionSignal {
  const ConsumptionSignal({
    required this.type,
    required this.productId,
    required this.scopeId,
    required this.observedAt,
    required this.observedValue,
    required this.baselineValue,
    required this.evidenceQuality,
    required this.observationCount,
    required this.policyVersion,
    this.merchantId,
    this.absoluteDifference,
    this.percentageDifference,
    this.factIds = const [],
  });
  final ConsumptionSignalType type;
  final String productId;
  final String scopeId;
  final DateTime observedAt;
  final double observedValue;
  final double baselineValue;
  final double? absoluteDifference;
  final double? percentageDifference;
  final ConsumptionEvidenceQuality evidenceQuality;
  final int observationCount;
  final String? merchantId;
  final List<String> factIds;
  final int policyVersion;
}

class ConsumptionDerivedState {
  const ConsumptionDerivedState({
    required this.state,
    required this.evidenceQuality,
    this.lastPurchase,
    this.lastHumanFeedback,
    this.confirmedRemainingQuantity,
    this.estimatedExhaustionAt,
    this.averageDuration,
  });
  final ConsumptionState state;
  final ConsumptionEvidenceQuality evidenceQuality;
  final ProductPriceObservation? lastPurchase;
  final ConsumptionEvent? lastHumanFeedback;
  final double? confirmedRemainingQuantity;
  final DateTime? estimatedExhaustionAt;
  final Duration? averageDuration;
}

class ConsumptionIntelligenceResult {
  const ConsumptionIntelligenceResult({
    required this.productId,
    required this.scopeId,
    required this.metrics,
    required this.state,
    required this.signals,
    required this.activeEvents,
    required this.policyVersion,
  });
  final String productId;
  final String scopeId;
  final ProductPurchaseMetrics metrics;
  final ConsumptionDerivedState state;
  final List<ConsumptionSignal> signals;
  final List<ConsumptionEvent> activeEvents;
  final int policyVersion;
}

/// Pure deterministic calculation. Purchases remain purchase facts; this class
/// never turns a missing repurchase into a confirmed depletion or a cause.
class ConsumptionIntelligenceEngine {
  const ConsumptionIntelligenceEngine({
    this.policy = const ConsumptionPolicy(),
  });
  final ConsumptionPolicy policy;

  ConsumptionIntelligenceResult analyze({
    required String productId,
    required String scopeId,
    required ProductPurchaseMetrics metrics,
    required Iterable<ConsumptionEvent> events,
    required DateTime referenceAt,
    bool quantityComparable = false,
  }) {
    final active =
        events
            .where(
              (e) =>
                  e.isActive &&
                  e.productId == productId &&
                  e.scopeId == scopeId,
            )
            .toList()
          ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final feedback = active.isEmpty ? null : active.last;
    // An exceptional purchase changes neither the regular price nor the
    // regular replenishment rhythm, but only when it is explicitly linked to
    // this observed purchase. An unlinked event is not enough to guess.
    final exceptionalPurchaseIds = active
        .where((e) => e.type == ConsumptionEventType.exceptionalPurchase)
        .map((e) => e.purchaseId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    final exceptionalObservationIds = active
        .where((e) => e.type == ConsumptionEventType.exceptionalPurchase)
        .map((e) => e.priceObservationId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    final regularHistory = metrics.history
        .where(
          (observation) =>
              !exceptionalPurchaseIds.contains(observation.purchaseId) &&
              !exceptionalObservationIds.contains(observation.id),
        )
        .toList();
    final effectiveMetrics = regularHistory.length == metrics.history.length
        ? metrics
        : const ProductPurchaseMetricsCalculator().calculate(
            productId: productId,
            observations: regularHistory,
          );
    final quality = _quality(effectiveMetrics);
    final pause = active
        .where(
          (e) =>
              e.type == ConsumptionEventType.paused &&
              (e.pauseUntil == null || !e.pauseUntil!.isBefore(referenceAt)),
        )
        .isNotEmpty;
    final stopped = active.any(
      (e) => e.type == ConsumptionEventType.discontinued,
    );
    final external = active
        .where((e) => e.type == ConsumptionEventType.externalPurchase)
        .lastOrNull;

    // A recorded or external purchase starts a new factual acquisition cycle.
    // Stock/finished feedback from an older cycle must not dominate the current
    // state merely because the event remains active and auditable.
    final lastRecordedPurchaseAt = effectiveMetrics.lastPurchase?.purchasedAt;
    final lastAcquisitionAt = _latestDate(
      lastRecordedPurchaseAt,
      external?.occurredAt,
    );
    final stockFeedback = active
        .where(
          (e) =>
              (e.type == ConsumptionEventType.stillHave ||
                  e.type == ConsumptionEventType.finished) &&
              (lastAcquisitionAt == null ||
                  !e.occurredAt.isBefore(lastAcquisitionAt)),
        )
        .lastOrNull;
    final still = stockFeedback?.type == ConsumptionEventType.stillHave
        ? stockFeedback
        : null;
    final finished = stockFeedback?.type == ConsumptionEventType.finished
        ? stockFeedback
        : null;

    ConsumptionState state;
    if (stopped) {
      state = ConsumptionState.discontinued;
    } else if (pause) {
      state = ConsumptionState.paused;
    } else if (still != null) {
      state = ConsumptionState.stockConfirmedRemaining;
    } else if (finished != null) {
      state = ConsumptionState.finishedConfirmed;
    } else if (quality == ConsumptionEvidenceQuality.insufficient) {
      state = ConsumptionState.insufficientHistory;
    } else {
      state = ConsumptionState.withinExpectedRhythm;
    }
    final signals = <ConsumptionSignal>[];
    final h = effectiveMetrics.history;
    if (quality.index >= ConsumptionEvidenceQuality.moderate.index &&
        h.isNotEmpty) {
      final last = h.last;
      final baseline = effectiveMetrics.averageUnitPrice!;
      final d = last.unitPrice - baseline;
      final p = d / baseline;
      if (_relevant(d, p)) {
        signals.add(
          _signal(
            d < 0
                ? ConsumptionSignalType.priceBelowUsual
                : ConsumptionSignalType.priceAboveUsual,
            productId,
            scopeId,
            last.purchasedAt,
            last.unitPrice,
            baseline,
            quality,
            h.length,
            d,
            p,
            last.merchantId,
          ),
        );
        final previous = h.sublist(0, h.length - 1).map((x) => x.unitPrice);
        if (d < 0 && last.unitPrice < previous.reduce(math.min)) {
          signals.add(
            _signal(
              ConsumptionSignalType.newLowestPrice,
              productId,
              scopeId,
              last.purchasedAt,
              last.unitPrice,
              previous.reduce(math.min),
              quality,
              h.length,
              d,
              p,
              last.merchantId,
            ),
          );
        }
        if (d > 0 && last.unitPrice > previous.reduce(math.max)) {
          signals.add(
            _signal(
              ConsumptionSignalType.newHighestPrice,
              productId,
              scopeId,
              last.purchasedAt,
              last.unitPrice,
              previous.reduce(math.max),
              quality,
              h.length,
              d,
              p,
              last.merchantId,
            ),
          );
        }
      }
      if (quantityComparable) {
        _quantitySignals(signals, productId, scopeId, h, quality);
      }
      _merchantSignals(signals, productId, scopeId, h, quality);
      _priceAndQuantitySignal(signals, productId, scopeId, h, quality);
    }
    _earlyRepurchaseSignal(signals, productId, scopeId, h, quality);
    final recurrence = effectiveMetrics.probableRecurrence;
    if (state == ConsumptionState.withinExpectedRhythm &&
        !pause &&
        !stopped &&
        recurrence != null &&
        quality.index >= ConsumptionEvidenceQuality.moderate.index) {
      // An external purchase is an acquisition fact, not a permanent mute.
      // When it is newer than the latest recorded purchase, restart the
      // replenishment clock from its date while keeping price/quantity unknown.
      final externalStartsCurrentCycle =
          external != null &&
          (lastRecordedPurchaseAt == null ||
              external.occurredAt.isAfter(lastRecordedPurchaseAt));
      final expected = externalStartsCurrentCycle
          ? external.occurredAt.add(recurrence.averageInterval)
          : recurrence.nextExpectedPurchaseAt;
      final tolerance = Duration(
        microseconds:
            (recurrence.averageInterval.inMicroseconds *
                    policy.repurchaseTolerance)
                .round(),
      );
      if (!referenceAt.isBefore(expected.subtract(tolerance)) &&
          referenceAt.isBefore(expected.add(tolerance))) {
        state = ConsumptionState.approachingRepurchase;
        signals.add(
          _signal(
            ConsumptionSignalType.repurchaseApproaching,
            productId,
            scopeId,
            referenceAt,
            0,
            0,
            quality,
            h.length,
            null,
            null,
            null,
          ),
        );
      }
      if (referenceAt.isAfter(expected.add(tolerance))) {
        state = ConsumptionState.overdueRepurchase;
        signals.add(
          _signal(
            ConsumptionSignalType.repurchaseOverdue,
            productId,
            scopeId,
            referenceAt,
            0,
            0,
            quality,
            h.length,
            null,
            null,
            null,
          ),
        );
      }
    }
    return ConsumptionIntelligenceResult(
      productId: productId,
      scopeId: scopeId,
      metrics: effectiveMetrics,
      state: ConsumptionDerivedState(
        state: state,
        evidenceQuality: quality,
        lastPurchase: effectiveMetrics.lastPurchase,
        lastHumanFeedback: feedback,
        confirmedRemainingQuantity: still?.remainingQuantity,
      ),
      signals: List.unmodifiable(signals),
      activeEvents: List.unmodifiable(active),
      policyVersion: policy.policyVersion,
    );
  }

  DateTime? _latestDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  ConsumptionEvidenceQuality _quality(ProductPurchaseMetrics m) {
    if (m.history.length < policy.minimumObservations ||
        m.probableRecurrence == null) {
      return ConsumptionEvidenceQuality.insufficient;
    }
    return m.history.length >= 5
        ? ConsumptionEvidenceQuality.strong
        : ConsumptionEvidenceQuality.moderate;
  }

  bool _relevant(double d, double p) =>
      d.abs() >= policy.minimumPriceAbsoluteDifference &&
      p.abs() >= policy.minimumRelativeDifference;
  ConsumptionSignal _signal(
    ConsumptionSignalType t,
    String p,
    String s,
    DateTime at,
    double o,
    double b,
    ConsumptionEvidenceQuality q,
    int n,
    double? d,
    double? pc,
    String? m, {
    List<String> factIds = const <String>[],
  }) => ConsumptionSignal(
    type: t,
    productId: p,
    scopeId: s,
    observedAt: at,
    observedValue: o,
    baselineValue: b,
    evidenceQuality: q,
    observationCount: n,
    policyVersion: policy.policyVersion,
    absoluteDifference: d,
    percentageDifference: pc,
    merchantId: m,
    factIds: factIds,
  );
  void _quantitySignals(
    List<ConsumptionSignal> out,
    String p,
    String s,
    List<ProductPriceObservation> h,
    ConsumptionEvidenceQuality q,
  ) {
    final avg = h.map((x) => x.quantity).reduce((a, b) => a + b) / h.length;
    final last = h.last.quantity;
    final d = last - avg;
    final r = d / avg;
    if (_quantityRelevant(r)) {
      out.add(
        _signal(
          d > 0
              ? ConsumptionSignalType.quantityAboveUsual
              : ConsumptionSignalType.quantityBelowUsual,
          p,
          s,
          h.last.purchasedAt,
          last,
          avg,
          q,
          h.length,
          d,
          r,
          h.last.merchantId,
          factIds: [h.last.id],
        ),
      );
    }
  }

  /// Quantities have no unit in [ProductPriceObservation]. Once the caller
  /// explicitly establishes comparability, use only a relative threshold: a
  /// currency floor would be dimensionally invalid here.
  bool _quantityRelevant(double relativeDifference) =>
      relativeDifference.abs() >= policy.minimumRelativeDifference;

  /// Merchant comparisons describe only observed historical prices. They do
  /// not predict availability or a future price at any establishment.
  void _merchantSignals(
    List<ConsumptionSignal> out,
    String productId,
    String scopeId,
    List<ProductPriceObservation> history,
    ConsumptionEvidenceQuality quality,
  ) {
    final last = history.last;
    final groups = <String, List<ProductPriceObservation>>{};
    for (final observation in history) {
      final merchantId = observation.merchantId?.trim();
      if (merchantId == null || merchantId.isEmpty) {
        continue;
      }
      groups.putIfAbsent(merchantId, () => []).add(observation);
    }
    if (groups.length < 2) {
      return;
    }
    final generalBaseline =
        history
            .map((observation) => observation.unitPrice)
            .reduce((a, b) => a + b) /
        history.length;
    final merchantMeans = <String, double>{};
    for (final entry in groups.entries) {
      if (entry.value.length < policy.minimumMerchantObservations) {
        continue;
      }
      merchantMeans[entry.key] =
          entry.value
              .map((observation) => observation.unitPrice)
              .reduce((a, b) => a + b) /
          entry.value.length;
    }
    if (merchantMeans.length < 2) {
      return;
    }
    for (final entry in merchantMeans.entries) {
      final difference = entry.value - generalBaseline;
      final percentage = difference / generalBaseline;
      if (!_relevant(difference, percentage)) {
        continue;
      }
      out.add(
        _signal(
          ConsumptionSignalType.merchantPricePattern,
          productId,
          scopeId,
          groups[entry.key]!.last.purchasedAt,
          entry.value,
          generalBaseline,
          quality,
          groups[entry.key]!.length,
          difference,
          percentage,
          entry.key,
          factIds: groups[entry.key]!
              .map((observation) => observation.id)
              .toList(),
        ),
      );
    }
    final candidates =
        merchantMeans.entries
            .where((entry) => entry.key != last.merchantId)
            .where(
              (entry) => _relevant(
                last.unitPrice - entry.value,
                (last.unitPrice - entry.value) / entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));
    if (candidates.isEmpty) {
      return;
    }
    final best = candidates.first;
    final difference = last.unitPrice - best.value;
    out.add(
      _signal(
        ConsumptionSignalType.betterPriceAtOtherMerchant,
        productId,
        scopeId,
        last.purchasedAt,
        last.unitPrice,
        best.value,
        quality,
        groups[best.key]!.length,
        difference,
        difference / best.value,
        best.key,
        factIds: [
          last.id,
          ...groups[best.key]!.map((observation) => observation.id),
        ],
      ),
    );
  }

  void _earlyRepurchaseSignal(
    List<ConsumptionSignal> out,
    String productId,
    String scopeId,
    List<ProductPriceObservation> history,
    ConsumptionEvidenceQuality quality,
  ) {
    if (history.length <= policy.minimumObservations) {
      return;
    }
    final last = history.last;
    final prior = const ProductPurchaseMetricsCalculator().calculate(
      productId: productId,
      observations: history.sublist(0, history.length - 1),
    );
    final recurrence = prior.probableRecurrence;
    final priorQuality = _quality(prior);
    if (recurrence == null ||
        priorQuality.index < ConsumptionEvidenceQuality.moderate.index) {
      return;
    }
    final tolerance = Duration(
      microseconds:
          (recurrence.averageInterval.inMicroseconds *
                  policy.repurchaseTolerance)
              .round(),
    );
    final lowerBound = recurrence.nextExpectedPurchaseAt.subtract(tolerance);
    if (!last.purchasedAt.isBefore(lowerBound)) {
      return;
    }
    final difference = lowerBound
        .difference(last.purchasedAt)
        .inMicroseconds
        .toDouble();
    out.add(
      _signal(
        ConsumptionSignalType.repurchaseEarly,
        productId,
        scopeId,
        last.purchasedAt,
        last.purchasedAt.millisecondsSinceEpoch.toDouble(),
        lowerBound.millisecondsSinceEpoch.toDouble(),
        priorQuality,
        history.length,
        difference,
        difference / recurrence.averageInterval.inMicroseconds,
        last.merchantId,
        factIds: [last.id],
      ),
    );
  }

  void _priceAndQuantitySignal(
    List<ConsumptionSignal> out,
    String productId,
    String scopeId,
    List<ProductPriceObservation> history,
    ConsumptionEvidenceQuality quality,
  ) {
    final last = history.last;
    final priceSignal = out.lastOrNullWhere(
      (signal) =>
          (signal.type == ConsumptionSignalType.priceAboveUsual ||
              signal.type == ConsumptionSignalType.priceBelowUsual) &&
          signal.observedAt == last.purchasedAt,
    );
    final quantitySignal = out.lastOrNullWhere(
      (signal) =>
          (signal.type == ConsumptionSignalType.quantityAboveUsual ||
              signal.type == ConsumptionSignalType.quantityBelowUsual) &&
          signal.observedAt == last.purchasedAt,
    );
    if (priceSignal == null || quantitySignal == null) {
      return;
    }
    out.add(
      _signal(
        ConsumptionSignalType.priceAndQuantityChanged,
        productId,
        scopeId,
        last.purchasedAt,
        last.unitPrice,
        priceSignal.baselineValue,
        quality,
        history.length,
        priceSignal.absoluteDifference,
        priceSignal.percentageDifference,
        last.merchantId,
        factIds: [last.id],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get lastOrNull => isEmpty ? null : last;

  T? lastOrNullWhere(bool Function(T) test) {
    T? result;
    for (final item in this) {
      if (test(item)) {
        result = item;
      }
    }
    return result;
  }
}
