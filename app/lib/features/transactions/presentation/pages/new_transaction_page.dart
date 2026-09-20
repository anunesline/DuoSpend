import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/context/wallet_context.dart';
import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_dropdown.dart';
import '../../../../core/design_system/duo_text_field.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/knowledge/products/product_repository.dart';
import '../../../../shared/knowledge/taxonomy/duo_taxonomy.dart';
import '../../../../shared/knowledge/taxonomy/taxonomy_item.dart';
import '../../../receipt_scanner/application/receipt_transaction_item_mapper.dart';
import '../../../receipt_scanner/domain/models/receipt_transaction_draft.dart';
import '../../../receipt_scanner/presentation/pages/receipt_scanner_page.dart';
import '../../../consumers/presentation/controllers/consumer_controller.dart';
import '../../../home/data/models/credit_card_model.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../home/data/repositories/credit_card_repository.dart';
import '../../../household_routines/domain/services/household_scope_id.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/models/product_model.dart';
import '../widgets/new_transaction_surface.dart';
import '../../domain/financial_split/financial_split_configuration.dart';
import '../../domain/financial_split/financial_split_configuration_resolver.dart';
import '../../domain/financial_split/financial_split_rules.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/purchase/commands/create_purchase_command.dart';
import '../../domain/purchase/models/purchase_item_model.dart';
import '../../domain/purchase/models/purchase_model.dart';
import '../controllers/purchase_controller.dart';
import '../controllers/transaction_controller.dart';
import '../widgets/financial_split_section.dart';
import '../widgets/installment_transaction_section.dart';
import '../widgets/recurring_transaction_section.dart';
import 'add_transaction_item_page.dart';

class NewTransactionPage extends StatefulWidget {
  final String walletId;
  final ConsumerController consumerController;
  final PurchaseController purchaseController;
  final ProductRepository productRepository;
  final WalletContext walletContext;
  final ReceiptTransactionDraft? receiptDraft;

  const NewTransactionPage({
    super.key,
    required this.walletContext,
    required this.walletId,
    required this.consumerController,
    required this.purchaseController,
    required this.productRepository,
    this.receiptDraft,
  });

  @override
  State<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends State<NewTransactionPage> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TransactionController transactionController = TransactionController();
  final FinancialSplitConfigurationResolver
  _financialSplitConfigurationResolver =
      const FinancialSplitConfigurationResolver();
  final UserRepository _userRepository = UserRepository();
  final CreditCardRepository _creditCardRepository = CreditCardRepository();
  final ReceiptTransactionItemMapper _receiptItemMapper =
      const ReceiptTransactionItemMapper();

  String? _partnerDisplayName;
  String? _loadedPartnerMemberId;
  PurchaseController get purchaseController => widget.purchaseController;

  bool _moreOptions = false;
  bool _marketDetailsVisible = false;
  String type = 'expense';
  String? selectedPayerMemberId;
  String? selectedPurchaseDestination;
  String? selectedFinancialWalletId;
  String? selectedOriginWalletId;
  String selectedSplitType = FinancialSplitRules.splitTypeEqual;
  double currentUserSplitPercent = 50;
  PaymentMethod selectedPaymentMethod = PaymentMethod.pix;
  String? selectedCreditCardId;
  List<CreditCardModel> _creditCards = const [];
  bool isRecurring = false;
  String recurringFrequency = 'monthly';
  DateTime recurringStartDate = DateTime.now();
  DateTime? recurringEndDate;
  bool recurringNeverEnds = true;
  bool isInstallment = false;
  int installmentCount = 2;
  DateTime firstInstallmentDate = DateTime.now();
  DateTime transactionDate = DateTime.now();
  TaxonomyItem selectedCategory = DuoTaxonomy.items.first;
  TaxonomyItem? selectedSubcategory =
      DuoTaxonomy.items.first.children.isNotEmpty
      ? DuoTaxonomy.items.first.children.first
      : null;

  @override
  void initState() {
    super.initState();
    purchaseController.clearPurchase();
    selectedOriginWalletId = widget.walletId;
    _syncFinancialCategory();
    _applyReceiptDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFinancialWalletSelection();
      _loadCreditCards();
      _loadPartnerDisplayName();
    });
  }

  void _applyReceiptDraft() {
    final draft = widget.receiptDraft;
    if (draft == null) return;
    descriptionController.text = draft.description;
    if (draft.amount != null)
      valueController.text = draft.amount!
          .toStringAsFixed(2)
          .replaceAll('.', ',');
    if (draft.purchaseDate != null) transactionDate = draft.purchaseDate!;
    final suggestedPayment = PaymentMethod.fromValue(
      draft.paymentMethodSuggestion,
    );
    if (suggestedPayment != null) selectedPaymentMethod = suggestedPayment;
    final now = DateTime.now();
    final items = _receiptItemMapper.map(
      items: draft.items,
      category: selectedCategory.name,
      subcategory: selectedSubcategory?.name ?? 'Sem subcategoria',
      taxonomyId: selectedSubcategory?.id ?? selectedCategory.id,
      createdAt: now,
    );
    final itemsTotal = items.fold<double>(
      0,
      (total, item) => total + item.totalPrice,
    );
    final canLoadItems =
        draft.amount == null || (itemsTotal - draft.amount!).abs() < 0.01;
    if (!canLoadItems) return;
    for (final item in items) {
      purchaseController.addTransactionItem(item);
      transactionController.addItem(item);
    }
    _refreshPurchaseState();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    valueController.dispose();
    notesController.dispose();
    transactionController.dispose();
    super.dispose();
  }

  WalletModel? _resolveActiveWallet() {
    final selectedWallet = widget.walletContext.selectedWallet;
    if (selectedWallet != null && selectedWallet.id == widget.walletId)
      return selectedWallet;
    for (final wallet in widget.walletContext.wallets) {
      if (wallet.id == widget.walletId) return wallet;
    }
    return null;
  }

  WalletModel? _resolveConnectedSharedWallet({required String currentUserId}) {
    for (final wallet in widget.walletContext.sharedWallets) {
      if (!wallet.hasPartner) continue;
      if (!wallet.memberIds.contains(currentUserId)) continue;
      return wallet;
    }
    return null;
  }

  String? _resolvePartnerMemberId({
    required WalletModel wallet,
    required String currentUserId,
  }) {
    WalletModel? memberSourceWallet = wallet;
    if (!wallet.isShared || !wallet.hasPartner)
      memberSourceWallet = _resolveConnectedSharedWallet(
        currentUserId: currentUserId,
      );
    if (memberSourceWallet == null) return null;
    for (final memberId in memberSourceWallet.memberIds) {
      final normalized = memberId.trim();
      if (normalized.isNotEmpty && normalized != currentUserId)
        return normalized;
    }
    return null;
  }

  FinancialSplitConfiguration _resolveFinancialSplitConfiguration({
    required WalletModel wallet,
    required String currentUserMemberId,
  }) {
    return _financialSplitConfigurationResolver.resolve(
      isSharedWallet: wallet.isShared,
      currentUserMemberId: currentUserMemberId,
      partnerMemberId: _resolvePartnerMemberId(
        wallet: wallet,
        currentUserId: currentUserMemberId,
      ),
    );
  }

  WalletModel _resolveTransactionWallet({
    required WalletModel activeWallet,
    required String currentUserId,
    required String purchaseDestination,
  }) {
    final requiresSharedContext =
        purchaseDestination == FinancialSplitRules.purchaseForPartner ||
        purchaseDestination == FinancialSplitRules.purchaseForBoth;
    if (!requiresSharedContext) return activeWallet;
    if (activeWallet.isShared && activeWallet.hasPartner) return activeWallet;
    final sharedWallet = _resolveConnectedSharedWallet(
      currentUserId: currentUserId,
    );
    if (sharedWallet == null)
      throw Exception('Não foi possível identificar a carteira compartilhada.');
    return sharedWallet;
  }

  Future<void> _loadPartnerDisplayName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final activeWallet = _resolveActiveWallet();
    if (currentUser == null || activeWallet == null) return;
    final partnerMemberId = _resolvePartnerMemberId(
      wallet: activeWallet,
      currentUserId: currentUser.uid,
    );
    if (partnerMemberId == null || partnerMemberId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _partnerDisplayName = null;
        _loadedPartnerMemberId = null;
      });
      return;
    }
    if (_loadedPartnerMemberId == partnerMemberId &&
        _partnerDisplayName != null)
      return;
    final displayName = await _userRepository.getUserDisplayName(
      partnerMemberId,
    );
    if (!mounted) return;
    setState(() {
      _loadedPartnerMemberId = partnerMemberId;
      _partnerDisplayName = displayName;
    });
  }

  void _syncFinancialCategory() => purchaseController.setFinancialCategory(
    category: selectedCategory.name,
    subcategory: selectedSubcategory?.name ?? 'Sem subcategoria',
  );

  void _syncCategoryFromPurchaseItems() {
    final items = purchaseController.items;
    if (items.isEmpty) {
      setState(() {
        selectedCategory = DuoTaxonomy.items.first;
        selectedSubcategory = selectedCategory.children.isNotEmpty
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
      if (categoryName.isEmpty) continue;
      categoryCounts[categoryName] = (categoryCounts[categoryName] ?? 0) + 1;
      firstCategoryPosition.putIfAbsent(categoryName, () => index);
      if (subcategoryName.isEmpty) continue;
      final counts = subcategoryCountsByCategory.putIfAbsent(
        categoryName,
        () => <String, int>{},
      );
      counts[subcategoryName] = (counts[subcategoryName] ?? 0) + 1;
      firstSubcategoryPosition.putIfAbsent(
        '$categoryName::$subcategoryName',
        () => index,
      );
    }
    if (categoryCounts.isEmpty) return;
    final categoryName = categoryCounts.keys.reduce((current, next) {
      final a = categoryCounts[current] ?? 0, b = categoryCounts[next] ?? 0;
      if (b != a) return b > a ? next : current;
      return (firstCategoryPosition[next] ?? items.length) <
              (firstCategoryPosition[current] ?? items.length)
          ? next
          : current;
    });
    TaxonomyItem? category;
    for (final candidate in DuoTaxonomy.items) {
      if (candidate.name == categoryName) {
        category = candidate;
        break;
      }
    }
    if (category == null) return;
    final counts =
        subcategoryCountsByCategory[categoryName] ?? const <String, int>{};
    String? subName;
    if (counts.isNotEmpty) {
      subName = counts.keys.reduce((current, next) {
        final a = counts[current] ?? 0, b = counts[next] ?? 0;
        if (b != a) return b > a ? next : current;
        return (firstSubcategoryPosition['$categoryName::$next'] ??
                    items.length) <
                (firstSubcategoryPosition['$categoryName::$current'] ??
                    items.length)
            ? next
            : current;
      });
    }
    TaxonomyItem? sub;
    for (final candidate in category.children) {
      if (candidate.name == subName) {
        sub = candidate;
        break;
      }
    }
    final resolvedCategory = category;
    setState(() {
      selectedCategory = resolvedCategory;
      selectedSubcategory =
          sub ??
          (resolvedCategory.children.isNotEmpty
              ? resolvedCategory.children.first
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

  void _changeSubcategory(TaxonomyItem? value) {
    setState(() => selectedSubcategory = value);
    _syncFinancialCategory();
  }

  void _changeType(String value) => setState(() => type = value);
  void _changePayer(String value) => setState(() {
    selectedPayerMemberId = value;
    if (value == FirebaseAuth.instance.currentUser?.uid)
      selectedFinancialWalletId = _resolveSelectedFinancialWalletId();
  });
  void _changePurchaseDestination(String value) =>
      setState(() => selectedPurchaseDestination = value);
  void _changeSplitType(String value) => setState(() {
    selectedSplitType = value;
    if (value == FinancialSplitRules.splitTypeEqual)
      currentUserSplitPercent = 50;
  });
  void _changeCurrentUserSplitPercent(double value) =>
      setState(() => currentUserSplitPercent = value);

  List<WalletModel> _availableOriginWallets() {
    final id = FirebaseAuth.instance.currentUser?.uid;
    if (id == null || id.isEmpty) return const [];
    return widget.walletContext.wallets
        .where((wallet) => wallet.hasMember(id))
        .toList(growable: false);
  }

  List<WalletModel> _currentUserIndividualWallets() {
    final id = FirebaseAuth.instance.currentUser?.uid;
    if (id == null || id.isEmpty) return const [];
    return widget.walletContext.wallets
        .where((wallet) => wallet.isIndividual && wallet.ownerId == id)
        .toList(growable: false);
  }

  WalletModel? _resolveOriginWallet() {
    final wallets = _availableOriginWallets();
    final id = selectedOriginWalletId ?? widget.walletId;
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    return wallets.isEmpty ? _resolveActiveWallet() : wallets.first;
  }

  String? _resolveSelectedFinancialWalletId() {
    final wallets = _currentUserIndividualWallets();
    if (wallets.isEmpty) return null;
    if (selectedFinancialWalletId != null &&
        wallets.any((wallet) => wallet.id == selectedFinancialWalletId))
      return selectedFinancialWalletId;
    return wallets.first.id;
  }

  void _initializeFinancialWalletSelection() {
    if (!mounted) return;
    final id = _resolveSelectedFinancialWalletId();
    if (id != selectedFinancialWalletId)
      setState(() => selectedFinancialWalletId = id);
  }

  Future<void> _loadCreditCards() async {
    try {
      final cards = await _creditCardRepository.getActiveCards();
      if (!mounted) return;
      setState(() {
        _creditCards = cards;
        if (selectedCreditCardId == null && cards.isNotEmpty)
          selectedCreditCardId = cards.first.id;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _creditCards = const [];
        selectedCreditCardId = null;
      });
    }
  }

  void _changePaymentMethod(PaymentMethod method) => setState(() {
    selectedPaymentMethod = method;
    if (method.isCreditCard &&
        selectedCreditCardId == null &&
        _creditCards.isNotEmpty)
      selectedCreditCardId = _creditCards.first.id;
  });
  CreditCardModel? _selectedCreditCard() {
    for (final card in _creditCards) {
      if (card.id == selectedCreditCardId) return card;
    }
    return null;
  }

  void _changeRecurring(bool value) => setState(() {
    isRecurring = value;
    if (value)
      isInstallment = false;
    else {
      recurringEndDate = null;
      recurringNeverEnds = true;
    }
  });
  void _changeInstallment(bool value) => setState(() {
    isInstallment = value;
    if (value) {
      isRecurring = false;
      recurringEndDate = null;
      recurringNeverEnds = true;
    }
  });
  void _changeInstallmentCount(int value) =>
      setState(() => installmentCount = value);
  void _changeFirstInstallmentDate(DateTime value) =>
      setState(() => firstInstallmentDate = value);
  void _changeRecurringFrequency(String value) =>
      setState(() => recurringFrequency = value);
  void _changeRecurringStartDate(DateTime value) => setState(() {
    recurringStartDate = value;
    if (recurringEndDate != null && recurringEndDate!.isBefore(value))
      recurringEndDate = null;
  });
  void _changeRecurringEndDate(DateTime? value) =>
      setState(() => recurringEndDate = value);
  void _changeRecurringNeverEnds(bool value) => setState(() {
    recurringNeverEnds = value;
    if (value) recurringEndDate = null;
  });

  ({String? currentId, String? partnerId, String partnerLabel})
  _itemMemberContext() {
    final user = FirebaseAuth.instance.currentUser;
    final wallet = _resolveActiveWallet();
    if (user == null || wallet == null)
      return (
        currentId: user?.uid,
        partnerId: null,
        partnerLabel: _partnerDisplayName ?? 'Parceiro',
      );
    return (
      currentId: user.uid,
      partnerId: _resolvePartnerMemberId(
        wallet: wallet,
        currentUserId: user.uid,
      ),
      partnerLabel: _partnerDisplayName ?? 'Parceiro',
    );
  }

  Future<void> _openAddItemPage({ProductModel? product}) async {
    final members = _itemMemberContext();
    final result = await Navigator.push<TransactionItemModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionItemPage(
          initialProduct: product,
          productRepository: widget.productRepository,
          currentMemberId: members.currentId,
          partnerMemberId: members.partnerId,
          currentMemberLabel: 'Eu',
          partnerMemberLabel: members.partnerLabel,
        ),
      ),
    );
    if (!mounted || result == null) return;
    purchaseController.addTransactionItem(result);
    transactionController.addItem(result);
    _refreshPurchaseState();
    _showMessage('${result.name} adicionado.');
  }

  Future<void> _openEditItemPage(PurchaseItemModel item) async {
    final initial = purchaseController.toTransactionItem(
      item: item,
      transactionId: item.purchaseId,
    );
    final members = _itemMemberContext();
    final updated = await Navigator.push<TransactionItemModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionItemPage(
          initialItem: initial,
          productRepository: widget.productRepository,
          currentMemberId: members.currentId,
          partnerMemberId: members.partnerId,
          currentMemberLabel: 'Eu',
          partnerMemberLabel: members.partnerLabel,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    purchaseController.updateTransactionItem(
      originalItemId: item.id,
      updatedItem: updated,
    );
    transactionController.updateItem(
      originalItemId: item.id,
      updatedItem: updated,
    );
    _refreshPurchaseState();
    _showMessage('${updated.name} atualizado.');
  }

  Future<void> _createInlineItem(String name, double unitPrice) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || name.trim().isEmpty) return;
    final now = DateTime.now();
    final taxonomyId = selectedSubcategory?.id ?? selectedCategory.id;
    final candidate = ProductModel(
      id: now.microsecondsSinceEpoch.toString(),
      name: name.trim(),
      normalizedName: widget.productRepository.normalize(name),
      brand: '',
      barcode: '',
      defaultUnit: 'un',
      productCategoryId: taxonomyId,
      productCategoryName: selectedSubcategory?.name ?? selectedCategory.name,
      taxonomyId: taxonomyId,
      averagePrice: unitPrice,
      lastPrice: unitPrice,
      lastMerchantId: '',
      favorite: false,
      createdAt: now,
      updatedAt: now,
    );
    final product = await widget.productRepository.resolveLearnedProduct(
      userId: user.uid,
      candidate: candidate,
    );
    final item = TransactionItemModel(
      id: now.microsecondsSinceEpoch.toString(),
      transactionId: '',
      productId: product.id,
      name: product.name,
      brand: '',
      quantity: 1,
      unit: 'un',
      unitPrice: unitPrice,
      totalPrice: unitPrice,
      taxonomyId: taxonomyId,
      category: selectedCategory.name,
      subcategory: selectedSubcategory?.name ?? 'Sem subcategoria',
      productCategoryId: product.productCategoryId,
      productCategoryName: product.productCategoryName,
      createdAt: now,
    );
    purchaseController.addTransactionItem(item);
    transactionController.addItem(item);
    _refreshPurchaseState();
  }

  void _removeItem(PurchaseItemModel item) {
    final transactionItem = purchaseController.toTransactionItem(
      item: item,
      transactionId: item.purchaseId,
    );
    purchaseController.removeItem(item.id);
    transactionController.removeItem(transactionItem);
    _refreshPurchaseState();
    _showMessage('${item.name} removido.');
  }

  void _refreshPurchaseState() {
    _syncCategoryFromPurchaseItems();
    _syncValueWithPurchaseTotal();
  }

  void _syncValueWithPurchaseTotal() => valueController.text =
      purchaseController.total.toStringAsFixed(2).replaceAll('.', ',');
  Future<String?> _resolveConsumerId(String walletId) async {
    final selected = widget.consumerController.selectedConsumer;
    if (selected != null && selected.walletId == walletId) return selected.id;
    await widget.consumerController.initializeWallet(walletId: walletId);
    return widget.consumerController.selectedConsumer?.id;
  }

  Map<String, double>? _buildCustomMemberShares({
    required double value,
    required String currentUserId,
    required String? partnerMemberId,
  }) {
    if (selectedSplitType != FinancialSplitRules.splitTypeCustom ||
        partnerMemberId == null ||
        partnerMemberId.isEmpty)
      return null;
    final current =
        (value * currentUserSplitPercent / 100 * 100).roundToDouble() / 100;
    return {
      currentUserId: current,
      partnerMemberId: ((value - current) * 100).roundToDouble() / 100,
    };
  }

  Future<void> _saveTransaction() async {
    if (purchaseController.isSaving || transactionController.isSaving) return;
    final description =
        descriptionController.text.trim().isEmpty && purchaseController.hasItems
        ? 'Compra: ${purchaseController.items.map((item) => item.name).join(', ')}'
        : descriptionController.text.trim();
    final value = double.tryParse(valueController.text.replaceAll(',', '.'));
    if (description.isEmpty || value == null) {
      _showMessage('Preencha todos os campos.');
      return;
    }
    if (value <= 0) {
      _showMessage('Informe um valor maior que zero.');
      return;
    }
    if (purchaseController.hasItems &&
        (purchaseController.total - value).abs() > 0.009) {
      _syncValueWithPurchaseTotal();
      _showMessage('O valor foi ajustado para o total dos itens.');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Usuário não autenticado.');
      return;
    }
    final activeWallet = _resolveActiveWallet();
    if (activeWallet == null) {
      _showMessage('Não foi possível identificar a carteira selecionada.');
      return;
    }
    final originWallet = _resolveOriginWallet() ?? activeWallet;
    final config = _resolveFinancialSplitConfiguration(
      wallet: originWallet,
      currentUserMemberId: user.uid,
    );
    final payerMemberId = config.resolvePayerMemberId(selectedPayerMemberId);
    final purchaseDestination = config.resolvePurchaseDestination(
      selectedPurchaseDestination,
    );
    final partnerMemberId = config.partnerMemberId;
    if (selectedSplitType != FinancialSplitRules.splitTypeNone &&
        (partnerMemberId == null || partnerMemberId.isEmpty)) {
      _showMessage('Conecte o parceiro para dividir esta transação.');
      return;
    }
    var financialWalletId = payerMemberId == user.uid
        ? _resolveSelectedFinancialWalletId()
        : null;
    String? paymentSourceId;
    if (selectedPaymentMethod.isCreditCard) {
      if (payerMemberId != user.uid) {
        _showMessage(
          'Somente o titular pode lançar uma compra no próprio cartão.',
        );
        return;
      }
      final card = _selectedCreditCard();
      if (card == null) {
        _showMessage('Cadastre ou selecione um cartão de crédito.');
        return;
      }
      financialWalletId = card.walletId;
      paymentSourceId = card.id;
    } else if (selectedPaymentMethod.requiresPaymentSource) {
      paymentSourceId = financialWalletId;
    }
    final transactionWallet = originWallet;
    if (!selectedPaymentMethod.isCreditCard) {
      financialWalletId = transactionWallet.id;
    }
    if (financialWalletId == null) {
      _showMessage(
        'Selecione uma conta de origem para registrar esta movimentação.',
      );
      return;
    }
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final consumerId = await _resolveConsumerId(transactionWallet.id);
      PurchaseModel? completedPurchase;
      if (purchaseController.hasItems) {
        final result = await purchaseController.completePurchase(
          CreatePurchaseCommand(
            id: id,
            userId: user.uid,
            walletId: transactionWallet.id,
            consumerId: consumerId,
            purchaseDate: DateTime.now(),
          ),
        );
        if (purchaseController.errorMessage != null) {
          _showMessage(purchaseController.errorMessage!);
          return;
        }
        if (result == null) {
          _showMessage('Não foi possível concluir a compra.');
          return;
        }
        completedPurchase = result.purchase;
      }
      await transactionController.saveTransaction(
        transactionId: id,
        description: description,
        value: value,
        type: type,
        walletId: transactionWallet.id,
        wallet: transactionWallet,
        consumerId: consumerId,
        category: selectedCategory.name,
        subcategory: selectedSubcategory?.name ?? 'Sem subcategoria',
        paidByMemberId: payerMemberId,
        purchaseFor: purchaseDestination,
        partnerMemberId: partnerMemberId,
        splitType: selectedSplitType,
        memberShares: _buildCustomMemberShares(
          value: value,
          currentUserId: user.uid,
          partnerMemberId: partnerMemberId,
        ),
        isRecurring: isRecurring,
        recurringFrequency: isRecurring ? recurringFrequency : null,
        recurringStartDate: isRecurring ? recurringStartDate : null,
        recurringEndDate: isRecurring ? recurringEndDate : null,
        recurringNeverEnds: isRecurring ? recurringNeverEnds : true,
        isInstallment: isInstallment,
        installmentCount: installmentCount,
        firstInstallmentDate: isInstallment ? firstInstallmentDate : null,
        notes: notesController.text,
        financialWalletId: financialWalletId,
        paymentMethod: selectedPaymentMethod,
        paymentSourceId: paymentSourceId,
        transactionDate: transactionDate,
        householdListScopeId: HouseholdScopeId.forContext(
          currentUserId: user.uid,
          isShared:
              purchaseDestination == FinancialSplitRules.purchaseForPartner ||
              purchaseDestination == FinancialSplitRules.purchaseForBoth,
          memberIds: transactionWallet.memberIds,
        ),
      );
      if (completedPurchase != null) {
        try {
          await widget.productRepository.learnFromPurchase(
            userId: user.uid,
            purchase: completedPurchase,
          );
        } catch (error) {
          debugPrint(
            'Aprendizado de preços ignorado após a persistência financeira: '
            '$error',
          );
        }
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      _showMessage(
        transactionController.errorMessage ??
            'Não foi possível salvar a transação.',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _openReceiptScanner() async {
    final draft = await Navigator.push<ReceiptTransactionDraft>(
      context,
      MaterialPageRoute(builder: (_) => const ReceiptScannerPage()),
    );
    if (!mounted || draft == null) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NewTransactionPage(
          walletContext: widget.walletContext,
          walletId: widget.walletId,
          consumerController: widget.consumerController,
          purchaseController: widget.purchaseController,
          productRepository: widget.productRepository,
          receiptDraft: draft,
        ),
      ),
    );
  }

  Widget _buildPaymentSection({
    required bool enabled,
    VoidCallback? onSelectionChanged,
  }) => DuoCard(
    borderRadius: 20,
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      children: [
        DuoDropdown<PaymentMethod>(
          label: 'Forma de pagamento',
          value: selectedPaymentMethod,
          icon: Icons.payments_outlined,
          items: PaymentMethod.values
              .map(
                (method) =>
                    DropdownMenuItem(value: method, child: Text(method.label)),
              )
              .toList(growable: false),
          onChanged: !enabled
              ? null
              : (method) {
                  if (method != null) {
                    _changePaymentMethod(method);
                    onSelectionChanged?.call();
                  }
                },
        ),
        if (selectedPaymentMethod.isCreditCard) ...[
          const SizedBox(height: AppSpacing.lg),
          DuoDropdown<String>(
            key: ValueKey('credit-card-${selectedCreditCardId ?? 'none'}'),
            label: 'Cartão',
            value: _selectedCreditCard()?.id,
            icon: Icons.credit_card_rounded,
            helperText:
                'A compra entrará na fatura e não debitará a conta agora.',
            items: _creditCards
                .map(
                  (card) => DropdownMenuItem(
                    value: card.id,
                    child: Text(
                      card.lastFourDigits == null
                          ? card.name
                          : '${card.name} •••• ${card.lastFourDigits}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: !enabled || _creditCards.isEmpty
                ? null
                : (id) {
                    setState(() => selectedCreditCardId = id);
                    onSelectionChanged?.call();
                  },
          ),
          if (_creditCards.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('Nenhum cartão cadastrado. Adicione um pela Home.'),
            ),
        ],
      ],
    ),
  );

  bool get _isMarket =>
      type == 'expense' && selectedSubcategory?.id == 'market';
  bool get _isSaving =>
      purchaseController.isSaving || transactionController.isSaving;
  String _money(double value) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$').format(value);
  double get _value =>
      double.tryParse(valueController.text.replaceAll(',', '.')) ?? 0;
  String get _paymentLabel => selectedPaymentMethod == PaymentMethod.debitCard
      ? 'Débito à vista'
      : selectedPaymentMethod.label;

  WalletModel? get _financialWallet {
    final id = _resolveSelectedFinancialWalletId();
    for (final wallet in _currentUserIndividualWallets()) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  String get _summaryAccountName {
    if (selectedPaymentMethod.isCreditCard) {
      final walletId = _selectedCreditCard()?.walletId;
      for (final wallet in widget.walletContext.wallets) {
        if (wallet.id == walletId) return wallet.name;
      }
      return _selectedCreditCard()?.name ?? 'Não selecionada';
    }
    return _financialWallet?.name ?? 'Não selecionada';
  }

  void _changeItemQuantity(PurchaseItemModel item, double quantity) {
    if (_isSaving || !quantity.isFinite || quantity < 1) return;
    // Keep both existing controller representations in sync, just as item editing does.
    final updated = item.copyWith(
      quantity: quantity,
      totalPrice: quantity * item.unitPrice,
    );
    final transactionItem = purchaseController.toTransactionItem(
      item: updated,
      transactionId: item.purchaseId,
    );
    purchaseController.updateTransactionItem(
      originalItemId: item.id,
      updatedItem: transactionItem,
    );
    transactionController.updateItem(
      originalItemId: item.id,
      updatedItem: transactionItem,
    );
    _syncValueWithPurchaseTotal();
  }

  void _changeItemUnitPrice(PurchaseItemModel item, double unitPrice) {
    if (_isSaving || !unitPrice.isFinite || unitPrice < 0) return;
    final updated = item.copyWith(
      unitPrice: unitPrice,
      totalPrice: unitPrice * item.quantity,
    );
    final transactionItem = purchaseController.toTransactionItem(
      item: updated,
      transactionId: item.purchaseId,
    );
    purchaseController.updateTransactionItem(
      originalItemId: item.id,
      updatedItem: transactionItem,
    );
    transactionController.updateItem(
      originalItemId: item.id,
      updatedItem: transactionItem,
    );
    _syncValueWithPurchaseTotal();
  }

  void _restoreItem(PurchaseItemModel item) {
    if (_isSaving ||
        purchaseController.items.any((current) => current.id == item.id)) {
      return;
    }
    final restored = purchaseController.toTransactionItem(
      item: item,
      transactionId: item.purchaseId,
    );
    purchaseController.addTransactionItem(restored);
    transactionController.addItem(restored);
    _refreshPurchaseState();
  }

  Future<void> _openItemsSheet() async {
    if (_isSaving) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF0E141E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => NewTransactionItemsSheet(
        controller: purchaseController,
        productRepository: widget.productRepository,
        onAdd: (product) => _openAddItemPage(product: product),
        onCreateInline: _createInlineItem,
        onEdit: _openEditItemPage,
        onRemove: _removeItem,
        onRestore: _restoreItem,
        onQuantityChanged: _changeItemQuantity,
        onUnitPriceChanged: _changeItemUnitPrice,
        onScan: () {
          Navigator.pop(context);
          _openReceiptScanner();
        },
      ),
    );
  }

  Future<void> _chooseCategory() async {
    if (_isSaving) return;
    if (purchaseController.hasItems) {
      _showMessage(
        'A categoria é definida pelos itens da compra. Edite os itens para alterá-la.',
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF0E141E),
      showDragHandle: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const Text(
              'Categoria',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            for (final category in DuoTaxonomy.items)
              ExpansionTile(
                key: ValueKey(category.id),
                initiallyExpanded: category.id == selectedCategory.id,
                leading: Text(category.icon),
                title: Text(category.name),
                children: [
                  if (category.children.isEmpty)
                    ListTile(
                      title: Text('Selecionar ${category.name}'),
                      onTap: () {
                        _changeCategory(category);
                        setState(() => _marketDetailsVisible = false);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  for (final subcategory in category.children)
                    ListTile(
                      leading: Text(subcategory.icon),
                      title: Text(subcategory.name),
                      trailing: subcategory.id == selectedSubcategory?.id
                          ? const Icon(Icons.check, color: transactionAccent)
                          : null,
                      onTap: () {
                        _changeCategory(category);
                        _changeSubcategory(subcategory);
                        setState(
                          () => _marketDetailsVisible =
                              subcategory.id == 'market',
                        );
                        Navigator.pop(sheetContext);
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseWallet() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF0E141E),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('De qual conta?')),
            if (_availableOriginWallets().isEmpty)
              const ListTile(title: Text('Nenhuma conta disponível.')),
            for (final wallet in _availableOriginWallets())
              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: transactionAccent,
                ),
                title: Text(wallet.name),
                subtitle: Text(_money(wallet.balance)),
                trailing:
                    wallet.id == (selectedOriginWalletId ?? widget.walletId)
                    ? const Icon(Icons.check, color: transactionAccent)
                    : null,
                onTap: () {
                  setState(() {
                    selectedOriginWalletId = wallet.id;
                    if (wallet.isIndividual)
                      selectedFinancialWalletId = wallet.id;
                  });
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _choosePayment() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF0E141E),
      builder: (_) => StatefulBuilder(
        builder: (context, updateSheet) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPaymentSection(
                enabled: !_isSaving,
                onSelectionChanged: () => updateSheet(() {}),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Concluir'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: transactionDate,
      firstDate: DateTime(
        transactionDate.year < 2000 ? transactionDate.year : 2000,
      ),
      lastDate: DateTime(
        transactionDate.year > 2100 ? transactionDate.year : 2100,
        12,
        31,
      ),
    );
    if (!mounted || date == null) return;
    setState(() => transactionDate = date);
  }

  Future<void> _submitFromHeader() async {
    if (_isSaving) return;
    // Description remains required by the existing save flow, without inserting mock data.
    if (descriptionController.text.trim().isEmpty &&
        !purchaseController.hasItems) {
      final accepted = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: const Color(0xFF0E141E),
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Como quer identificar esta transação?',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('Salvar transação'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || accepted != true) return;
    }
    await _saveTransaction();
  }

  Widget _summaryLine(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: transactionMuted)),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(color: color ?? Colors.white),
          ),
        ),
      ],
    ),
  );

  Widget _buildCategoryCard() => TransactionPanel(
    child: Column(
      children: [
        TransactionField(
          icon: Icons.shopping_cart_outlined,
          filledIcon: true,
          label: 'Categoria',
          value: selectedCategory.name,
          detail: selectedSubcategory?.name,
          detailColor: const Color(0xFF72D6FC),
          onTap: _chooseCategory,
        ),
        if (_isMarket && _marketDetailsVisible && !purchaseController.hasItems)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TransactionPanel(
              outlined: true,
              child: InkWell(
                onTap: _openItemsSheet,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shopping_basket_outlined,
                      color: transactionAccent,
                      size: 23,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mercado', style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 5),
                          Text(
                            selectedSplitType ==
                                    FinancialSplitRules.splitTypeNone
                                ? 'Esta transação não será dividida financeiramente com seu parceiro.'
                                : 'A divisão desta despesa segue a configuração em Mais opções.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: transactionMuted,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.info_outline,
                      size: 17,
                      color: transactionAccent,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final activeWallet = _resolveActiveWallet();
    final currentUser = FirebaseAuth.instance.currentUser;
    final config = activeWallet != null && currentUser != null
        ? _resolveFinancialSplitConfiguration(
            wallet: activeWallet,
            currentUserMemberId: currentUser.uid,
          )
        : null;
    final resolvedPayer = config?.resolvePayerMemberId(selectedPayerMemberId);
    final showWallet =
        currentUser != null && selectedPaymentMethod.affectsBalanceImmediately;
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: const Color(0xFF03070C),
        colorScheme: ColorScheme.fromSeed(
          seedColor: transactionAccent,
          brightness: Brightness.dark,
        ),
        textTheme: theme.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF03070C),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              transactionController,
              purchaseController,
              valueController,
            ]),
            builder: (context, _) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      TransactionCircleButton(
                        icon: Icons.close,
                        tooltip: 'Fechar',
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nova transação',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Registre uma receita ou despesa',
                              style: TextStyle(
                                fontSize: 12,
                                color: transactionMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isSaving ? null : _submitFromHeader,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF512984),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFF7442A7)),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Salvar'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AbsorbPointer(
                    absorbing: _isSaving,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TransactionTypeTabs(
                            type: type,
                            onChanged: _changeType,
                          ),
                          const SizedBox(height: 10),
                          TransactionPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Valor',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: transactionMuted,
                                  ),
                                ),
                                TextField(
                                  controller: valueController,
                                  readOnly: purchaseController.hasItems,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    TextInputFormatter.withFunction(
                                      (oldValue, newValue) =>
                                          RegExp(
                                            r'^\d*([,.]\d{0,2})?$',
                                          ).hasMatch(newValue.text)
                                          ? newValue
                                          : oldValue,
                                    ),
                                  ],
                                  style: const TextStyle(
                                    fontSize: 30,
                                    height: 1.25,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    prefixText: r'R$ ',
                                    prefixStyle: const TextStyle(
                                      fontSize: 30,
                                      color: Colors.white,
                                    ),
                                    hintText: '0,00',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.only(
                                      bottom: 8,
                                      top: 4,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    suffixIcon: IconButton(
                                      tooltip: 'Limpar valor',
                                      onPressed: purchaseController.hasItems
                                          ? null
                                          : valueController.clear,
                                      icon: const Icon(
                                        Icons.cancel,
                                        size: 17,
                                        color: Color(0xFF757985),
                                      ),
                                    ),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFF343044),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    for (final amount in [10, 50, 100, 200])
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: OutlinedButton(
                                            onPressed:
                                                purchaseController.hasItems
                                                ? null
                                                : () => valueController.text =
                                                      (_value + amount)
                                                          .toStringAsFixed(2)
                                                          .replaceAll('.', ','),
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(0, 28),
                                              padding: EdgeInsets.zero,
                                              foregroundColor: transactionMuted,
                                              side: const BorderSide(
                                                color: Color(0xFF39274E),
                                              ),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              textStyle: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                            child: Text('+ R\$ $amount'),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (showWallet) ...[
                            const SizedBox(height: 8),
                            TransactionPanel(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          type == 'expense'
                                              ? 'De qual conta?'
                                              : 'Em qual conta?',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: transactionMuted,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _chooseWallet,
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            'Ver saldos',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: transactionAccent,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  TransactionField(
                                    icon: Icons.account_balance_wallet_outlined,
                                    value:
                                        _resolveOriginWallet()?.name ??
                                        'Selecionar conta',
                                    detail: _resolveOriginWallet() == null
                                        ? 'Nenhuma conta disponível'
                                        : _resolveOriginWallet()!.isShared
                                        ? 'Carteira compartilhada'
                                        : 'Conta individual',
                                    trailing: _resolveOriginWallet() == null
                                        ? null
                                        : Text(
                                            _money(
                                              _resolveOriginWallet()!.balance,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                    onTap: _chooseWallet,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          _buildCategoryCard(),
                          if (_isMarket && !purchaseController.hasItems)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TransactionPanel(
                                child: OutlinedButton.icon(
                                  onPressed: _openItemsSheet,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Adicionar item'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: transactionAccent,
                                    side: const BorderSide(
                                      color: Color(0xFF39274E),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (purchaseController.hasItems) ...[
                            const SizedBox(height: 8),
                            TransactionPanel(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Itens adicionados (${purchaseController.itemCount})',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: transactionMuted,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _openItemsSheet,
                                        child: const Text(
                                          'Editar',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  for (final item in purchaseController.items)
                                    InkWell(
                                      onTap: () => _openEditItemPage(item),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 7,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.shopping_bag_outlined,
                                              color: transactionAccent,
                                              size: 23,
                                            ),
                                            const SizedBox(width: 9),
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _money(item.totalPrice),
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Qtd. ${formatTransactionQuantity(item.quantity)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: transactionMuted,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Editar ${item.name}',
                                              onPressed: () =>
                                                  _openEditItemPage(item),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 17,
                                              ),
                                              color: transactionAccent,
                                              padding: const EdgeInsets.all(6),
                                              constraints: const BoxConstraints(
                                                minWidth: 30,
                                                minHeight: 30,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _openItemsSheet,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Adicionar item'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: transactionAccent,
                                        side: const BorderSide(
                                          color: Color(0xFF39274E),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TransactionPanel(
                            child: TransactionField(
                              icon: Icons.calendar_month_outlined,
                              label: 'Data',
                              value: DateFormat(
                                "d 'de' MMMM 'de' y",
                                'pt_BR',
                              ).format(transactionDate),
                              onTap: _chooseDate,
                              showChevron: false,
                              trailing: OutlinedButton(
                                onPressed: () => setState(
                                  () => transactionDate = DateTime.now(),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: transactionAccent,
                                  side: const BorderSide(
                                    color: Color(0xFF39274E),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  minimumSize: const Size(0, 30),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                                child: const Text('Hoje'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TransactionPanel(
                            child: TransactionField(
                              icon: Icons.payment_outlined,
                              label: 'Como foi o pagamento?',
                              value: _paymentLabel,
                              detail:
                                  selectedPaymentMethod
                                      .affectsBalanceImmediately
                                  ? (type == 'expense'
                                        ? 'Valor será debitado agora'
                                        : 'Valor será creditado agora')
                                  : selectedPaymentMethod.isCreditCard
                                  ? _selectedCreditCard()?.name ??
                                        'Selecione um cartão'
                                  : 'Pagamento sem débito imediato',
                              onTap: _choosePayment,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: Color(0xFF343044)),
                                ),
                                TextButton.icon(
                                  onPressed: () => setState(
                                    () => _moreOptions = !_moreOptions,
                                  ),
                                  icon: Icon(
                                    _moreOptions
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _moreOptions
                                        ? 'Menos opções'
                                        : 'Mais opções',
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: transactionAccent,
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: Color(0xFF343044)),
                                ),
                              ],
                            ),
                          ),
                          if (_moreOptions) ...[
                            TransactionPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextButton.icon(
                                    onPressed: _openReceiptScanner,
                                    icon: const Icon(
                                      Icons.document_scanner_outlined,
                                    ),
                                    label: const Text('Scanner fiscal'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (config != null)
                              FinancialSplitSection(
                                enabled: !_isSaving,
                                configuration: config,
                                selectedPayerMemberId: config
                                    .resolvePayerMemberId(
                                      selectedPayerMemberId,
                                    ),
                                selectedPurchaseDestination: config
                                    .resolvePurchaseDestination(
                                      selectedPurchaseDestination,
                                    ),
                                selectedSplitType: selectedSplitType,
                                currentUserPercent: currentUserSplitPercent,
                                partnerDisplayName: _partnerDisplayName,
                                onPayerChanged: _changePayer,
                                onPurchaseDestinationChanged:
                                    _changePurchaseDestination,
                                onSplitTypeChanged: _changeSplitType,
                                onCurrentUserPercentChanged:
                                    _changeCurrentUserSplitPercent,
                              ),
                            const SizedBox(height: 10),
                            InstallmentTransactionSection(
                              enabled: !_isSaving,
                              isInstallment: isInstallment,
                              installmentCount: installmentCount,
                              firstInstallmentDate: firstInstallmentDate,
                              onInstallmentChanged: _changeInstallment,
                              onInstallmentCountChanged:
                                  _changeInstallmentCount,
                              onFirstInstallmentDateChanged:
                                  _changeFirstInstallmentDate,
                            ),
                            const SizedBox(height: 10),
                            RecurringTransactionSection(
                              enabled: !_isSaving,
                              isRecurring: isRecurring,
                              recurringFrequency: recurringFrequency,
                              recurringStartDate: recurringStartDate,
                              recurringEndDate: recurringEndDate,
                              recurringNeverEnds: recurringNeverEnds,
                              onRecurringChanged: _changeRecurring,
                              onFrequencyChanged: _changeRecurringFrequency,
                              onStartDateChanged: _changeRecurringStartDate,
                              onEndDateChanged: _changeRecurringEndDate,
                              onNeverEndsChanged: _changeRecurringNeverEnds,
                            ),
                            const SizedBox(height: 10),
                            DuoTextField(
                              controller: notesController,
                              label: 'Observações',
                              enabled: !_isSaving,
                              maxLines: 3,
                              hintText: 'Adicione uma observação (opcional)',
                              icon: Icons.notes_outlined,
                            ),
                            const SizedBox(height: 16),
                          ],
                          TransactionPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Resumo',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 9),
                                _summaryLine(
                                  'Tipo',
                                  type == 'expense' ? 'Despesa' : 'Receita',
                                  color: type == 'expense'
                                      ? Colors.orange
                                      : const Color(0xFF4FD66C),
                                ),
                                _summaryLine('Valor', _money(_value)),
                                _summaryLine(
                                  'Conta',
                                  resolvedPayer != currentUser?.uid
                                      ? _partnerDisplayName ?? 'Parceiro'
                                      : _summaryAccountName,
                                ),
                                _summaryLine(
                                  'Categoria',
                                  selectedCategory.name,
                                ),
                                _summaryLine('Pagamento', _paymentLabel),
                                _summaryLine(
                                  'Data',
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(transactionDate),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TransactionPanel(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  color: transactionAccent,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Dica Orbit ✨',
                                        style: TextStyle(
                                          color: transactionAccent,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        selectedPaymentMethod.isCreditCard
                                            ? 'Esta movimentação entrará na fatura do cartão selecionado e aparecerá nos seus relatórios.'
                                            : selectedPaymentMethod
                                                  .affectsBalanceImmediately
                                            ? 'Esta ${type == 'expense' ? 'despesa será debitada' : 'receita será creditada'} agora na conta selecionada e aparecerá nos seus relatórios.'
                                            : 'Esta movimentação aparecerá nos seus relatórios, sem alterar o saldo disponível agora.',
                                        style: const TextStyle(
                                          color: transactionMuted,
                                          fontSize: 12,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
