import '../models/shopping_item_model.dart';
import '../repositories/shopping_repository.dart';

class GetPurchasedShoppingItemsUseCase {
  final ShoppingRepository repository;

  const GetPurchasedShoppingItemsUseCase(this.repository);

  Future<List<ShoppingItemModel>> call() async {
    return repository.getPurchasedItems();
  }
}