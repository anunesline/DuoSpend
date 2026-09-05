import '../models/household_list.dart';
import '../models/household_list_item.dart';

abstract class HouseholdListRepository {
  Future<void> saveList(HouseholdList list);
  Future<HouseholdList?> getListById(String listId);
  Future<List<HouseholdList>> getListsByScope(
    String scopeId, {
    bool includeArchived = false,
  });
  Future<void> deleteList(String listId);

  Future<void> saveItem(HouseholdListItem item);
  Future<void> deleteItem(String itemId);
  Future<List<HouseholdListItem>> getItemsByList(String listId);
  Future<void> markItemPurchased({
    required HouseholdListItem item,
    required HouseholdListItemPurchaseEvent event,
  });
  Future<bool> markItemPurchasedFromFinancialTransaction({
    required HouseholdListItem item,
    required HouseholdListItemPurchaseEvent event,
  });
  Future<List<HouseholdListItemPurchaseEvent>> getPurchaseEvents({
    required String scopeId,
    String? identityKey,
  });
}
