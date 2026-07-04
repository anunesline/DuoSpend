import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/knowledge/taxonomy/duo_taxonomy.dart';
import '../../../../shared/knowledge/taxonomy/taxonomy_item.dart';
import '../../data/models/transaction_item_model.dart';
import '../controllers/transaction_controller.dart';
import 'add_transaction_item_page.dart';

class NewTransactionPage extends StatefulWidget {
  const NewTransactionPage({super.key});

  @override
  State<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends State<NewTransactionPage> {
  final descriptionController = TextEditingController();
  final valueController = TextEditingController();
  final TransactionController controller = TransactionController();

  String type = 'expense';

  TaxonomyItem selectedCategory = DuoTaxonomy.items.first;
  TaxonomyItem? selectedSubcategory = DuoTaxonomy.items.first.children.isNotEmpty
      ? DuoTaxonomy.items.first.children.first
      : null;

  @override
  void dispose() {
    descriptionController.dispose();
    valueController.dispose();
    super.dispose();
  }

  void _changeCategory(TaxonomyItem category) {
    setState(() {
      selectedCategory = category;
      selectedSubcategory =
          category.children.isNotEmpty ? category.children.first : null;
    });
  }

  Future<void> _openAddItemPage() async {
    final item = await Navigator.push<TransactionItemModel>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionItemPage(),
      ),
    );

    if (item != null) {
      controller.addItem(item);
    }
  }

  Future<void> _saveTransaction() async {
    final description = descriptionController.text.trim();

    final value = double.tryParse(
      valueController.text.replaceAll(',', '.'),
    );

    if (description.isEmpty || value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos.'),
        ),
      );
      return;
    }

    await controller.saveTransaction(
      description: description,
      value: value,
      type: type,
      category: selectedCategory.name,
      subcategory: selectedSubcategory?.name ?? 'Sem subcategoria',
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final subcategories = selectedCategory.children;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Transação'),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final items = controller.items;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                TextField(
                  controller: valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                DropdownButtonFormField<TaxonomyItem>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: DuoTaxonomy.items.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text('${category.icon} ${category.name}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _changeCategory(value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                DropdownButtonFormField<TaxonomyItem>(
                  value: selectedSubcategory,
                  decoration: const InputDecoration(
                    labelText: 'Subcategoria',
                    border: OutlineInputBorder(),
                  ),
                  items: subcategories.map((subcategory) {
                    return DropdownMenuItem(
                      value: subcategory,
                      child: Text('${subcategory.icon} ${subcategory.name}'),
                    );
                  }).toList(),
                  onChanged: subcategories.isEmpty
                      ? null
                      : (value) {
                          setState(() {
                            selectedSubcategory = value;
                          });
                        },
                ),
                const SizedBox(height: AppSpacing.lg),

                RadioListTile<String>(
                  title: const Text('Receita'),
                  value: 'income',
                  groupValue: type,
                  onChanged: (value) {
                    setState(() {
                      type = value!;
                    });
                  },
                ),

                RadioListTile<String>(
                  title: const Text('Despesa'),
                  value: 'expense',
                  groupValue: type,
                  onChanged: (value) {
                    setState(() {
                      type = value!;
                    });
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Itens (${items.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openAddItemPage,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),

                if (items.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Nenhum item adicionado. Use essa área para detalhar compras de mercado, farmácia, casa e outros consumos.',
                      ),
                    ),
                  )
                else
                  Column(
                    children: items.map((item) {
                      return Card(
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.quantity.toStringAsFixed(2).replaceAll('.', ',')} ${item.unit}'
                            '${item.brand.isNotEmpty ? ' • ${item.brand}' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatMoney(item.totalPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  controller.removeItem(item);
                                },
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: AppSpacing.xl),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveTransaction,
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
