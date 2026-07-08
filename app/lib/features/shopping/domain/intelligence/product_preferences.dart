class ProductPreferences {
  final String? preferredBrand;
  final String? preferredMerchant;
  final String? preferredPackage;

  const ProductPreferences({
    this.preferredBrand,
    this.preferredMerchant,
    this.preferredPackage,
  });

  ProductPreferences copyWith({
    String? preferredBrand,
    String? preferredMerchant,
    String? preferredPackage,
  }) {
    return ProductPreferences(
      preferredBrand: preferredBrand ?? this.preferredBrand,
      preferredMerchant: preferredMerchant ?? this.preferredMerchant,
      preferredPackage: preferredPackage ?? this.preferredPackage,
    );
  }

  bool get isEmpty =>
      preferredBrand == null &&
      preferredMerchant == null &&
      preferredPackage == null;

  bool get isNotEmpty => !isEmpty;
}