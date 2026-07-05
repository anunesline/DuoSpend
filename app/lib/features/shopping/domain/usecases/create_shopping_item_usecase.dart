import '../models/shopping_item_model.dart';
import '../repositories/shopping_repository.dart';

class CreateShoppingItemUseCase {
  final ShoppingRepository repository;

  const CreateShoppingItemUseCase(this.repository);

  Future<void> call(ShoppingItemModel item) async {
    await repository.createItem(item);
  }
}