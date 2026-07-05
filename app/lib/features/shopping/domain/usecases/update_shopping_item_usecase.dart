import '../models/shopping_item_model.dart';
import '../repositories/shopping_repository.dart';

class UpdateShoppingItemUseCase {
  final ShoppingRepository repository;

  const UpdateShoppingItemUseCase(this.repository);

  Future<void> call(ShoppingItemModel item) async {
    await repository.updateItem(item);
  }
}