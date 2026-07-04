import '../models/purchase_model.dart';
import '../repositories/purchase_repository.dart';

class GetPurchasesByWalletUseCase {
  final PurchaseRepository _purchaseRepository;

  const GetPurchasesByWalletUseCase({
    required PurchaseRepository purchaseRepository,
  }) : _purchaseRepository = purchaseRepository;

  Future<List<PurchaseModel>> call(String walletId) async {
    if (walletId.trim().isEmpty) {
      throw Exception('Informe a carteira para buscar as compras.');
    }

    return _purchaseRepository.getPurchasesByWallet(walletId);
  }
}