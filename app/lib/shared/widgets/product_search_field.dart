import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/transactions/data/models/product_model.dart';

class ProductSearchField extends StatefulWidget {
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

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }

      widget.onSearch(value);
    });
  }

  void _selectProduct(ProductModel product) {
    _searchDebounce?.cancel();

    widget.controller.value = TextEditingValue(
      text: product.name,
      selection: TextSelection.collapsed(offset: product.name.length),
    );

    widget.onSelected(product);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Produto',
            hintText: 'Ex.: Leite integral',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: _handleChanged,
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
                  onTap: () => _selectProduct(product),
                );
              },
            ),
          ),
      ],
    );
  }
}
