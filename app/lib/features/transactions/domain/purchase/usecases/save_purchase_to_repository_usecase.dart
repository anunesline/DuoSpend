import '../models/purchase_model.dart';
import '../repositories/purchase_repository.dart';

class SavePurchaseToRepositoryUseCase {
  final PurchaseRepository _purchaseRepository;

  const SavePurchaseToRepositoryUseCase({
    required PurchaseRepository purchaseRepository,
  }) : _purchaseRepository = purchaseRepository;

  Future<void> call(PurchaseModel purchase) async {
    _validatePurchase(purchase);

    await _purchaseRepository.savePurchase(purchase);
  }

  void _validatePurchase(PurchaseModel purchase) {
    if (purchase.id.trim().isEmpty) {
      throw Exception('A compra precisa ter um ID.');
    }

    if (purchase.userId.trim().isEmpty) {
      throw Exception('A compra precisa estar vinculada a um usuário.');
    }

    if (purchase.walletId.trim().isEmpty) {
      throw Exception('A compra precisa estar vinculada a uma carteira.');
    }

    if (purchase.items.isEmpty) {
      throw Exception('Adicione pelo menos um produto à compra.');
    }

    if (purchase.total <= 0) {
      throw Exception('O total da compra deve ser maior que zero.');
    }
  }
}