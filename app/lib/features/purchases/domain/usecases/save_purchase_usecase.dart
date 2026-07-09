import '../../../home/data/repositories/wallet_repository.dart';
import '../../../merchants/data/merchant_memory_repository.dart';
import '../../../merchants/domain/merchant_model.dart';
import '../../../transactions/data/models/transaction_item_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../services/purchase_service.dart';

class SavePurchaseUseCase implements PurchaseService {
  SavePurchaseUseCase({
    TransactionRepository? transactionRepository,
    WalletRepository? walletRepository,
    MerchantMemoryRepository? merchantMemoryRepository,
  })  : _transactionRepository =
            transactionRepository ?? TransactionRepository(),
        _walletRepository = walletRepository ?? WalletRepository(),
        _merchantMemoryRepository =
            merchantMemoryRepository ?? MerchantMemoryRepository();

  final TransactionRepository _transactionRepository;
  final WalletRepository _walletRepository;
  final MerchantMemoryRepository _merchantMemoryRepository;

  @override
  Future<void> savePurchase({
    required String walletId,
    String? consumerId,
    required MerchantModel merchant,
    required double totalValue,
    required String financialCategory,
    required String financialSubcategory,
    required List<TransactionItemModel> items,
  }) async {
    final wallet = await _walletRepository.getMainWallet();

    final transactionId = DateTime.now().millisecondsSinceEpoch.toString();

    final transaction = TransactionModel(
      id: transactionId,
      description: merchant.name,
      value: totalValue,
      type: 'expense',
      date: DateTime.now(),
      walletId: wallet?.id ?? walletId,
      consumerId: consumerId,
      category: financialCategory,
      subcategory: financialSubcategory,
      items: items
          .map(
            (item) => item.copyWith(
              transactionId: transactionId,
            ),
          )
          .toList(),
    );

    await _transactionRepository.addTransaction(transaction);

    if (wallet != null) {
      final newBalance = wallet.balance - totalValue;
      await _walletRepository.updateBalance(newBalance);
    }

    await _merchantMemoryRepository.updateAfterPurchase(
      merchantId: merchant.id,
      merchantName: merchant.name,
      purchaseValue: totalValue,
      productNames: items.map((item) => item.name).toList(),
    );
  }
}