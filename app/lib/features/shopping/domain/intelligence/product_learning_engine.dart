import '../../../../core/cognition/contracts/learning_engine.dart';
import '../../../../core/cognition/contexts/knowledge_context.dart';
import '../../../../core/cognition/payloads/purchase_knowledge_payload.dart';

import 'product_memory.dart';

class ProductLearningEngine implements LearningEngine<ProductMemory> {
  const ProductLearningEngine();

  @override
  ProductMemory learn(
    KnowledgeContext context,
    ProductMemory memory,
  ) {
    if (context.payload is! PurchaseKnowledgePayload) {
      return memory;
    }

    final payload = context.payload as PurchaseKnowledgePayload;

    final packageDescription = _buildPackageDescription(
      payload.packageQuantity,
      payload.packageUnit,
    );

    final updatedStatistics = memory.statistics.registerPurchase(
      purchasedAt: context.occurredAt,
      unitPrice: payload.unitPrice,
      totalPrice: payload.totalPrice,
      brandName: payload.brand,
      merchantName: payload.merchantName,
      packageDescription: packageDescription,
    );

    final updatedPreferences = memory.preferences.copyWith(
      preferredBrand: payload.brand,
      preferredMerchant: payload.merchantName,
      preferredPackage: packageDescription,
    );

    return memory.copyWith(
      statistics: updatedStatistics,
      preferences: updatedPreferences,
    );
  }

  String? _buildPackageDescription(
    double? quantity,
    String? unit,
  ) {
    if (quantity == null || unit == null) {
      return null;
    }

    return '$quantity$unit';
  }
}