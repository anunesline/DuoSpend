import '../entities/product_alias_entity.dart';
import '../entities/product_identity_entity.dart';
import 'product_classification_result.dart';
import 'product_matcher.dart';
import 'product_memory.dart';

class ProductLearningEngine {
  const ProductLearningEngine();

  ProductMemory learn({
    required ProductClassificationResult classification,
    required ProductMatchResult match,
    required ProductMemory memory,
  }) {
    if (match.isKnown && match.identity != null) {
      return _learnAliasForKnownIdentity(
        classification: classification,
        identity: match.identity!,
        memory: memory,
      );
    }

    return _learnNewIdentity(
      classification: classification,
      memory: memory,
    );
  }

  ProductMemory _learnAliasForKnownIdentity({
    required ProductClassificationResult classification,
    required ProductIdentityEntity identity,
    required ProductMemory memory,
  }) {
    final aliasAlreadyExists = memory.aliases.any(
      (alias) => alias.normalizedText == classification.normalizedText,
    );

    if (aliasAlreadyExists) {
      return memory;
    }

    final now = DateTime.now();

    final alias = ProductAliasEntity(
      id: _buildId('alias', classification.normalizedText),
      rawText: classification.rawText,
      normalizedText: classification.normalizedText,
      productIdentityId: identity.id,
      confidence: classification.confidence,
      createdAt: now,
      updatedAt: now,
    );

    return memory.copyWith(
      aliases: [
        ...memory.aliases,
        alias,
      ],
    );
  }

  ProductMemory _learnNewIdentity({
    required ProductClassificationResult classification,
    required ProductMemory memory,
  }) {
    final now = DateTime.now();

    final identity = ProductIdentityEntity(
      id: _buildId('product', classification.canonicalName),
      canonicalName: _capitalize(classification.canonicalName),
      category: 'Não classificado',
      subcategory: 'Não classificado',
      createdAt: now,
      updatedAt: now,
    );

    final alias = ProductAliasEntity(
      id: _buildId('alias', classification.normalizedText),
      rawText: classification.rawText,
      normalizedText: classification.normalizedText,
      productIdentityId: identity.id,
      confidence: classification.confidence,
      createdAt: now,
      updatedAt: now,
    );

    return memory.copyWith(
      identities: [
        ...memory.identities,
        identity,
      ],
      aliases: [
        ...memory.aliases,
        alias,
      ],
    );
  }

  String _buildId(String prefix, String value) {
    final normalized = value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return '${prefix}_$normalized';
  }

  String _capitalize(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return trimmed;
    }

    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}