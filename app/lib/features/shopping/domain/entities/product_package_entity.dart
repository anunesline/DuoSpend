class ProductPackageEntity {
  final String id;
  final String commercialProductId;
  final double quantity;
  final String unit;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductPackageEntity({
    required this.id,
    required this.commercialProductId,
    required this.quantity,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
  });

  ProductPackageEntity copyWith({
    String? id,
    String? commercialProductId,
    double? quantity,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductPackageEntity(
      id: id ?? this.id,
      commercialProductId: commercialProductId ?? this.commercialProductId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}