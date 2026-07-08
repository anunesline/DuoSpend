enum ProductLearningSource {
  manualPurchase,
  shoppingFlow,
  import,
  correction,
  systemInference,
}

class ProductLearningEvent {
  const ProductLearningEvent({
    required this.userId,
    required this.rawDescription,
    required this.normalizedDescription,
    required this.purchasedAt,
    required this.source,
    this.productIdentityId,
    this.productVariantId,
    this.commercialProductId,
    this.productPackageId,
    this.brandName,
    this.categoryName,
    this.subcategoryName,
    this.packageDescription,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
    this.merchantId,
    this.merchantName,
    this.confidence = 0,
  });

  final String userId;
  final String rawDescription;
  final String normalizedDescription;
  final DateTime purchasedAt;
  final ProductLearningSource source;

  final String? productIdentityId;
  final String? productVariantId;
  final String? commercialProductId;
  final String? productPackageId;

  final String? brandName;
  final String? categoryName;
  final String? subcategoryName;
  final String? packageDescription;

  final double? quantity;
  final double? unitPrice;
  final double? totalPrice;

  final String? merchantId;
  final String? merchantName;

  final double confidence;

  bool get hasIdentity => productIdentityId != null;
  bool get hasVariant => productVariantId != null;
  bool get hasCommercialProduct => commercialProductId != null;
  bool get hasPackage => productPackageId != null;
  bool get hasBrand => brandName != null && brandName!.trim().isNotEmpty;
  bool get hasCategory =>
      categoryName != null && categoryName!.trim().isNotEmpty;
  bool get hasPriceInformation => unitPrice != null || totalPrice != null;
  bool get isReliable => confidence >= 0.7;
}