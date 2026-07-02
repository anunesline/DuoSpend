import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/wallet_model.dart';

class WalletRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<WalletModel?> getMainWallet() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wallets')
        .doc('principal')
        .get();

    if (!doc.exists) return null;

    return WalletModel.fromMap(doc.data()!);
  }

  Future<void> updateBalance(double balance) async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wallets')
        .doc('principal')
        .update({
      'balance': balance,
    });
  }
}