import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addTransaction(TransactionModel transaction) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Usuário não autenticado.");
    }

    await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("transactions")
        .doc(transaction.id)
        .set(transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactions() async {
    final user = _auth.currentUser;

    if (user == null) {
      return [];
    }

    final snapshot = await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("transactions")
        .orderBy("date", descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data()))
        .toList();
  }
}