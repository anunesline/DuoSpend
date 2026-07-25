import '../../../merchants/domain/merchant_model.dart';
import '../../../transactions/data/models/transaction_item_model.dart';

abstract class PurchaseService {
  Future<void> savePurchase({
    required String walletId,
    String? consumerId,
    String? purchaseDestination,
    String? splitType,
    Map<String, double>? customShares,
    required MerchantModel merchant,
    required double totalValue,
    required String financialCategory,
    required String financialSubcategory,
    required List<TransactionItemModel> items,
  });
}