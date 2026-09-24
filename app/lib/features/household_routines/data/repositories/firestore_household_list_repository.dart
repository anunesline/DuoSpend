import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/household_list.dart';
import '../../domain/models/household_list_item.dart';
import '../../domain/repositories/household_list_repository.dart';

class FirestoreHouseholdListRepository implements HouseholdListRepository {
  final FirebaseFirestore firestore;

  FirestoreHouseholdListRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _lists =>
      firestore.collection('household_lists');
  CollectionReference<Map<String, dynamic>> get _items =>
      firestore.collection('household_list_items');
  CollectionReference<Map<String, dynamic>> get _events =>
      firestore.collection('household_list_purchase_events');

  @override
  Future<void> saveList(HouseholdList list) =>
      _lists.doc(list.id).set(list.toMap());

  @override
  Future<HouseholdList?> getListById(String listId) async {
    final snapshot = await _lists.doc(listId).get();
    final data = snapshot.data();
    return !snapshot.exists || data == null ? null : HouseholdList.fromMap(data);
  }

  @override
  Future<List<HouseholdList>> getListsByScope(
    String scopeId, {
    bool includeArchived = false,
  }) async {
    final snapshot = await _lists.where('scopeId', isEqualTo: scopeId).get();
    final lists = snapshot.docs.map((doc) => HouseholdList.fromMap(doc.data()));
    final filtered = includeArchived
        ? lists
        : lists.where((list) => list.isActive);
    return filtered.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<void> deleteList(String listId) => _lists.doc(listId).delete();

  @override
  Future<void> saveItem(HouseholdListItem item) =>
      _items.doc(item.id).set(item.toMap());

  @override
  Future<void> deleteItem(String itemId) => _items.doc(itemId).delete();

  @override
  Future<List<HouseholdListItem>> getItemsByList(String listId) async {
    final snapshot = await _items.where('listId', isEqualTo: listId).get();
    final items = snapshot.docs
        .map((doc) => HouseholdListItem.fromMap(doc.data()))
        .toList();
    items.sort((a, b) {
      if (a.isPurchased != b.isPurchased) return a.isPurchased ? 1 : -1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return items;
  }

  @override
  Future<void> markItemPurchased({
    required HouseholdListItem item,
    required HouseholdListItemPurchaseEvent event,
  }) async {
    final batch = firestore.batch();
    batch.set(_items.doc(item.id), item.toMap());
    batch.set(_events.doc(event.id), event.toMap());
    await batch.commit();
  }

  @override
  Future<bool> markItemPurchasedFromFinancialTransaction({
    required HouseholdListItem item,
    required HouseholdListItemPurchaseEvent event,
  }) =>
      firestore.runTransaction((transaction) async {
        final itemReference = _items.doc(item.id);
        final eventReference = _events.doc(event.id);
        final itemSnapshot = await transaction.get(itemReference);
        final data = itemSnapshot.data();
        if (!itemSnapshot.exists || data == null) return false;
        final persistedItem = HouseholdListItem.fromMap(data);
        if (persistedItem.isPurchased ||
            persistedItem.financialReferenceId == event.sourceReferenceId) {
          return false;
        }

        transaction.set(itemReference, item.toMap());
        transaction.set(eventReference, event.toMap());
        return true;
      });

  @override
  Future<List<HouseholdListItemPurchaseEvent>> getPurchaseEvents({
    required String scopeId,
    String? identityKey,
  }) async {
    final snapshot = await _events.where('scopeId', isEqualTo: scopeId).get();
    final events = snapshot.docs
        .map((doc) => HouseholdListItemPurchaseEvent.fromMap(doc.data()))
        .where((event) => identityKey == null || event.identityKey == identityKey)
        .toList()
      ..sort((a, b) => a.purchasedAt.compareTo(b.purchasedAt));
    return events;
  }

  @override
  Future<List<HouseholdListItemPurchaseEvent>> getPurchaseEventsByList({
    required String scopeId,
    required String listId,
  }) async {
    final events = await getPurchaseEvents(scopeId: scopeId);
    return events.where((event) => event.listId == listId).toList()
      ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
  }
}
