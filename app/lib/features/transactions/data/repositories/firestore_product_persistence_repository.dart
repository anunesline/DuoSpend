import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/knowledge/products/product_persistence_repository.dart';
import '../models/product_model.dart';

class FirestoreProductPersistenceRepository
    implements ProductPersistenceRepository {
  final FirebaseFirestore _firestore;

  FirestoreProductPersistenceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _productsCollection({
    required String userId,
  }) {
    return _firestore.collection('users').doc(userId).collection('products');
  }

  @override
  Future<List<ProductModel>> getAll({required String userId}) async {
    final snapshot = await _productsCollection(userId: userId).get();

    return snapshot.docs.map((document) {
      return ProductModel.fromMap(<String, dynamic>{
        ...document.data(),
        'id': document.id,
      });
    }).toList();
  }

  @override
  Future<ProductModel?> getById({
    required String userId,
    required String productId,
  }) async {
    final document = await _productsCollection(
      userId: userId,
    ).doc(productId).get();

    final data = document.data();

    if (!document.exists || data == null) {
      return null;
    }

    return ProductModel.fromMap(<String, dynamic>{...data, 'id': document.id});
  }

  @override
  Future<void> save({
    required String userId,
    required ProductModel product,
  }) async {
    await _productsCollection(
      userId: userId,
    ).doc(product.id).set(product.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> delete({
    required String userId,
    required String productId,
  }) async {
    await _productsCollection(userId: userId).doc(productId).delete();
  }
}
