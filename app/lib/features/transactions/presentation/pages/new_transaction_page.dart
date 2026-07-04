import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/knowledge/taxonomy/duo_taxonomy.dart';
import '../../../../shared/knowledge/taxonomy/taxonomy_item.dart';
import '../../data/models/transaction_item_model.dart';
import '../../domain/purchase/models/purchase_item_model.dart';
import '../../domain/purchase/commands/create_purchase_command.dart';
import '../controllers/purchase_controller.dart';
import '../controllers/transaction_controller.dart';
import '../widgets/purchase_items_section.dart';
import '../widgets/transaction_basic_fields_section.dart';
import '../widgets/transaction_save_button.dart';
import 'add_transaction_item_page.dart';

class NewTransactionPage extends StatefulWidget {
  const NewTransactionPage({super.key});

  @override
  State<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends State<NewTransactionPage> {
  final descriptionController = TextEditingController();
  final valueController = TextEditingController();

  final transactionController = TransactionController();
  final purchaseController = PurchaseController();

  String type = 'expense';

  TaxonomyItem selectedCategory = DuoTaxonomy.items.first;
  TaxonomyItem? selectedSubcategory =
      DuoTaxonomy.items.first.children.isNotEmpty
          ? DuoTaxonomy.items.first.children.first
          : null;

  @override
  void initState() {
    super.initState();
    _syncFinancialCategory();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    valueController.dispose();
    transactionController.dispose();
    purchaseController.dispose();
    super.dispose();
  }

  void _syncFinancialCategory() {
    purchaseController.setFinancialCategory(
      category: selectedCategory.name,
      subcategory: selectedSubcategory?.name ?? 'Sem subcategoria',
    );
  }

  void _changeCategory(TaxonomyItem category) {
    setState(() {
      selectedCategory = category;
      selectedSubcategory =
          category.children.isNotEmpty ? category.children.first : null;
    });

    _syncFinancialCategory();
  }

  void _changeSubcategory(TaxonomyItem? subcategory) {
    setState(() {
      selectedSubcategory = subcategory;
    });

    _syncFinancialCategory();
  }

  void _changeType(String value) {
    setState(() {
      type = value;
    });
  }

  Future<void> _openAddItemPage() async {
    final item = await Navigator.push<TransactionItemModel>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionItemPage(),
      ),
    );

    if (item == null) return;

    purchaseController.addTransactionItem(item);
    transactionController.addItem(item);
    _syncValueWithPurchaseTotal();
  }

  void _removeItem(PurchaseItemModel item) {
    purchaseController.removeItem(item.id);

    final transactionItem = purchaseController.toTransactionItem(
      item: item,
      transactionId: item.purchaseId,
    );

    transactionController.removeItem(transactionItem);
    _syncValueWithPurchaseTotal();
  }

  void _syncValueWithPurchaseTotal() {
    valueController.text =
        purchaseController.total.toStringAsFixed(2).replaceAll('.', ',');
  }

  Future<void> _saveTransaction() async {
    final description = descriptionController.text.trim();
    final value = double.tryParse(valueController.text.replaceAll(',', '.'));

    if (description.isEmpty || value == null) {
      _showMessage('Preencha todos os campos.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Usuário não autenticado.');
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();

    if (purchaseController.hasItems) {
      await purchaseController.completePurchase(
        CreatePurchaseCommand(
          id: id,
          userId: user.uid,
          walletId: 'principal',
          purchaseDate: DateTime.now(),
        ),
      );
      if (purchaseController.errorMessage != null) {
        _showMessage(purchaseController.errorMessage!);
        return;
      }
    }

    await transactionController.saveTransaction(
      transactionId: id,
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

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Transação'),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          transactionController,
          purchaseController,
        ]),
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TransactionBasicFieldsSection(
                  descriptionController: descriptionController,
                  valueController: valueController,
                  type: type,
                  selectedCategory: selectedCategory,
                  selectedSubcategory: selectedSubcategory,
                  onTypeChanged: _changeType,
                  onCategoryChanged: _changeCategory,
                  onSubcategoryChanged: _changeSubcategory,
                ),
                const SizedBox(height: AppSpacing.lg),
                PurchaseItemsSection(
                  items: purchaseController.items,
                  total: purchaseController.total,
                  onAddItem: _openAddItemPage,
                  onRemoveItem: _removeItem,
                ),
                const SizedBox(height: AppSpacing.xl),
                TransactionSaveButton(
                  isSaving: purchaseController.isSaving,
                  onPressed: _saveTransaction,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}