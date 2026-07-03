import '../taxonomy/taxonomy_item.dart';
import '../taxonomy/duo_taxonomy.dart';

class ClassificationResult {
  final TaxonomyItem category;
  final TaxonomyItem? subcategory;
  final double confidence;

  const ClassificationResult({
    required this.category,
    this.subcategory,
    required this.confidence,
  });
}

class TransactionClassifier {
  static final Map<String, (String categoryId, String? subcategoryId)> _rules = {
    // Mercado
    'condor': ('food', 'market'),
    'muffato': ('food', 'market'),
    'carrefour': ('food', 'market'),
    'festval': ('food', 'market'),
    'angeloni': ('food', 'market'),
    'mercado': ('food', 'market'),

    // Fast Food
    'ifood': ('food', 'fast_food'),
    'mcdonald': ('food', 'fast_food'),
    'bk': ('food', 'fast_food'),
    'burger king': ('food', 'fast_food'),
    'pizza': ('food', 'fast_food'),
    'pizzaria': ('food', 'fast_food'),
    'hot dog': ('food', 'fast_food'),

    // Transporte
    'shell': ('transport', 'fuel'),
    'ipiranga': ('transport', 'fuel'),
    'petrobras': ('transport', 'fuel'),
    'posto': ('transport', 'fuel'),
    'uber': ('transport', 'uber'),
    '99': ('transport', 'uber'),

    // Pets
    'cobasi': ('pets', 'pet_food'),
    'petz': ('pets', 'pet_food'),

    // Contas
    'copel': ('bills', 'energy'),
    'sanepar': ('bills', 'water'),
    'vivo': ('bills', 'phone'),
    'tim': ('bills', 'phone'),
    'claro': ('bills', 'phone'),
    'netflix': ('bills', 'subscriptions'),
    'spotify': ('bills', 'subscriptions'),
  };

  static ClassificationResult? classify(String text) {
    final value = text.toLowerCase();

    for (final rule in _rules.entries) {
      if (value.contains(rule.key)) {
        final category = DuoTaxonomy.items.firstWhere(
          (c) => c.id == rule.value.$1,
        );

        TaxonomyItem? subcategory;

        if (rule.value.$2 != null) {
          subcategory = category.children.firstWhere(
            (c) => c.id == rule.value.$2,
          );
        }

        return ClassificationResult(
          category: category,
          subcategory: subcategory,
          confidence: 0.95,
        );
      }
    }

    return null;
  }

  TransactionClassifier._();
}