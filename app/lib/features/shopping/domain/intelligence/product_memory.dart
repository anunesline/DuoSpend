import '../entities/commercial_product_entity.dart';
import '../entities/product_alias_entity.dart';
import '../entities/product_identity_entity.dart';
import '../entities/product_package_entity.dart';
import '../entities/product_variant_entity.dart';

class ProductMemory {
  final List<ProductIdentityEntity> identities;
  final List<ProductVariantEntity> variants;
  final List<CommercialProductEntity> commercialProducts;
  final List<ProductPackageEntity> packages;
  final List<ProductAliasEntity> aliases;

  const ProductMemory({
    this.identities = const [],
    this.variants = const [],
    this.commercialProducts = const [],
    this.packages = const [],
    this.aliases = const [],
  });

  ProductMemory copyWith({
    List<ProductIdentityEntity>? identities,
    List<ProductVariantEntity>? variants,
    List<CommercialProductEntity>? commercialProducts,
    List<ProductPackageEntity>? packages,
    List<ProductAliasEntity>? aliases,
  }) {
    return ProductMemory(
      identities: identities ?? this.identities,
      variants: variants ?? this.variants,
      commercialProducts:
          commercialProducts ?? this.commercialProducts,
      packages: packages ?? this.packages,
      aliases: aliases ?? this.aliases,
    );
  }

  bool get isEmpty =>
      identities.isEmpty &&
      variants.isEmpty &&
      commercialProducts.isEmpty &&
      packages.isEmpty &&
      aliases.isEmpty;

  bool get isNotEmpty => !isEmpty;
}