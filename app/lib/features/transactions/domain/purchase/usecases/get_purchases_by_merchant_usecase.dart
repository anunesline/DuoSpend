import '../models/purchase_model.dart';
import '../repositories/purchase_repository.dart';

class GetPurchasesByMerchantUseCase {
  final PurchaseRepository _purchaseRepository;

  const GetPurchasesByMerchantUseCase({
    required PurchaseRepository purchaseRepository,
  }) : _purchaseRepository = purchaseRepository;

  Future<List<PurchaseModel>> call(String merchantId) async {
    if (merchantId.trim().isEmpty) {
      throw Exception('Informe o estabelecimento para buscar as compras.');
    }

    return _purchaseRepository.getPurchasesByMerchant(merchantId);
  }
}