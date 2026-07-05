import '../repositories/shopping_repository.dart';

class MarkShoppingItemAsPurchasedUseCase {
  final ShoppingRepository repository;

  const MarkShoppingItemAsPurchasedUseCase(this.repository);

  Future<void> call(String itemId) async {
    await repository.markAsPurchased(itemId);
  }
}