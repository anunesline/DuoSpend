import '../models/purchase_model.dart';

abstract class PurchaseRepository {
  Future<void> savePurchase(PurchaseModel purchase);

  Future<PurchaseModel?> getPurchaseById(String purchaseId);

  Future<List<PurchaseModel>> getPurchasesByWallet(String walletId);

  Future<List<PurchaseModel>> getPurchasesByMerchant(String merchantId);

  Future<List<PurchaseModel>> getPurchasesByDateRange({
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> deletePurchase(String purchaseId);
}