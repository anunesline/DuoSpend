import 'package:flutter/foundation.dart';

import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../../home/data/repositories/wallet_repository.dart';

class TransactionController extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();
  final WalletRepository _walletRepository = WalletRepository();

  Future<void> saveTransaction({
    required String description,
    required double value,
    required String type,
  }) async {
    final wallet = await _walletRepository.getMainWallet();

    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      value: value,
      type: type,
      date: DateTime.now(),
      walletId: 'principal',
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

    notifyListeners();
  }
}