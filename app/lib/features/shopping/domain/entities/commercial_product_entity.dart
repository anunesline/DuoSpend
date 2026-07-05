class CommercialProductEntity {
  final String id;
  final String productIdentityId;
  final String? productVariantId;
  final String brand;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommercialProductEntity({
    required this.id,
    required this.productIdentityId,
    this.productVariantId,
    required this.brand,
    required this.createdAt,
    required this.updatedAt,
  });

  CommercialProductEntity copyWith({
    String? id,
    String? productIdentityId,
    String? productVariantId,
    String? brand,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommercialProductEntity(
      id: id ?? this.id,
      productIdentityId: productIdentityId ?? this.productIdentityId,
      productVariantId: productVariantId ?? this.productVariantId,
      brand: brand ?? this.brand,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}