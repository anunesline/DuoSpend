import '../models/shopping_item_model.dart';
import '../repositories/shopping_repository.dart';

class GetAllShoppingItemsUseCase {
  final ShoppingRepository repository;

  const GetAllShoppingItemsUseCase(this.repository);

  Future<List<ShoppingItemModel>> call() async {
    return repository.getAllItems();
  }
}