class ProductAliasEntity {
  final String id;
  final String rawText;
  final String normalizedText;
  final String productIdentityId;
  final String? productVariantId;
  final String? commercialProductId;
  final String? productPackageId;
  final double confidence;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductAliasEntity({
    required this.id,
    required this.rawText,
    required this.normalizedText,
    required this.productIdentityId,
    this.productVariantId,
    this.commercialProductId,
    this.productPackageId,
    required this.confidence,
    required this.createdAt,
    required this.updatedAt,
  });

  ProductAliasEntity copyWith({
    String? id,
    String? rawText,
    String? normalizedText,
    String? productIdentityId,
    String? productVariantId,
    String? commercialProductId,
    String? productPackageId,
    double? confidence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductAliasEntity(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      normalizedText: normalizedText ?? this.normalizedText,
      productIdentityId: productIdentityId ?? this.productIdentityId,
      productVariantId: productVariantId ?? this.productVariantId,
      commercialProductId: commercialProductId ?? this.commercialProductId,
      productPackageId: productPackageId ?? this.productPackageId,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}