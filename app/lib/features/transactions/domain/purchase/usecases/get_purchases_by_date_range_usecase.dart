import '../models/purchase_model.dart';
import '../repositories/purchase_repository.dart';

class GetPurchasesByDateRangeUseCase {
  final PurchaseRepository _purchaseRepository;

  const GetPurchasesByDateRangeUseCase({
    required PurchaseRepository purchaseRepository,
  }) : _purchaseRepository = purchaseRepository;

  Future<List<PurchaseModel>> call({
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (walletId.trim().isEmpty) {
      throw Exception('Informe a carteira para buscar as compras.');
    }

    if (endDate.isBefore(startDate)) {
      throw Exception('A data final não pode ser anterior à data inicial.');
    }

    return _purchaseRepository.getPurchasesByDateRange(
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}