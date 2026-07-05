import '../../data/repositories/in_memory_product_memory_repository.dart';
import 'product_intelligence_engine.dart';

class ProductIntelligenceDebug {
  Future<void> run() async {
    final repository = InMemoryProductMemoryRepository();

    final engine = ProductIntelligenceEngine(
      repository: repository,
    );

    await engine.process('Leite Piracanjuba Integral 1L');
    await engine.process('Leite Italac Semidesnatado 1 litro');
    await engine.process('Leite Tirol Zero Lactose');

    final memory = await repository.load();

    // ignore: avoid_print
    print('Identidades: ${memory.identities.length}');

    // ignore: avoid_print
    print('Aliases: ${memory.aliases.length}');

    // ignore: avoid_print
    print('Produtos comerciais: ${memory.commercialProducts.length}');
  }
}