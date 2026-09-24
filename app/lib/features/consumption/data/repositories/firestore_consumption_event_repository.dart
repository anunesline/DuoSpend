import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/consumption_event.dart';
import '../../domain/repositories/consumption_event_repository.dart';

class FirestoreConsumptionEventRepository
    implements ConsumptionEventRepository {
  FirestoreConsumptionEventRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('consumption_events');

  @override
  Future<void> record(ConsumptionEvent event) async {
    final eventId = event.id.trim();
    if (eventId.isEmpty || event.productId.trim().isEmpty) {
      throw ArgumentError('Evento de consumo precisa de id e productId.');
    }

    final reference = _events.doc(eventId);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) return;
      transaction.set(reference, event.toMap());
    });
  }

  @override
  Future<ConsumptionEvent?> getById(String eventId) async {
    final snapshot = await _events.doc(eventId.trim()).get();
    final data = snapshot.data();
    return !snapshot.exists || data == null
        ? null
        : ConsumptionEvent.fromMap(data);
  }

  @override
  Future<List<ConsumptionEvent>> getByScope({
    required String scopeId,
    DateTime? from,
    DateTime? until,
    bool includeInactive = false,
  }) async {
    final snapshot = await _events
        .where('scopeId', isEqualTo: scopeId.trim())
        .get();
    return _filterAndSort(
      snapshot.docs.map(
        (document) => ConsumptionEvent.fromMap(document.data()),
      ),
      from: from,
      until: until,
      includeInactive: includeInactive,
    );
  }

  @override
  Future<List<ConsumptionEvent>> getByProduct({
    required String productId,
    DateTime? from,
    DateTime? until,
    bool includeInactive = false,
  }) async {
    final snapshot = await _events
        .where('productId', isEqualTo: productId.trim())
        .get();
    return _filterAndSort(
      snapshot.docs.map(
        (document) => ConsumptionEvent.fromMap(document.data()),
      ),
      from: from,
      until: until,
      includeInactive: includeInactive,
    );
  }

  @override
  Future<List<ConsumptionEvent>> getByScopeAndProduct({
    required String scopeId,
    required String productId,
    DateTime? from,
    DateTime? until,
    bool includeInactive = false,
  }) async {
    final events = await getByScope(
      scopeId: scopeId,
      from: from,
      until: until,
      includeInactive: includeInactive,
    );
    return events
        .where((event) => event.productId == productId.trim())
        .toList();
  }

  @override
  Future<void> invalidate({
    required String eventId,
    required DateTime invalidatedAt,
    String? invalidatedByUserId,
    String? reason,
  }) async {
    final reference = _events.doc(eventId.trim());
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw StateError('Evento de consumo não encontrado.');
      }
      final event = ConsumptionEvent.fromMap(data);
      if (!event.isActive) return;
      transaction.update(
        reference,
        event
            .invalidate(
              at: invalidatedAt,
              byUserId: invalidatedByUserId,
              reason: reason,
            )
            .toMap(),
      );
    });
  }

  List<ConsumptionEvent> _filterAndSort(
    Iterable<ConsumptionEvent> events, {
    required DateTime? from,
    required DateTime? until,
    required bool includeInactive,
  }) {
    final filtered =
        events.where((event) {
          if (!includeInactive && !event.isActive) return false;
          if (from != null && event.occurredAt.isBefore(from)) return false;
          if (until != null && event.occurredAt.isAfter(until)) return false;
          return true;
        }).toList()..sort((first, second) {
          final date = first.occurredAt.compareTo(second.occurredAt);
          return date == 0 ? first.id.compareTo(second.id) : date;
        });
    return List.unmodifiable(filtered);
  }
}
