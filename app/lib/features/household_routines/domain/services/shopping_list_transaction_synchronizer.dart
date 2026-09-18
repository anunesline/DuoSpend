import 'dart:convert';

import '../../data/repositories/firestore_household_list_repository.dart';
import '../models/household_list_item.dart';
import '../repositories/household_list_repository.dart';

class PurchasedTransactionItem {
  final String id;
  final String displayName;

  const PurchasedTransactionItem({required this.id, required this.displayName});
}

abstract class ShoppingListPurchaseSynchronizer {
  Future<ShoppingListSyncReport> synchronize({
    required String scopeId,
    required String transactionId,
    required DateTime purchasedAt,
    required String? purchasedBy,
    required List<PurchasedTransactionItem> items,
  });
}

class ShoppingListSyncReport {
  final int receivedItems;
  final int matchedItems;
  final int ambiguousItems;

  const ShoppingListSyncReport({
    required this.receivedItems,
    required this.matchedItems,
    required this.ambiguousItems,
  });
}

class ShoppingListTransactionSynchronizer
    implements ShoppingListPurchaseSynchronizer {
  final HouseholdListRepository repository;

  ShoppingListTransactionSynchronizer({HouseholdListRepository? repository})
      : repository = repository ?? FirestoreHouseholdListRepository();

  @override
  Future<ShoppingListSyncReport> synchronize({
    required String scopeId,
    required String transactionId,
    required DateTime purchasedAt,
    required String? purchasedBy,
    required List<PurchasedTransactionItem> items,
  }) async {
    if (scopeId.trim().isEmpty || transactionId.trim().isEmpty || items.isEmpty) {
      return ShoppingListSyncReport(
        receivedItems: items.length,
        matchedItems: 0,
        ambiguousItems: 0,
      );
    }
    final lists = (await repository.getListsByScope(scopeId))
        .where((list) => list.isShopping)
        .toList(growable: false);
    if (lists.isEmpty) {
      return ShoppingListSyncReport(
        receivedItems: items.length,
        matchedItems: 0,
        ambiguousItems: 0,
      );
    }

    final pendingByIdentity = <String, Map<String, List<HouseholdListItem>>>{};
    for (final list in lists) {
      final pending = (await repository.getItemsByList(list.id))
          .where((item) => !item.isPurchased)
          .toList(growable: false);
      for (final item in pending) {
        pendingByIdentity
            .putIfAbsent(item.identityKey, () => {})
            .putIfAbsent(list.id, () => [])
            .add(item);
      }
    }

    var matchedItems = 0;
    var ambiguousItems = 0;
    for (var index = 0; index < items.length; index++) {
      final purchasedItem = items[index];
      final identity = HouseholdListItemIdentity.normalize(
        purchasedItem.displayName,
      );
      if (identity.isEmpty) continue;
      final candidatesByList = pendingByIdentity[identity];
      if (candidatesByList == null) continue;
      if (candidatesByList.length != 1) {
        ambiguousItems++;
        continue;
      }
      final candidates = candidatesByList.values.single;
      if (candidates.isEmpty) continue;
      final item = candidates.removeAt(0);
      final stableItemId = purchasedItem.id.trim().isEmpty
          ? 'position-$index'
          : purchasedItem.id.trim();
      final sourceReferenceId = '$transactionId:$stableItemId';
      final eventId = 'financial_${base64Url.encode(utf8.encode(sourceReferenceId))}';
      final changed = await repository.markItemPurchasedFromFinancialTransaction(
        item: item.markPurchased(
          at: purchasedAt,
          by: purchasedBy,
          financialReferenceId: sourceReferenceId,
        ),
        event: HouseholdListItemPurchaseEvent(
          id: eventId,
          itemId: item.id,
          listId: item.listId,
          scopeId: item.scopeId,
          displayName: item.displayName,
          identityKey: item.identityKey,
          purchasedAt: purchasedAt,
          purchasedBy: purchasedBy,
          source: 'financialTransaction',
          sourceReferenceId: sourceReferenceId,
        ),
      );
      if (changed) matchedItems++;
    }
    return ShoppingListSyncReport(
      receivedItems: items.length,
      matchedItems: matchedItems,
      ambiguousItems: ambiguousItems,
    );
  }
}
