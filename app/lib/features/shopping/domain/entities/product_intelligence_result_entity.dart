import 'product_identity_entity.dart';

class ProductIntelligenceResultEntity {
  final String originalInput;
  final ProductIdentityEntity identity;
  final bool isKnownProduct;
  final bool needsUserConfirmation;

  const ProductIntelligenceResultEntity({
    required this.originalInput,
    required this.identity,
    required this.isKnownProduct,
    required this.needsUserConfirmation,
  });
}