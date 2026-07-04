import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/purchase/models/purchase_model.dart';
import '../../domain/purchase/repositories/purchase_repository.dart';

class FirebasePurchaseRepository implements PurchaseRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebasePurchaseRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _purchasesCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('purchases');
  }

  String _getCurrentUserIdOrThrow() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    return user.uid;
  }

  @override
  Future<void> savePurchase(PurchaseModel purchase) async {
    final userId = _getCurrentUserIdOrThrow();

    await _purchasesCollection(userId).doc(purchase.id).set(purchase.toMap());
  }

  @override
  Future<PurchaseModel?> getPurchaseById(String purchaseId) async {
    final userId = _getCurrentUserIdOrThrow();

    final document =
        await _purchasesCollection(userId).doc(purchaseId).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return PurchaseModel.fromMap(document.data()!);
  }

  @override
  Future<List<PurchaseModel>> getPurchasesByWallet(String walletId) async {
    final userId = _getCurrentUserIdOrThrow();

    final snapshot = await _purchasesCollection(userId)
        .where('walletId', isEqualTo: walletId)
        .orderBy('purchaseDate', descending: true)
        .get();

    return snapshot.docs
        .map((document) => PurchaseModel.fromMap(document.data()))
        .toList();
  }

  @override
  Future<List<PurchaseModel>> getPurchasesByMerchant(String merchantId) async {
    final userId = _getCurrentUserIdOrThrow();

    final snapshot = await _purchasesCollection(userId)
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('purchaseDate', descending: true)
        .get();

    return snapshot.docs
        .map((document) => PurchaseModel.fromMap(document.data()))
        .toList();
  }

  @override
  Future<List<PurchaseModel>> getPurchasesByDateRange({
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = _getCurrentUserIdOrThrow();

    final snapshot = await _purchasesCollection(userId)
        .where('walletId', isEqualTo: walletId)
        .where(
          'purchaseDate',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        )
        .where(
          'purchaseDate',
          isLessThanOrEqualTo: endDate.toIso8601String(),
        )
        .orderBy('purchaseDate', descending: true)
        .get();

    return snapshot.docs
        .map((document) => PurchaseModel.fromMap(document.data()))
        .toList();
  }

  @override
  Future<void> deletePurchase(String purchaseId) async {
    final userId = _getCurrentUserIdOrThrow();

    await _purchasesCollection(userId).doc(purchaseId).delete();
  }
}