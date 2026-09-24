import '../models/consumption_event.dart';

abstract interface class ConsumptionEventRepository {
  /// Records a factual event. Repeating the same event ID must not replace the
  /// original event, which keeps event recording safe for retrying clients.
  Future<void> record(ConsumptionEvent event);

  Future<ConsumptionEvent?> getById(String eventId);

  Future<List<ConsumptionEvent>> getByScope({
    required String scopeId,
    DateTime? from,
    DateTime? until,
    bool includeInactive = false,
  });

  Future<List<ConsumptionEvent>> getByProduct({
    required String productId,
    DateTime? from,
    DateTime? until,
    bool includeInactive = false,
  });

  Future<List<ConsumptionEvent>> getByScopeAndProduct({
    required String scopeId,
    required String productId,
    DateTime? from,
    DateTime? until,
    bool includeInactive = false,
  });

  /// Keeps the original document and marks it explicitly inactive. A factual
  /// correction is recorded as another event with [supersedesEventId].
  Future<void> invalidate({
    required String eventId,
    required DateTime invalidatedAt,
    String? invalidatedByUserId,
    String? reason,
  });
}
