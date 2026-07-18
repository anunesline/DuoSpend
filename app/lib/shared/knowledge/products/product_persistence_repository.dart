import '../../../features/transactions/data/models/product_model.dart';

abstract interface class ProductPersistenceRepository {
  Future<List<ProductModel>> getAll({required String userId});

  Future<ProductModel?> getById({
    required String userId,
    required String productId,
  });

  Future<void> save({required String userId, required ProductModel product});

  Future<void> delete({required String userId, required String productId});
}
