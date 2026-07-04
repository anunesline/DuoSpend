import '../../../features/transactions/data/models/product_model.dart';
import 'product_memory.dart';

class ProductRepository {
  ProductModel? findById(String id) {
    return ProductMemory.findById(id);
  }

  List<ProductModel> search(String query) {
    final value = query.trim().toLowerCase();

    print('Buscando produto: $value');
    print('Total memória: ${ProductMemory.all.length}');

    if (value.isEmpty) {
      return ProductMemory.all;
    }

    return ProductMemory.all.where((product) {
      return product.name.toLowerCase().contains(value) ||
          product.normalizedName.toLowerCase().contains(value) ||
          product.brand.toLowerCase().contains(value);
    }).toList();
  }

  void save(ProductModel product) {
    ProductMemory.remember(product);
  }

  bool exists(String name) {
    final normalized = name.trim().toLowerCase();

    return ProductMemory.all.any(
      (product) => product.normalizedName == normalized,
    );
  }

  ProductModel? findByName(String name) {
    final normalized = name.trim().toLowerCase();

    try {
      return ProductMemory.all.firstWhere(
        (product) => product.normalizedName == normalized,
      );
    } catch (_) {
      return null;
    }
  }
}