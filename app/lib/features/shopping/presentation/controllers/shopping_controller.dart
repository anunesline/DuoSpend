import '../../domain/models/shopping_item_model.dart';
import '../../domain/services/shopping_flow_service.dart';

class ShoppingController {
  final ShoppingFlowService flow;

  const ShoppingController(this.flow);

  Future<void> createItem(ShoppingItemModel item) async {
    await flow.createItem(item);
  }

  Future<void> createItemFromNameForTest(String name) async {
    final now = DateTime.now();
    final normalizedName = name.trim().toLowerCase();

    final item = ShoppingItemModel.create(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      normalizedName: normalizedName,
      quantity: 1,
      unit: 'un',
      source: ShoppingItemSource.manual,
      priority: ShoppingItemPriority.normal,
      isShared: false,
      now: now,
    );

    await createItem(item);
  }

  Future<void> updateItem(ShoppingItemModel item) async {
    await flow.updateItem(item);
  }

  Future<void> deleteItem(String itemId) async {
    await flow.deleteItem(itemId);
  }

  Future<void> markAsPurchased(String itemId) async {
    await flow.markAsPurchased(itemId);
  }

  Future<void> archiveItem(String itemId) async {
    await flow.archiveItem(itemId);
  }

  Future<List<ShoppingItemModel>> loadItems() async {
    return flow.getPendingItems();
  }

  Future<List<ShoppingItemModel>> loadPurchasedItems() async {
    return flow.getPurchasedItems();
  }

  Future<List<ShoppingItemModel>> search(String query) async {
    return flow.search(query);
  }

  Future<List<ShoppingItemModel>> loadSuggestions() async {
    return flow.getSuggestions();
  }
}