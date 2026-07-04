import '../repositories/purchase_repository.dart';

class DeletePurchaseUseCase {
  final PurchaseRepository _purchaseRepository;

  const DeletePurchaseUseCase({
    required PurchaseRepository purchaseRepository,
  }) : _purchaseRepository = purchaseRepository;

  Future<void> call(String purchaseId) async {
    if (purchaseId.trim().isEmpty) {
      throw Exception('Informe a compra que será excluída.');
    }

    await _purchaseRepository.deletePurchase(purchaseId);
  }
}