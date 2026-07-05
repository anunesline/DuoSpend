import '../../domain/intelligence/product_knowledge_loader.dart';
import '../../domain/intelligence/product_memory.dart';
import '../../domain/repositories/product_memory_repository.dart';

class InMemoryProductMemoryRepository implements ProductMemoryRepository {
  ProductMemory? _memory;

  final ProductKnowledgeLoader loader;

  InMemoryProductMemoryRepository({
    this.loader = const ProductKnowledgeLoader(),
  });

  @override
  Future<ProductMemory> load() async {
    _memory ??= loader.loadBrazilDefaultMemory();

    return _memory!;
  }

  @override
  Future<void> save(ProductMemory memory) async {
    _memory = memory;
  }

  @override
  Future<void> reset() async {
    _memory = loader.loadBrazilDefaultMemory();
  }
}