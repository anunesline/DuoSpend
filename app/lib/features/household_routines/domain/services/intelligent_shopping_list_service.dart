import 'dart:convert';

import '../models/household_list_item.dart';
import '../repositories/household_list_repository.dart';

/// Adds a known product to one unambiguous active shopping list. It never
/// creates a list silently and uses a stable item ID so retries are harmless.
class IntelligentShoppingListService {
  const IntelligentShoppingListService(this._repository);
  final HouseholdListRepository _repository;

  Future<HouseholdListItem?> addKnownProduct({
    required String scopeId,
    required String productId,
    required String displayName,
    required String addedBy,
    required DateTime at,
  }) async {
    if (scopeId.trim().isEmpty ||
        productId.trim().isEmpty ||
        displayName.trim().isEmpty) {
      return null;
    }
    final lists = (await _repository.getListsByScope(
      scopeId,
    )).where((list) => list.isActive && list.isShopping).toList();
    if (lists.length != 1) return null;
    final list = lists.single;
    final items = await _repository.getItemsByList(list.id);
    final identityKey = HouseholdListItemIdentity.normalize(displayName);
    final existing = items.where(
      (item) =>
          !item.isPurchased &&
          (item.productId?.trim() == productId.trim() ||
              ((item.productId == null || item.productId!.trim().isEmpty) &&
                  item.identityKey == identityKey)),
    );
    if (existing.isNotEmpty) return existing.first;
    final stable = '${list.id}:${productId.trim()}';
    final id = 'intelligent_${base64Url.encode(utf8.encode(stable))}';
    final item = HouseholdListItem(
      id: id,
      listId: list.id,
      scopeId: scopeId,
      displayName: displayName.trim(),
      identityKey: identityKey,
      status: HouseholdListItemStatus.pending,
      createdAt: at,
      createdBy: addedBy.trim().isEmpty ? null : addedBy.trim(),
      updatedAt: at,
      productId: productId.trim(),
    );
    await _repository.saveItem(item);
    return item;
  }
}
