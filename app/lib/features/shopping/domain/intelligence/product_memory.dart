import '../entities/commercial_product_entity.dart';
import '../entities/product_alias_entity.dart';
import '../entities/product_identity_entity.dart';
import '../entities/product_package_entity.dart';
import '../entities/product_variant_entity.dart';
import 'learning_statistics.dart';
import 'memory_scope.dart';
import 'product_preferences.dart';

class ProductMemory {
  final MemoryScope? scope;

  final List<ProductIdentityEntity> identities;
  final List<ProductVariantEntity> variants;
  final List<CommercialProductEntity> commercialProducts;
  final List<ProductPackageEntity> packages;
  final List<ProductAliasEntity> aliases;

  final LearningStatistics statistics;
  final ProductPreferences preferences;

  const ProductMemory({
    this.scope,
    this.identities = const [],
    this.variants = const [],
    this.commercialProducts = const [],
    this.packages = const [],
    this.aliases = const [],
    this.statistics = const LearningStatistics(),
    this.preferences = const ProductPreferences(),
  });

  ProductMemory copyWith({
    MemoryScope? scope,
    List<ProductIdentityEntity>? identities,
    List<ProductVariantEntity>? variants,
    List<CommercialProductEntity>? commercialProducts,
    List<ProductPackageEntity>? packages,
    List<ProductAliasEntity>? aliases,
    LearningStatistics? statistics,
    ProductPreferences? preferences,
  }) {
    return ProductMemory(
      scope: scope ?? this.scope,
      identities: identities ?? this.identities,
      variants: variants ?? this.variants,
      commercialProducts:
          commercialProducts ?? this.commercialProducts,
      packages: packages ?? this.packages,
      aliases: aliases ?? this.aliases,
      statistics: statistics ?? this.statistics,
      preferences: preferences ?? this.preferences,
    );
  }

  bool get hasScope => scope != null;

  bool get hasKnowledge =>
      identities.isNotEmpty ||
      variants.isNotEmpty ||
      commercialProducts.isNotEmpty ||
      packages.isNotEmpty ||
      aliases.isNotEmpty;

  bool get hasLearning =>
      statistics.hasPurchases ||
      preferences.isNotEmpty;

  bool get isEmpty => !hasKnowledge && !hasLearning;

  bool get isNotEmpty => !isEmpty;
}