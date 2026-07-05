import '../repositories/shopping_repository.dart';

class ArchiveShoppingItemUseCase {
  final ShoppingRepository repository;

  const ArchiveShoppingItemUseCase(this.repository);

  Future<void> call(String itemId) async {
    await repository.archiveItem(itemId);
  }
}