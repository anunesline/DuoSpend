import '../models/purchase_model.dart';
import '../repositories/purchase_repository.dart';

class GetPurchaseByIdUseCase {
  final PurchaseRepository _purchaseRepository;

  const GetPurchaseByIdUseCase({
    required PurchaseRepository purchaseRepository,
  }) : _purchaseRepository = purchaseRepository;

  Future<PurchaseModel?> call(String purchaseId) async {
    if (purchaseId.trim().isEmpty) {
      throw Exception('Informe a compra que será buscada.');
    }

    return _purchaseRepository.getPurchaseById(purchaseId);
  }
}