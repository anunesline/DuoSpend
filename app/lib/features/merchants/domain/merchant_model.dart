class MerchantModel {
  const MerchantModel({
    required this.id,
    required this.name,
    required this.type,
    required this.defaultFinancialCategory,
    this.defaultFinancialSubcategory,
    this.aliases = const [],
    this.icon = 'storefront',
    this.colorHex,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;

  /// Ex: mercado, farmácia, restaurante, delivery, petshop, posto, loja.
  final String type;

  /// Categoria financeira sugerida.
  /// Ex: Mercado, Alimentação, Saúde, Transporte.
  final String defaultFinancialCategory;

  /// Subcategoria financeira sugerida.
  /// Ex: Supermercado, Farmácia, Delivery.
  final String? defaultFinancialSubcategory;

  /// Variações de escrita usadas para reconhecimento.
  /// Ex: ['condor supermercado', 'super condor', 'condor agua verde']
  final List<String> aliases;

  /// Nome do ícone para uso visual futuro.
  final String icon;

  /// Cor opcional futura para personalização visual.
  final String? colorHex;

  /// Observações internas futuras.
  final String? notes;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  MerchantModel copyWith({
    String? id,
    String? name,
    String? type,
    String? defaultFinancialCategory,
    String? defaultFinancialSubcategory,
    List<String>? aliases,
    String? icon,
    String? colorHex,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MerchantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      defaultFinancialCategory:
          defaultFinancialCategory ?? this.defaultFinancialCategory,
      defaultFinancialSubcategory:
          defaultFinancialSubcategory ?? this.defaultFinancialSubcategory,
      aliases: aliases ?? this.aliases,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MerchantModel.fromMap(Map<String, dynamic> map) {
    return MerchantModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      defaultFinancialCategory: map['defaultFinancialCategory'] ?? '',
      defaultFinancialSubcategory: map['defaultFinancialSubcategory'],
      aliases: List<String>.from(map['aliases'] ?? []),
      icon: map['icon'] ?? 'storefront',
      colorHex: map['colorHex'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'defaultFinancialCategory': defaultFinancialCategory,
      'defaultFinancialSubcategory': defaultFinancialSubcategory,
      'aliases': aliases,
      'icon': icon,
      'colorHex': colorHex,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool matches(String query) {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      return false;
    }

    final normalizedName = _normalize(name);

    if (normalizedName.contains(normalizedQuery)) {
      return true;
    }

    return aliases.any((alias) {
      return _normalize(alias).contains(normalizedQuery);
    });
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}