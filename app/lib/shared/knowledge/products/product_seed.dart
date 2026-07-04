import '../../../features/transactions/data/models/product_model.dart';
import 'product_repository.dart';

class ProductSeed {
  static void load(ProductRepository repository) {
    final now = DateTime.now();

    final products = [
      ProductModel(
        id: 'heineken_350ml',
        name: 'Heineken 350ml',
        normalizedName: 'heineken 350ml',
        brand: 'Heineken',
        barcode: '',
        defaultUnit: 'un',
        productCategoryId: 'beverages',
        productCategoryName: 'Bebidas',
        taxonomyId: 'drinks',
        averagePrice: 0,
        lastPrice: 0,
        lastMerchantId: '',
        favorite: false,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'coca_cola_2l',
        name: 'Coca-Cola 2L',
        normalizedName: 'coca-cola 2l',
        brand: 'Coca-Cola',
        barcode: '',
        defaultUnit: 'un',
        productCategoryId: 'beverages',
        productCategoryName: 'Bebidas',
        taxonomyId: 'drinks',
        averagePrice: 0,
        lastPrice: 0,
        lastMerchantId: '',
        favorite: false,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'leite_1l',
        name: 'Leite 1L',
        normalizedName: 'leite 1l',
        brand: '',
        barcode: '',
        defaultUnit: 'L',
        productCategoryId: 'dairy',
        productCategoryName: 'Laticínios',
        taxonomyId: 'dairy',
        averagePrice: 0,
        lastPrice: 0,
        lastMerchantId: '',
        favorite: false,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'picanha_kg',
        name: 'Picanha',
        normalizedName: 'picanha',
        brand: '',
        barcode: '',
        defaultUnit: 'kg',
        productCategoryId: 'meat',
        productCategoryName: 'Carnes',
        taxonomyId: 'meat',
        averagePrice: 0,
        lastPrice: 0,
        lastMerchantId: '',
        favorite: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final product in products) {
      if (!repository.exists(product.name)) {
        repository.save(product);
      }
    }
  }

  ProductSeed._();
}