import '../entities/commercial_product_entity.dart';
import '../entities/product_alias_entity.dart';
import '../entities/product_identity_entity.dart';
import '../entities/product_variant_entity.dart';
import 'brazil_product_knowledge_pack.dart';
import 'product_knowledge_pack_item.dart';
import 'product_memory.dart';

class ProductKnowledgeLoader {
  final BrazilProductKnowledgePack brazilPack;

  const ProductKnowledgeLoader({
    this.brazilPack = const BrazilProductKnowledgePack(),
  });

  ProductMemory loadBrazilDefaultMemory() {
    final items = brazilPack.load();
    final now = DateTime.now();

    final identities = <ProductIdentityEntity>[];
    final variants = <ProductVariantEntity>[];
    final commercialProducts = <CommercialProductEntity>[];
    final aliases = <ProductAliasEntity>[];

    for (final item in items) {
      final identityId = _buildId('product', item.canonicalName);

      final identity = ProductIdentityEntity(
        id: identityId,
        canonicalName: item.canonicalName,
        category: item.category,
        subcategory: item.subcategory,
        createdAt: now,
        updatedAt: now,
      );

      identities.add(identity);

      aliases.add(
        ProductAliasEntity(
          id: _buildId('alias', item.canonicalName),
          rawText: item.canonicalName,
          normalizedText: _normalize(item.canonicalName),
          productIdentityId: identityId,
          confidence: 1.0,
          createdAt: now,
          updatedAt: now,
        ),
      );

      for (final variantName in item.variants) {
        final variantId = _buildId(
          'variant',
          '${item.canonicalName}_$variantName',
        );

        variants.add(
          ProductVariantEntity(
            id: variantId,
            productIdentityId: identityId,
            name: variantName,
            createdAt: now,
            updatedAt: now,
          ),
        );

        aliases.add(
          ProductAliasEntity(
            id: _buildId('alias', '${item.canonicalName}_$variantName'),
            rawText: '${item.canonicalName} $variantName',
            normalizedText: _normalize('${item.canonicalName} $variantName'),
            productIdentityId: identityId,
            productVariantId: variantId,
            confidence: 1.0,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      for (final brandName in item.brands) {
        final commercialProductId = _buildId(
          'commercial',
          '${item.canonicalName}_$brandName',
        );

        commercialProducts.add(
          CommercialProductEntity(
            id: commercialProductId,
            productIdentityId: identityId,
            brand: brandName,
            createdAt: now,
            updatedAt: now,
          ),
        );

        aliases.add(
          ProductAliasEntity(
            id: _buildId('alias', '${item.canonicalName}_$brandName'),
            rawText: '${item.canonicalName} $brandName',
            normalizedText: _normalize('${item.canonicalName} $brandName'),
            productIdentityId: identityId,
            commercialProductId: commercialProductId,
            confidence: 1.0,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    return ProductMemory(
      identities: identities,
      variants: variants,
      commercialProducts: commercialProducts,
      aliases: aliases,
    );
  }

  String _buildId(String prefix, String value) {
    final normalized = _normalize(value)
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return '${prefix}_$normalized';
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }
}