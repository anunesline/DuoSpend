import '../../../features/transactions/data/models/product_model.dart';

class ProductMemory {
  static final List<ProductModel> _products = [];

  static List<ProductModel> get all => List.unmodifiable(_products);

  static void remember(ProductModel product) {
    final index = _products.indexWhere((p) => p.id == product.id);

    if (index >= 0) {
      _products[index] = product;
    } else {
      _products.add(product);
    }
  }

  static ProductModel? findById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<ProductModel> search(String query) {
    final value = query.trim().toLowerCase();

    if (value.isEmpty) return [];

    return _products.where((product) {
      return product.name.toLowerCase().contains(value) ||
          product.normalizedName.toLowerCase().contains(value) ||
          product.brand.toLowerCase().contains(value);
    }).toList();
  }

  static void clear() {
    _products.clear();
  }

  ProductMemory._();
}