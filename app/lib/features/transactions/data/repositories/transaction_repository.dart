import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TransactionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> addTransaction(
    TransactionModel transaction,
  ) async {
    final user = _requireAuthenticatedUser();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactions() async {
    final user = _auth.currentUser;

    if (user == null) {
      return [];
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy(
          'date',
          descending: true,
        )
        .get();

    return snapshot.docs
        .map(
          (document) => TransactionModel.fromMap(
            document.data(),
          ),
        )
        .toList();
  }

  Future<List<TransactionModel>> getTransactionsByWallet(
    String walletId,
  ) async {
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      return [];
    }

    final transactions = await getTransactions();

    return List<TransactionModel>.unmodifiable(
      transactions.where(
        (transaction) =>
            transaction.walletId == normalizedWalletId,
      ),
    );
  }

  User _requireAuthenticatedUser() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    return user;
  }
}