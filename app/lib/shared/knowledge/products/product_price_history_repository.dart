import 'product_price_observation.dart';

abstract interface class ProductPriceHistoryRepository {
  Future<List<ProductPriceObservation>> getByProductId({
    required String userId,
    required String productId,
  });

  Future<void> saveObservation({
    required String userId,
    required ProductPriceObservation observation,
  });
}
