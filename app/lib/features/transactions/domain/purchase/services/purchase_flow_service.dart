import '../models/purchase_model.dart';
import '../usecases/complete_purchase_usecase.dart';

class PurchaseFlowResult {
  final PurchaseModel purchase;
  final CompletePurchaseResult completedPurchase;

  const PurchaseFlowResult({
    required this.purchase,
    required this.completedPurchase,
  });
}

class PurchaseFlowService {
  final CompletePurchaseUseCase _completePurchaseUseCase;

  const PurchaseFlowService({
    required CompletePurchaseUseCase completePurchaseUseCase,
  }) : _completePurchaseUseCase = completePurchaseUseCase;

  Future<PurchaseFlowResult> completePurchase(PurchaseModel purchase) async {
    _validatePurchase(purchase);

    final completedPurchase = await _completePurchaseUseCase(purchase);

    return PurchaseFlowResult(
      purchase: completedPurchase.purchase,
      completedPurchase: completedPurchase,
    );
  }

  void _validatePurchase(PurchaseModel purchase) {
    if (purchase.id.trim().isEmpty) {
      throw Exception('A compra precisa ter um ID.');
    }

    if (purchase.userId.trim().isEmpty) {
      throw Exception('A compra precisa estar vinculada a um usuário.');
    }

    if (purchase.walletId.trim().isEmpty) {
      throw Exception('A compra precisa estar vinculada a uma carteira.');
    }

    if (!purchase.hasItems) {
      throw Exception('Adicione pelo menos um produto à compra.');
    }

    if (purchase.total <= 0) {
      throw Exception('O total da compra deve ser maior que zero.');
    }
  }
}