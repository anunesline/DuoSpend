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

  void removeItem(TransactionItemModel item) {
    _items.removeWhere((currentItem) => currentItem.id == item.id);
    notifyListeners();
  }

  void clearItems() {
    _items.clear();
    notifyListeners();
  }

  Future<String> saveTransaction({
    String? transactionId,
    required String description,
    required double value,
    required String type,
    required String category,
    required String subcategory,
  }) async {
    final wallet = await _walletRepository.getMainWallet();
    final id = transactionId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final transaction = TransactionModel(
      id: id,
      description: description,
      value: value,
      type: type,
      date: DateTime.now(),
      walletId: 'principal',
      category: category,
      subcategory: subcategory,
      items: _items.map((item) => item.copyWith(transactionId: id)).toList(),
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
    notifyListeners();

    return id;
  }
}