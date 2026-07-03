class MerchantModel {
  final String id;
  final String name;
  final String normalizedName;
  final String cnpj;
  final String category;
  final String city;
  final String state;
  final bool favorite;
  final DateTime createdAt;

  MerchantModel({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.cnpj,
    required this.category,
    required this.city,
    required this.state,
    required this.favorite,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'normalizedName': normalizedName,
      'cnpj': cnpj,
      'category': category,
      'city': city,
      'state': state,
      'favorite': favorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MerchantModel.fromMap(Map<String, dynamic> map) {
    return MerchantModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      normalizedName: map['normalizedName'] ?? '',
      cnpj: map['cnpj'] ?? '',
      category: map['category'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      favorite: map['favorite'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}