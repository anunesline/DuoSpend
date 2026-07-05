class ProductIdentityEntity {
  final String id;
  final String canonicalName;
  final String category;
  final String subcategory;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductIdentityEntity({
    required this.id,
    required this.canonicalName,
    required this.category,
    required this.subcategory,
    required this.createdAt,
    required this.updatedAt,
  });

  ProductIdentityEntity copyWith({
    String? id,
    String? canonicalName,
    String? category,
    String? subcategory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductIdentityEntity(
      id: id ?? this.id,
      canonicalName: canonicalName ?? this.canonicalName,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}