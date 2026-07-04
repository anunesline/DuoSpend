import 'package:flutter/material.dart';

import '../../features/transactions/data/models/product_model.dart';

class ProductSearchField extends StatefulWidget {
  final List<ProductModel> suggestions;
  final ValueChanged<String> onSearch;
  final ValueChanged<ProductModel> onSelected;

  const ProductSearchField({
    super.key,
    required this.suggestions,
    required this.onSearch,
    required this.onSelected,
  });

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _selectProduct(ProductModel product) {
    controller.text = product.name;
    widget.onSelected(product);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'O que você comprou?',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: widget.onSearch,
        ),
        if (widget.suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.suggestions.length,
              itemBuilder: (_, index) {
                final product = widget.suggestions[index];

                return ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                    product.brand.isEmpty ? 'Produto salvo' : product.brand,
                  ),
                  onTap: () {
                    _selectProduct(product);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}