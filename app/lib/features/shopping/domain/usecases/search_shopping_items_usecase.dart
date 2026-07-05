import '../models/shopping_item_model.dart';
import '../repositories/shopping_repository.dart';

class SearchShoppingItemsUseCase {
  final ShoppingRepository repository;

  const SearchShoppingItemsUseCase(this.repository);

  Future<List<ShoppingItemModel>> call(String query) async {
    return repository.search(query);
  }
}