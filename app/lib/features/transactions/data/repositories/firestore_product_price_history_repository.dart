import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/knowledge/products/product_price_history_repository.dart';
import '../../../../shared/knowledge/products/product_price_observation.dart';

class FirestoreProductPriceHistoryRepository
    implements ProductPriceHistoryRepository {
  FirestoreProductPriceHistoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _historyCollection({
    required String userId,
    required String productId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('products')
        .doc(productId)
        .collection('priceHistory');
  }

  @override
  Future<List<ProductPriceObservation>> getByProductId({
    required String userId,
    required String productId,
  }) async {
    final snapshot = await _historyCollection(
      userId: userId,
      productId: productId,
    ).get();

    final observations =
        snapshot.docs
            .map(
              (document) => ProductPriceObservation.fromMap(
                document.data(),
                fallbackProductId: productId,
              ),
            )
            .toList()
          ..sort((left, right) {
            final dateComparison = left.purchasedAt.compareTo(
              right.purchasedAt,
            );
            if (dateComparison != 0) {
              return dateComparison;
            }

            return left.purchaseId.compareTo(right.purchaseId);
          });

    return observations;
  }

  @override
  Future<void> saveObservation({
    required String userId,
    required ProductPriceObservation observation,
  }) async {
    await _historyCollection(
      userId: userId,
      productId: observation.productId,
    ).doc(observation.id).set(observation.toMap(), SetOptions(merge: true));
  }
}
