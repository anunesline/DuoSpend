import 'package:flutter/material.dart';

import '../../features/transactions/data/models/product_model.dart';

class ProductSummaryCard extends StatelessWidget {
  final ProductModel product;
  final String category;
  final String subcategory;

  const ProductSummaryCard({
    super.key,
    required this.product,
    required this.category,
    required this.subcategory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Produto reconhecido',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            _Item(
              icon: Icons.sell_outlined,
              title: 'Marca',
              value: product.brand.isEmpty ? 'Sem marca' : product.brand,
            ),
            _Item(
              icon: Icons.category_outlined,
              title: 'Categoria do produto',
              value: product.productCategoryName,
            ),
            _Item(
              icon: Icons.account_tree_outlined,
              title: 'Classificação atual',
              value: '$category • $subcategory',
            ),
            _Item(
              icon: Icons.straighten,
              title: 'Unidade',
              value: product.defaultUnit,
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _Item({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}