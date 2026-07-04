import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/merchant_memory_model.dart';

class MerchantMemoryRepository {
  MerchantMemoryRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  User? get _currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final user = _currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('merchant_memory');
  }

  Future<List<MerchantMemoryModel>> getAllMemories() async {
    final collection = _collection;

    if (collection == null) {
      return [];
    }

    final snapshot = await collection.get();

    return snapshot.docs
        .map((doc) => MerchantMemoryModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<MerchantMemoryModel>> searchMemories(String query) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return [];
    }

    final memories = await getAllMemories();

    return memories.where((memory) {
      return memory.merchantName.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  Future<MerchantMemoryModel?> getMemoryByMerchantId(
    String merchantId,
  ) async {
    final collection = _collection;

    if (collection == null) {
      return null;
    }

    final doc = await collection.doc(merchantId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return MerchantMemoryModel.fromMap(doc.data()!);
  }

  Future<void> updateAfterPurchase({
    required String merchantId,
    required String merchantName,
    required double purchaseValue,
    required List<String> productNames,
  }) async {
    final collection = _collection;

    if (collection == null) {
      return;
    }

    final currentMemory = await getMemoryByMerchantId(merchantId);

    if (currentMemory == null) {
      final newMemory = MerchantMemoryModel(
        merchantId: merchantId,
        merchantName: merchantName,
        timesVisited: 1,
        totalSpent: purchaseValue,
        averageTicket: purchaseValue,
        lastPurchaseAt: DateTime.now(),
        lastProducts: productNames,
      );

      await collection.doc(merchantId).set(newMemory.toMap());
      return;
    }

    final newTimesVisited = currentMemory.timesVisited + 1;
    final newTotalSpent = currentMemory.totalSpent + purchaseValue;
    final newAverageTicket = newTotalSpent / newTimesVisited;

    final updatedProducts = {
      ...productNames,
      ...currentMemory.lastProducts,
    }.take(20).toList();

    final updatedMemory = currentMemory.copyWith(
      merchantName: merchantName,
      timesVisited: newTimesVisited,
      totalSpent: newTotalSpent,
      averageTicket: newAverageTicket,
      lastPurchaseAt: DateTime.now(),
      lastProducts: updatedProducts,
    );

    await collection.doc(merchantId).set(updatedMemory.toMap());
  }
}