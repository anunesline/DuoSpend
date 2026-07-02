import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';
import 'wallet_repository.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WalletRepository _walletRepository = WalletRepository();

  Future<void> addTransaction(TransactionModel transaction) async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toMap());

    final wallet =
        await _walletRepository.getMainWallet();

    if (wallet == null) return;

    double newBalance = wallet.balance;

    if (transaction.type == "income") {
      newBalance += transaction.value;
    } else {
      newBalance -= transaction.value;
    }

    await _walletRepository.updateBalance(newBalance);
  }

  Future<List<TransactionModel>> getTransactions() async {
    final user = _auth.currentUser;

    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy("date", descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data()))
        .toList();
  }
}