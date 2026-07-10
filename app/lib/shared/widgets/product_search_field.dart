import 'package:flutter/material.dart';

import '../../features/transactions/data/models/product_model.dart';

class ProductSearchField extends StatelessWidget {
  final TextEditingController controller;
  final List<ProductModel> suggestions;
  final ValueChanged<String> onSearch;
  final ValueChanged<ProductModel> onSelected;

  const ProductSearchField({
    super.key,
    required this.controller,
    required this.suggestions,
    required this.onSearch,
    required this.onSelected,
  });

  void _selectProduct(ProductModel product) {
    controller.text = product.name;
    onSelected(product);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Produto',
            hintText: 'Ex.: Leite integral',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: onSearch,
        ),
        if (suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              itemBuilder: (_, index) {
                final product = suggestions[index];

                return ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                    product.brand.isEmpty
                        ? 'Produto salvo'
                        : product.brand,
                  ),
                  onTap: () => _selectProduct(product),
                );
              },
            ),
          ),
      ],
    );
  }
}