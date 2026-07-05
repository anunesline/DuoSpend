import '../repositories/shopping_repository.dart';

class DeleteShoppingItemUseCase {
  final ShoppingRepository repository;

  const DeleteShoppingItemUseCase(this.repository);

  Future<void> call(String itemId) async {
    await repository.deleteItem(itemId);
  }
}