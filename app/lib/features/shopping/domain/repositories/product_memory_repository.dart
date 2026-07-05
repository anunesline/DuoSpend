import '../intelligence/product_memory.dart';

abstract class ProductMemoryRepository {
  Future<ProductMemory> load();

  Future<void> save(ProductMemory memory);

  Future<void> reset();
}