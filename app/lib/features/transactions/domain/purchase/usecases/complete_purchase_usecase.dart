import '../models/purchase_model.dart';
import 'analyze_purchase_usecase.dart';
import 'save_purchase_to_repository_usecase.dart';

class CompletePurchaseResult {
  final PurchaseModel purchase;
  final AnalyzePurchaseResult analysis;

  const CompletePurchaseResult({
    required this.purchase,
    required this.analysis,
  });
}

class CompletePurchaseUseCase {
  final AnalyzePurchaseUseCase _analyzePurchaseUseCase;
  final SavePurchaseToRepositoryUseCase _savePurchaseUseCase;

  const CompletePurchaseUseCase({
    required AnalyzePurchaseUseCase analyzePurchaseUseCase,
    required SavePurchaseToRepositoryUseCase savePurchaseUseCase,
  })  : _analyzePurchaseUseCase = analyzePurchaseUseCase,
        _savePurchaseUseCase = savePurchaseUseCase;

  Future<CompletePurchaseResult> call(PurchaseModel purchase) async {
    final analysis = _analyzePurchaseUseCase(purchase);

    await _savePurchaseUseCase(purchase);

    return CompletePurchaseResult(
      purchase: purchase,
      analysis: analysis,
    );
  }
}
