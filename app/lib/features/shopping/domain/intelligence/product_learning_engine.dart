import 'product_classification_result.dart';
import 'product_matcher.dart';
import 'product_memory.dart';

class ProductLearningEngine {
  const ProductLearningEngine();

  ProductMemory learn({
    required ProductClassificationResult classification,
    required ProductMatchResult match,
    required ProductMemory memory,
  }) {
    final packageDescription = _buildPackageDescription(classification);

    final updatedStatistics = memory.statistics.registerPurchase(
      purchasedAt: DateTime.now(),
      brandName: classification.brand,
      packageDescription: packageDescription,
    );

    final updatedPreferences = memory.preferences.copyWith(
      preferredBrand: classification.brand,
      preferredPackage: packageDescription,
    );

    return memory.copyWith(
      statistics: updatedStatistics,
      preferences: updatedPreferences,
    );
  }

  String? _buildPackageDescription(
    ProductClassificationResult classification,
  ) {
    if (classification.packageQuantity == null ||
        classification.packageUnit == null) {
      return null;
    }

    return '${classification.packageQuantity}${classification.packageUnit}';
  }
}