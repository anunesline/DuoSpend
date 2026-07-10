import '../../data/models/transaction_item_model.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/knowledge/taxonomy/duo_taxonomy.dart';
import '../../../../shared/knowledge/taxonomy/taxonomy_item.dart';
import '../../../consumers/presentation/controllers/consumer_controller.dart';
import '../../domain/purchase/commands/create_purchase_command.dart';
import '../../domain/purchase/models/purchase_item_model.dart';
import '../controllers/purchase_controller.dart';
import '../controllers/transaction_controller.dart';
import '../widgets/purchase_items_section.dart';
import '../widgets/transaction_basic_fields_section.dart';
import '../widgets/transaction_save_button.dart';
import 'add_transaction_item_page.dart';

class NewTransactionPage extends StatefulWidget {
  final String walletId;
  final ConsumerController consumerController;
  final PurchaseController purchaseController;

  const NewTransactionPage({
    super.key,
    required this.walletId,
    required this.consumerController,
    required this.purchaseController,
  });

  @override
  State<NewTransactionPage> createState() =>
      _NewTransactionPageState();
}

class _NewTransactionPageState
    extends State<NewTransactionPage> {
  final descriptionController = TextEditingController();
  final valueController = TextEditingController();
  final transactionController = TransactionController();

  PurchaseController get purchaseController =>
      widget.purchaseController;

  String type = 'expense';

  TaxonomyItem selectedCategory = DuoTaxonomy.items.first;

  TaxonomyItem? selectedSubcategory =
      DuoTaxonomy.items.first.children.isNotEmpty
          ? DuoTaxonomy.items.first.children.first
          : null;

  @override
  void initState() {
    super.initState();

    purchaseController.clearPurchase();
    _syncFinancialCategory();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    valueController.dispose();
    transactionController.dispose();

    super.dispose();
  }

  void _syncFinancialCategory() {
    purchaseController.setFinancialCategory(
      category: selectedCategory.name,
      subcategory:
          selectedSubcategory?.name ?? 'Sem subcategoria',
    );
  }

  void _syncCategoryFromPurchaseItem(
    PurchaseItemModel item,
  ) {
    TaxonomyItem? category;
    TaxonomyItem? subcategory;

    for (final taxonomyCategory in DuoTaxonomy.items) {
      if (taxonomyCategory.name == item.financialCategory) {
        category = taxonomyCategory;

        for (final child in taxonomyCategory.children) {
          if (child.name == item.financialSubcategory) {
            subcategory = child;
            break;
          }
        }

        break;
      }
    }

    if (category == null) {
      return;
    }

    setState(() {
      selectedCategory = category!;

      selectedSubcategory = subcategory ??
          (category.children.isNotEmpty
              ? category.children.first
              : null);
    });

    _syncFinancialCategory();
  }

  void _changeCategory(TaxonomyItem category) {
    setState(() {
      selectedCategory = category;

      selectedSubcategory =
          category.children.isNotEmpty
              ? category.children.first
              : null;
    });

    _syncFinancialCategory();
  }

  void _changeSubcategory(
    TaxonomyItem? subcategory,
  ) {
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
    final item = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionItemPage(),
      ),
    );

    if (item == null ||
        item is! TransactionItemModel) {
      return;
    }

    purchaseController.addTransactionItem(item);
    transactionController.addItem(item);

    final purchaseItem =
        purchaseController.items.last;

    _syncCategoryFromPurchaseItem(purchaseItem);
    _syncValueWithPurchaseTotal();
  }

  void _removeItem(PurchaseItemModel item) {
    purchaseController.removeItem(item.id);

    final transactionItem =
        purchaseController.toTransactionItem(
      item: item,
      transactionId: item.purchaseId,
    );

    transactionController.removeItem(transactionItem);

    _syncValueWithPurchaseTotal();
  }

  void _syncValueWithPurchaseTotal() {
    valueController.text = purchaseController.total
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  Future<String?> _resolveConsumerId() async {
    final selectedConsumer =
        widget.consumerController.selectedConsumer;

    if (selectedConsumer != null) {
      return selectedConsumer.id;
    }

    await widget.consumerController.initializeWallet(
      walletId: widget.walletId,
    );

    return widget
        .consumerController
        .selectedConsumer
        ?.id;
  }

  Future<void> _saveTransaction() async {
    final description =
        descriptionController.text.trim();

    final value = double.tryParse(
      valueController.text.replaceAll(',', '.'),
    );

    if (description.isEmpty || value == null) {
      _showMessage('Preencha todos os campos.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Usuário não autenticado.');
      return;
    }

    final id = DateTime.now()
        .millisecondsSinceEpoch
        .toString();

    final consumerId = await _resolveConsumerId();

    if (purchaseController.hasItems) {
      final purchaseResult =
          await purchaseController.completePurchase(
        CreatePurchaseCommand(
          id: id,
          userId: user.uid,
          walletId: widget.walletId,
          consumerId: consumerId,
          purchaseDate: DateTime.now(),
        ),
      );

      if (purchaseController.errorMessage != null) {
        _showMessage(
          purchaseController.errorMessage!,
        );
        return;
      }

      if (purchaseResult == null) {
        _showMessage(
          'Não foi possível concluir a compra.',
        );
        return;
      }
    }

    await transactionController.saveTransaction(
      transactionId: id,
      description: description,
      value: value,
      type: type,
      walletId: widget.walletId,
      consumerId: consumerId,
      category: selectedCategory.name,
      subcategory:
          selectedSubcategory?.name ??
              'Sem subcategoria',
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                TransactionBasicFieldsSection(
                  descriptionController:
                      descriptionController,
                  valueController: valueController,
                  type: type,
                  hasPurchaseItems:
                      purchaseController.hasItems,
                  selectedCategory:
                      selectedCategory,
                  selectedSubcategory:
                      selectedSubcategory,
                  onTypeChanged: _changeType,
                  onCategoryChanged:
                      _changeCategory,
                  onSubcategoryChanged:
                      _changeSubcategory,
                ),
                const SizedBox(
                  height: AppSpacing.lg,
                ),
                PurchaseItemsSection(
                  items: purchaseController.items,
                  total: purchaseController.total,
                  onAddItem: _openAddItemPage,
                  onRemoveItem: _removeItem,
                ),
                const SizedBox(
                  height: AppSpacing.xl,
                ),
                TransactionSaveButton(
                  isSaving:
                      purchaseController.isSaving,
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