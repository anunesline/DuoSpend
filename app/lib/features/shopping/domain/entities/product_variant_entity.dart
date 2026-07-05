class ProductVariantEntity {
  final String id;
  final String productIdentityId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductVariantEntity({
    required this.id,
    required this.productIdentityId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  ProductVariantEntity copyWith({
    String? id,
    String? productIdentityId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductVariantEntity(
      id: id ?? this.id,
      productIdentityId: productIdentityId ?? this.productIdentityId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}