import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/wallet_model.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';

class HomeController extends ChangeNotifier {
  final WalletRepository _walletRepository = WalletRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();

  User? user;
  WalletModel? wallet;
  List<TransactionModel> transactions = [];

  double totalIncome = 0;
  double totalExpense = 0;

  bool isLoading = true;

  String get userName {
    final name = user?.displayName?.trim();

    if (name == null || name.isEmpty) {
      return 'usuário';
    }

    return name.split(' ').first;
  }

  String? get userPhotoUrl => user?.photoURL;

  Future<void> loadHome() async {
    isLoading = true;
    notifyListeners();

    user = FirebaseAuth.instance.currentUser;
    wallet = await _walletRepository.getMainWallet();
    transactions = await _transactionRepository.getTransactions();

    totalIncome = 0;
    totalExpense = 0;

    for (final transaction in transactions) {
      if (transaction.type == 'income') {
        totalIncome += transaction.value;
      } else {
        totalExpense += transaction.value;
      }
    }

    isLoading = false;
    notifyListeners();
  }
}