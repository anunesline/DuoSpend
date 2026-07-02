import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/wallet_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    final doc = _firestore.collection('users').doc(user.uid);

    final snapshot = await doc.get();

    if (!snapshot.exists) {
      await doc.set(user.toMap());

      final wallet = WalletModel(
        id: 'principal',
        name: 'Carteira Principal',
        balance: 0,
      );

      await doc
          .collection('wallets')
          .doc(wallet.id)
          .set(wallet.toMap());
    }
  }
}