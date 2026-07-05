import '../intelligence/product_intelligence_engine.dart';

class ProcessProductIntelligenceUseCase {
  final ProductIntelligenceEngine engine;

  const ProcessProductIntelligenceUseCase(this.engine);

  Future<ProductIntelligenceResult> call(String input) async {
    return engine.process(input);
  }
}