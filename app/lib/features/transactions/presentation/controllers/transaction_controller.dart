import 'package:flutter/foundation.dart';

import '../../../home/data/repositories/wallet_repository.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

class TransactionController extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();
  final WalletRepository _walletRepository = WalletRepository();

  final List<TransactionItemModel> _items = [];

  List<TransactionItemModel> get items => List.unmodifiable(_items);

  void addItem(TransactionItemModel item) {
    _items.add(item);
    notifyListeners();
  }

  void updateItem({
    required String originalItemId,
    required TransactionItemModel updatedItem,
  }) {
    final index = _items.indexWhere(
      (item) => item.id == originalItemId,
    );

    if (index == -1) {
      return;
    }

    _items[index] = updatedItem;
    notifyListeners();
  }

  void removeItem(TransactionItemModel item) {
    _items.removeWhere(
      (currentItem) => currentItem.id == item.id,
    );

    notifyListeners();
  }

  void clearItems() {
    _items.clear();
    notifyListeners();
  }

  Future<void> saveTransaction({
    required String transactionId,
    required String description,
    required double value,
    required String type,
    required String walletId,
    String? consumerId,
    required String category,
    required String subcategory,
    required String paidByMemberId,
    required String purchaseFor,
    required String splitType,
    required Map<String, double> memberShares,
  }) async {
    final wallet = await _walletRepository.getMainWallet();
    final resolvedWalletId = wallet?.id ?? walletId;

    final transaction = TransactionModel(
      id: transactionId,
      description: description,
      value: value,
      type: type,
      date: DateTime.now(),
      walletId: resolvedWalletId,
      consumerId: consumerId,
      category: category,
      subcategory: subcategory,
      paidByMemberId: paidByMemberId,
      purchaseFor: purchaseFor,
      splitType: splitType,
      memberShares: memberShares,
      items: _items
          .map(
            (item) => item.copyWith(
              transactionId: transactionId,
            ),
          )
          .toList(),
    );

    await _repository.addTransaction(transaction);

    if (wallet != null) {
      double newBalance = wallet.balance;

      if (type == 'income') {
        newBalance += value;
      } else {
        newBalance -= value;
      }

      await _walletRepository.updateBalance(newBalance);
    }

    clearItems();
  }
}