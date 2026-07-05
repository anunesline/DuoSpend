import '../models/shopping_item_model.dart';
import '../usecases/archive_shopping_item_usecase.dart';
import '../usecases/create_shopping_item_usecase.dart';
import '../usecases/delete_shopping_item_usecase.dart';
import '../usecases/get_all_shopping_items_usecase.dart';
import '../usecases/get_pending_shopping_items_usecase.dart';
import '../usecases/get_purchased_shopping_items_usecase.dart';
import '../usecases/get_shopping_suggestions_usecase.dart';
import '../usecases/mark_shopping_item_as_purchased_usecase.dart';
import '../usecases/process_product_intelligence_usecase.dart';
import '../usecases/search_shopping_items_usecase.dart';
import '../usecases/update_shopping_item_usecase.dart';

class ShoppingFlowService {
  final CreateShoppingItemUseCase createShoppingItem;
  final UpdateShoppingItemUseCase updateShoppingItem;
  final DeleteShoppingItemUseCase deleteShoppingItem;
  final GetAllShoppingItemsUseCase getAllShoppingItems;
  final GetPendingShoppingItemsUseCase getPendingShoppingItems;
  final GetPurchasedShoppingItemsUseCase getPurchasedShoppingItems;
  final MarkShoppingItemAsPurchasedUseCase markShoppingItemAsPurchased;
  final ArchiveShoppingItemUseCase archiveShoppingItem;
  final SearchShoppingItemsUseCase searchShoppingItems;
  final GetShoppingSuggestionsUseCase getShoppingSuggestions;
  final ProcessProductIntelligenceUseCase processProductIntelligence;

  const ShoppingFlowService({
    required this.createShoppingItem,
    required this.updateShoppingItem,
    required this.deleteShoppingItem,
    required this.getAllShoppingItems,
    required this.getPendingShoppingItems,
    required this.getPurchasedShoppingItems,
    required this.markShoppingItemAsPurchased,
    required this.archiveShoppingItem,
    required this.searchShoppingItems,
    required this.getShoppingSuggestions,
    required this.processProductIntelligence,
  });

  Future<void> createItem(ShoppingItemModel item) async {
    final normalizedItem = await _normalizeItem(item);
    await createShoppingItem(normalizedItem);
  }

  Future<void> updateItem(ShoppingItemModel item) async {
    final normalizedItem = await _normalizeItem(item);
    await updateShoppingItem(normalizedItem);
  }

  Future<void> deleteItem(String itemId) async {
    await deleteShoppingItem(itemId);
  }

  Future<List<ShoppingItemModel>> getAllItems() async {
    return getAllShoppingItems();
  }

  Future<List<ShoppingItemModel>> getPendingItems() async {
    return getPendingShoppingItems();
  }

  Future<List<ShoppingItemModel>> getPurchasedItems() async {
    return getPurchasedShoppingItems();
  }

  Future<void> markAsPurchased(String itemId) async {
    await markShoppingItemAsPurchased(itemId);
  }

  Future<void> archiveItem(String itemId) async {
    await archiveShoppingItem(itemId);
  }

  Future<List<ShoppingItemModel>> search(String query) async {
    final normalizedQuery = await _normalizeQuery(query);

    if (normalizedQuery.isEmpty) {
      return getPendingItems();
    }

    return searchShoppingItems(normalizedQuery);
  }

  Future<List<ShoppingItemModel>> getSuggestions() async {
    return getShoppingSuggestions();
  }

  Future<ShoppingItemModel> _normalizeItem(ShoppingItemModel item) async {
    final trimmedName = item.name.trim();
    final normalizedName = await _normalizeProductName(trimmedName);

    return item.copyWith(
      name: trimmedName,
      normalizedName: normalizedName,
      quantity: item.quantity <= 0 ? 1 : item.quantity,
      unit: item.unit.trim().isEmpty ? 'un' : item.unit.trim(),
      updatedAt: DateTime.now(),
    );
  }

  Future<String> _normalizeQuery(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return '';
    }

    return _normalizeProductName(trimmedQuery);
  }

  Future<String> _normalizeProductName(String value) async {
    final result = await processProductIntelligence(value);

    final identityName = result.match.identity?.canonicalName;

    return (identityName ?? result.classification.canonicalName)
        .trim()
        .toLowerCase();
  }
}