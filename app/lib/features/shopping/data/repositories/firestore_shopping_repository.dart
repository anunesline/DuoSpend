import '../../domain/models/shopping_item_model.dart';
import '../../domain/repositories/shopping_repository.dart';
import '../mappers/shopping_item_mapper.dart';
import '../models/shopping_item_entity.dart';

class FirestoreShoppingRepository implements ShoppingRepository {
  final List<ShoppingItemEntity> _items = [];

  @override
  Future<void> createItem(ShoppingItemModel item) async {
    final entity = ShoppingItemMapper.toEntity(item);
    _items.add(entity);
  }

  @override
  Future<void> updateItem(ShoppingItemModel item) async {
    final entity = ShoppingItemMapper.toEntity(item);
    final index = _items.indexWhere((savedItem) => savedItem.id == item.id);

    if (index == -1) {
      return;
    }

    _items[index] = entity;
  }

  @override
  Future<void> deleteItem(String itemId) async {
    _items.removeWhere((item) => item.id == itemId);
  }

  @override
  Future<ShoppingItemModel?> getItemById(String itemId) async {
    final matches = _items.where((item) => item.id == itemId);

    if (matches.isEmpty) {
      return null;
    }

    return ShoppingItemMapper.toModel(matches.first);
  }

  @override
  Future<List<ShoppingItemModel>> getAllItems() async {
    return ShoppingItemMapper.toModelList(_items);
  }

  @override
  Future<List<ShoppingItemModel>> getPendingItems() async {
    final pendingItems = _items.where((item) => item.status == 'pending');

    return ShoppingItemMapper.toModelList(pendingItems.toList());
  }

  @override
  Future<List<ShoppingItemModel>> getPurchasedItems() async {
    final purchasedItems = _items.where((item) => item.status == 'purchased');

    return ShoppingItemMapper.toModelList(purchasedItems.toList());
  }

  @override
  Future<void> markAsPurchased(String itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);

    if (index == -1) {
      return;
    }

    final currentItem = ShoppingItemMapper.toModel(_items[index]);
    final purchasedItem = currentItem.markAsPurchased();

    _items[index] = ShoppingItemMapper.toEntity(purchasedItem);
  }

  @override
  Future<void> archiveItem(String itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);

    if (index == -1) {
      return;
    }

    final currentItem = ShoppingItemMapper.toModel(_items[index]);
    final archivedItem = currentItem.archive();

    _items[index] = ShoppingItemMapper.toEntity(archivedItem);
  }

  @override
  Future<List<ShoppingItemModel>> getSuggestions() async {
    return [];
  }

  @override
  Future<List<ShoppingItemModel>> search(String query) async {
    final normalizedQuery = query.trim().toLowerCase();

    final results = _items.where((item) {
      return item.normalizedName.contains(normalizedQuery) ||
          item.name.toLowerCase().contains(normalizedQuery);
    });

    return ShoppingItemMapper.toModelList(results.toList());
  }

  @override
  Future<void> clearArchive() async {
    _items.removeWhere((item) => item.status == 'archived');
  }
}