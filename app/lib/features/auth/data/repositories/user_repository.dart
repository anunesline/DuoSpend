import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../home/data/models/wallet_model.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

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

      await doc.collection('wallets').doc(wallet.id).set(wallet.toMap());
    }
  }

  Future<String?> getUserDisplayName(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return null;
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(normalizedUserId)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    final data = snapshot.data()!;

    final displayName = _readNonEmptyString(
      data['displayName'],
    );

    if (displayName != null) {
      return displayName;
    }

    final name = _readNonEmptyString(
      data['name'],
    );

    if (name != null) {
      return name;
    }

    final email = _readNonEmptyString(
      data['email'],
    );

    return email;
  }

  String? _readNonEmptyString(
    Object? value,
  ) {
    final normalizedValue = value?.toString().trim();

    if (normalizedValue == null || normalizedValue.isEmpty) {
      return null;
    }

    return normalizedValue;
  }
}