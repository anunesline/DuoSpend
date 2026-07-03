class ProductModel {
  final String id;
  final String name;
  final String normalizedName;
  final String brand;
  final String barcode;
  final String defaultUnit;
  final String taxonomyId;
  final double averagePrice;
  final double lastPrice;
  final String lastMerchantId;
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.brand,
    required this.barcode,
    required this.defaultUnit,
    required this.taxonomyId,
    required this.averagePrice,
    required this.lastPrice,
    required this.lastMerchantId,
    required this.favorite,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'normalizedName': normalizedName,
      'brand': brand,
      'barcode': barcode,
      'defaultUnit': defaultUnit,
      'taxonomyId': taxonomyId,
      'averagePrice': averagePrice,
      'lastPrice': lastPrice,
      'lastMerchantId': lastMerchantId,
      'favorite': favorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      normalizedName: map['normalizedName'] ?? '',
      brand: map['brand'] ?? '',
      barcode: map['barcode'] ?? '',
      defaultUnit: map['defaultUnit'] ?? 'un',
      taxonomyId: map['taxonomyId'] ?? '',
      averagePrice: (map['averagePrice'] ?? 0).toDouble(),
      lastPrice: (map['lastPrice'] ?? 0).toDouble(),
      lastMerchantId: map['lastMerchantId'] ?? '',
      favorite: map['favorite'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}