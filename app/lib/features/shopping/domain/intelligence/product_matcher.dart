import '../entities/product_alias_entity.dart';
import '../entities/product_identity_entity.dart';
import 'product_classification_result.dart';
import 'product_memory.dart';

class ProductMatcher {
  const ProductMatcher();

  ProductMatchResult match({
    required ProductClassificationResult classification,
    required ProductMemory memory,
  }) {
    final aliasMatch = _findAliasMatch(
      classification: classification,
      memory: memory,
    );

    if (aliasMatch != null) {
      final identity = _findIdentityById(
        productIdentityId: aliasMatch.productIdentityId,
        memory: memory,
      );

      if (identity != null) {
        return ProductMatchResult(
          identity: identity,
          alias: aliasMatch,
          isKnown: true,
          confidence: aliasMatch.confidence,
        );
      }
    }

    final identityMatch = _findIdentityMatch(
      classification: classification,
      memory: memory,
    );

    if (identityMatch != null) {
      return ProductMatchResult(
        identity: identityMatch,
        isKnown: true,
        confidence: classification.confidence,
      );
    }

    return ProductMatchResult(
      identity: null,
      alias: null,
      isKnown: false,
      confidence: classification.confidence,
    );
  }

  ProductAliasEntity? _findAliasMatch({
    required ProductClassificationResult classification,
    required ProductMemory memory,
  }) {
    for (final alias in memory.aliases) {
      if (alias.normalizedText == classification.normalizedText) {
        return alias;
      }
    }

    return null;
  }

  ProductIdentityEntity? _findIdentityMatch({
    required ProductClassificationResult classification,
    required ProductMemory memory,
  }) {
    for (final identity in memory.identities) {
      if (identity.canonicalName.toLowerCase() ==
          classification.canonicalName.toLowerCase()) {
        return identity;
      }
    }

    return null;
  }

  ProductIdentityEntity? _findIdentityById({
    required String productIdentityId,
    required ProductMemory memory,
  }) {
    for (final identity in memory.identities) {
      if (identity.id == productIdentityId) {
        return identity;
      }
    }

    return null;
  }
}

class ProductMatchResult {
  final ProductIdentityEntity? identity;
  final ProductAliasEntity? alias;
  final bool isKnown;
  final double confidence;

  const ProductMatchResult({
    required this.identity,
    this.alias,
    required this.isKnown,
    required this.confidence,
  });
}