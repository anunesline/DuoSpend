import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/context/wallet_context.dart';
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
import '../widgets/financial_split_section.dart';
import '../widgets/transaction_basic_fields_section.dart';
import '../widgets/transaction_save_button.dart';
import 'add_transaction_item_page.dart';

class NewTransactionPage extends StatefulWidget {
  final String walletId;
  final ConsumerController consumerController;
  final PurchaseController purchaseController;
  final ProductRepository productRepository;

  final WalletContext walletContext;

  const NewTransactionPage({
    super.key,
    required this.walletContext,
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
  String? _resolvePartnerMemberId(String currentUserId) {
    final wallet = widget.walletContext.selectedWallet;

    if (wallet == null || wallet.id != widget.walletId) {
      return null;
    }

    for (final memberId in wallet.memberIds) {
      final normalizedMemberId = memberId.trim();

      if (normalizedMemberId.isNotEmpty &&
          normalizedMemberId != currentUserId) {
        return normalizedMemberId;
      }
    }

    return null;
  }
  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController valueController = TextEditingController();

  final TransactionController transactionController = TransactionController();

  PurchaseController get purchaseController {
    return widget.purchaseController;
  }

  String type = 'expense';

  bool payerIsCurrentUser = true;

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

  void _syncCategoryFromPurchaseItems() {
    final items = purchaseController.items;

    if (items.isEmpty) {
      setState(() {
        selectedCategory = DuoTaxonomy.items.first;
        selectedSubcategory =
            selectedCategory.children.isNotEmpty
            ? selectedCategory.children.first
            : null;
      });

      _syncFinancialCategory();
      return;
    }

    final categoryCounts = <String, int>{};
    final subcategoryCountsByCategory = <String, Map<String, int>>{};
    final firstCategoryPosition = <String, int>{};
    final firstSubcategoryPosition = <String, int>{};

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final categoryName = item.financialCategory.trim();
      final subcategoryName = item.financialSubcategory.trim();

      if (categoryName.isEmpty) {
        continue;
      }

      categoryCounts[categoryName] = (categoryCounts[categoryName] ?? 0) + 1;
      firstCategoryPosition.putIfAbsent(categoryName, () => index);

      if (subcategoryName.isEmpty) {
        continue;
      }

      final subcategoryCounts = subcategoryCountsByCategory.putIfAbsent(
        categoryName,
        () => <String, int>{},
      );

      subcategoryCounts[subcategoryName] =
          (subcategoryCounts[subcategoryName] ?? 0) + 1;

      firstSubcategoryPosition.putIfAbsent(
        '$categoryName::$subcategoryName',
        () => index,
      );
    }

    if (categoryCounts.isEmpty) {
      return;
    }

    final predominantCategoryName = categoryCounts.keys.reduce((current, next) {
      final currentCount = categoryCounts[current] ?? 0;
      final nextCount = categoryCounts[next] ?? 0;

      if (nextCount > currentCount) {
        return next;
      }

      if (nextCount < currentCount) {
        return current;
      }

      final currentPosition =
          firstCategoryPosition[current] ?? items.length;
      final nextPosition = firstCategoryPosition[next] ?? items.length;

      return nextPosition < currentPosition ? next : current;
    });

    TaxonomyItem? predominantCategory;

    for (final category in DuoTaxonomy.items) {
      if (category.name == predominantCategoryName) {
        predominantCategory = category;
        break;
      }
    }

    if (predominantCategory == null) {
      return;
    }

    final subcategoryCounts =
        subcategoryCountsByCategory[predominantCategoryName] ??
        const <String, int>{};

    String? predominantSubcategoryName;

    if (subcategoryCounts.isNotEmpty) {
      predominantSubcategoryName = subcategoryCounts.keys.reduce((
        current,
        next,
      ) {
        final currentCount = subcategoryCounts[current] ?? 0;
        final nextCount = subcategoryCounts[next] ?? 0;

        if (nextCount > currentCount) {
          return next;
        }

        if (nextCount < currentCount) {
          return current;
        }

        final currentPosition =
            firstSubcategoryPosition[
                '$predominantCategoryName::$current'] ??
            items.length;

        final nextPosition =
            firstSubcategoryPosition[
                '$predominantCategoryName::$next'] ??
            items.length;

        return nextPosition < currentPosition ? next : current;
      });
    }

    TaxonomyItem? predominantSubcategory;

    for (final subcategory in predominantCategory.children) {
      if (subcategory.name == predominantSubcategoryName) {
        predominantSubcategory = subcategory;
        break;
      }
    }

    setState(() {
      selectedCategory = predominantCategory!;

      selectedSubcategory =
          predominantSubcategory ??
          (predominantCategory.children.isNotEmpty
              ? predominantCategory.children.first
              : null);
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


  void _changePayer(bool value) {
    setState(() {
      payerIsCurrentUser = value;
    });
  }

  void _changePurchaseFor(String value) {
    setState(() {
      purchaseFor = value;
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

    _syncCategoryFromPurchaseItems();
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

    _syncCategoryFromPurchaseItems();
    _syncValueWithPurchaseTotal();

    _showMessage('${updatedItem.name} atualizado.');
  }

  void _removeItem(PurchaseItemModel item) {
    final transactionItem = purchaseController.toTransactionItem(
      item: item,
      transactionId: item.purchaseId,
    );

    purchaseController.removeItem(item.id);
    transactionController.removeItem(transactionItem);

    _syncCategoryFromPurchaseItems();
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
    final partnerMemberId = _resolvePartnerMemberId(user.uid);

final needsPartner =
    purchaseFor != FinancialSplitService.purchaseForSelf ||
    !payerIsCurrentUser;

if (needsPartner && partnerMemberId == null) {
  _showMessage(
    'Adicione o parceiro à carteira antes de dividir esta transação.',
  );

  return;
}

final payerMemberId =
    payerIsCurrentUser ? user.uid : partnerMemberId!;

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
      paidByMemberId: payerMemberId,
      purchaseFor: purchaseFor,
      splitType: FinancialSplitService.splitTypeForPurchase(purchaseFor),
      memberShares: FinancialSplitService.calculateAutomaticShares(
      value: value,
      payerMemberId: payerMemberId,
      partnerMemberId: partnerMemberId,
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
                FinancialSplitSection(
                  enabled: !purchaseController.isSaving,
                  showPartnerOptions: true,
                  payerIsCurrentUser: payerIsCurrentUser,
                  purchaseFor: purchaseFor,
                  onPayerChanged: _changePayer,
                  onPurchaseForChanged: _changePurchaseFor,
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
