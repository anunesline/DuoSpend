import 'product_repository.dart';
import 'product_seed.dart';

class ProductBootstrap {
  final ProductRepository _productRepository;

  ProductBootstrap({required ProductRepository productRepository})
    : _productRepository = productRepository;

  Future<void> initialize({required String userId}) async {
    _productRepository.clearMemory();

    ProductSeed.load(_productRepository);

    await _productRepository.initialize(userId: userId);
  }
}
