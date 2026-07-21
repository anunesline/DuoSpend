import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/knowledge/products/product_repository.dart';
import '../../../../shared/knowledge/taxonomy/duo_taxonomy.dart';
import '../../../../shared/knowledge/taxonomy/taxonomy_item.dart';
import '../../../consumers/presentation/controllers/consumer_controller.dart';
import '../../data/models/transaction_item_model.dart';
import '../../domain/purchase/commands/create_purchase_command.dart';
import '../../domain/purchase/models/purchase_item_model.dart';
import '../../domain/purchase/services/financial_split_service.dart';
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
  final ProductRepository productRepository;

  const NewTransactionPage({
    super.key,
    required this.walletId,
    required this.consumerController,
    required this.purchaseController,
    required this.productRepository,
  });

  @override
  State<NewTransactionPage> createState() {
    return _NewTransactionPageState();
  }
}

class _NewTransactionPageState extends State<NewTransactionPage> {
  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController valueController = TextEditingController();

  final TransactionController transactionController = TransactionController();

  PurchaseController get purchaseController {
    return widget.purchaseController;
  }

  String type = 'expense';

  String purchaseFor = FinancialSplitService.purchaseForSelf;

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
      subcategory: selectedSubcategory?.name ?? 'Sem subcategoria',
    );
  }

  void _syncCategoryFromPurchaseItem(PurchaseItemModel item) {
    TaxonomyItem? category;
    TaxonomyItem? subcategory;

    for (final taxonomyCategory in DuoTaxonomy.items) {
      if (taxonomyCategory.name != item.financialCategory) {
        continue;
      }

      category = taxonomyCategory;

      for (final child in taxonomyCategory.children) {
        if (child.name == item.financialSubcategory) {
          subcategory = child;
          break;
        }
      }

      break;
    }

    if (category == null) {
      return;
    }

    setState(() {
      selectedCategory = category!;

      selectedSubcategory =
          subcategory ??
          (category.children.isNotEmpty ? category.children.first : null);
    });

    _syncFinancialCategory();
  }

  void _changeCategory(TaxonomyItem category) {
    setState(() {
      selectedCategory = category;

      selectedSubcategory = category.children.isNotEmpty
          ? category.children.first
          : null;
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
    final result = await Navigator.push<TransactionItemModel>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddTransactionItemPage(productRepository: widget.productRepository),
      ),
    );

    if (result == null) {
      return;
    }

    purchaseController.addTransactionItem(result);
    transactionController.addItem(result);

    final addedPurchaseItem = purchaseController.items.last;

    _syncCategoryFromPurchaseItem(addedPurchaseItem);
    _syncValueWithPurchaseTotal();
  }

  Future<void> _openEditItemPage(PurchaseItemModel purchaseItem) async {
    final initialTransactionItem = purchaseController.toTransactionItem(
      item: purchaseItem,
      transactionId: purchaseItem.purchaseId,
    );

    final updatedItem = await Navigator.push<TransactionItemModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionItemPage(
          initialItem: initialTransactionItem,
          productRepository: widget.productRepository,
        ),
      ),
    );

    if (updatedItem == null) {
      return;
    }

    purchaseController.updateTransactionItem(
      originalItemId: purchaseItem.id,
      updatedItem: updatedItem,
    );

    transactionController.updateItem(
      originalItemId: purchaseItem.id,
      updatedItem: updatedItem,
    );

    final updatedPurchaseItem = _findPurchaseItemById(purchaseItem.id);

    if (updatedPurchaseItem != null) {
      _syncCategoryFromPurchaseItem(updatedPurchaseItem);
    }

    _syncValueWithPurchaseTotal();

    _showMessage('${updatedItem.name} atualizado.');
  }

  PurchaseItemModel? _findPurchaseItemById(String itemId) {
    for (final item in purchaseController.items) {
      if (item.id == itemId) {
        return item;
      }
    }

    return null;
  }

  void _removeItem(PurchaseItemModel item) {
    final transactionItem = purchaseController.toTransactionItem(
      item: item,
      transactionId: item.purchaseId,
    );

    purchaseController.removeItem(item.id);
    transactionController.removeItem(transactionItem);

    _syncValueWithPurchaseTotal();
  }

  void _syncValueWithPurchaseTotal() {
    valueController.text = purchaseController.total
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  Future<String?> _resolveConsumerId() async {
    final selectedConsumer = widget.consumerController.selectedConsumer;

    if (selectedConsumer != null) {
      return selectedConsumer.id;
    }

    await widget.consumerController.initializeWallet(walletId: widget.walletId);

    return widget.consumerController.selectedConsumer?.id;
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

    final consumerId = await _resolveConsumerId();

    if (purchaseController.hasItems) {
      final purchaseResult = await purchaseController.completePurchase(
        CreatePurchaseCommand(
          id: id,
          userId: user.uid,
          walletId: widget.walletId,
          consumerId: consumerId,
          purchaseDate: DateTime.now(),
        ),
      );

      if (purchaseController.errorMessage != null) {
        _showMessage(purchaseController.errorMessage!);

        return;
      }

      if (purchaseResult == null) {
        _showMessage('Não foi possível concluir a compra.');

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
      subcategory: selectedSubcategory?.name ?? 'Sem subcategoria',
      paidByMemberId: user.uid,
      purchaseFor: purchaseFor,
      splitType: FinancialSplitService.splitTypeForPurchase(purchaseFor),
      memberShares: FinancialSplitService.calculateAutomaticShares(
        value: value,
        payerMemberId: user.uid,
        purchaseFor: purchaseFor,
      ),
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

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Transação')),
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
                  hasPurchaseItems: purchaseController.hasItems,
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
                  onEditItem: _openEditItemPage,
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
