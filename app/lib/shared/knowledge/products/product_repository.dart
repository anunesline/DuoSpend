import '../../../features/transactions/data/models/product_model.dart';
import 'product_memory.dart';

class ProductRepository {
  ProductModel? findById(String id) {
    return ProductMemory.findById(id);
  }

  String normalize(String value) {
    var normalized = value.trim().toLowerCase();

    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
    };

    replacements.forEach((character, replacement) {
      normalized = normalized.replaceAll(character, replacement);
    });

    normalized = normalized
        .replaceAll(RegExp(r'[^a-z0-9\s\-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return normalized;
  }

  List<ProductModel> search(String query) {
    final normalizedQuery = normalize(query);

    if (normalizedQuery.isEmpty) {
      return ProductMemory.all;
    }

    return ProductMemory.all.where((product) {
      final normalizedName = normalize(product.name);
      final normalizedStoredName = normalize(product.normalizedName);
      final normalizedBrand = normalize(product.brand);

      return normalizedName.contains(normalizedQuery) ||
          normalizedStoredName.contains(normalizedQuery) ||
          normalizedBrand.contains(normalizedQuery);
    }).toList();
  }

  void save(ProductModel product) {
    ProductMemory.remember(product);
  }

  bool exists(String name) {
    final normalizedName = normalize(name);

    return ProductMemory.all.any(
      (product) =>
          normalize(product.normalizedName) == normalizedName ||
          normalize(product.name) == normalizedName,
    );
  }

  ProductModel? findByName(String name) {
    final normalizedName = normalize(name);

    try {
      return ProductMemory.all.firstWhere(
        (product) =>
            normalize(product.normalizedName) == normalizedName ||
            normalize(product.name) == normalizedName,
      );
    } catch (_) {
      return null;
    }
  }
}
