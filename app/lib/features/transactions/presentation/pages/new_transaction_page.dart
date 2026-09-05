import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/context/wallet_context.dart';
import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_dropdown.dart';
import '../../../../core/design_system/duo_page_scaffold.dart';
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
import '../../domain/financial_split/financial_split_configuration.dart';
import '../../domain/financial_split/financial_split_configuration_resolver.dart';
import '../../domain/financial_split/financial_split_rules.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/purchase/commands/create_purchase_command.dart';
import '../../domain/purchase/models/purchase_item_model.dart';
import '../controllers/purchase_controller.dart';
import '../controllers/transaction_controller.dart';
import '../widgets/financial_split_section.dart';
import '../widgets/installment_transaction_section.dart';
import '../widgets/purchase_items_section.dart';
import '../widgets/recurring_transaction_section.dart';
import '../widgets/transaction_basic_fields_section.dart';
import '../widgets/transaction_save_button.dart';
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
  final FinancialSplitConfigurationResolver _financialSplitConfigurationResolver = const FinancialSplitConfigurationResolver();
  final UserRepository _userRepository = UserRepository();
  final CreditCardRepository _creditCardRepository = CreditCardRepository();
  final ReceiptTransactionItemMapper _receiptItemMapper = const ReceiptTransactionItemMapper();

  String? _partnerDisplayName;
  String? _loadedPartnerMemberId;
  PurchaseController get purchaseController => widget.purchaseController;

  String type = 'expense';
  String? selectedPayerMemberId;
  String? selectedPurchaseDestination;
  String? selectedFinancialWalletId;
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
  TaxonomyItem? selectedSubcategory = DuoTaxonomy.items.first.children.isNotEmpty ? DuoTaxonomy.items.first.children.first : null;

  @override
  void initState() {
    super.initState();
    purchaseController.clearPurchase();
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
    if (draft.amount != null) valueController.text = draft.amount!.toStringAsFixed(2).replaceAll('.', ',');
    if (draft.purchaseDate != null) transactionDate = draft.purchaseDate!;
    final suggestedPayment = PaymentMethod.fromValue(draft.paymentMethodSuggestion);
    if (suggestedPayment != null) selectedPaymentMethod = suggestedPayment;
    final now = DateTime.now();
    final items = _receiptItemMapper.map(
      items: draft.items,
      category: selectedCategory.name,
      subcategory: selectedSubcategory?.name ?? 'Sem subcategoria',
      taxonomyId: selectedSubcategory?.id ?? selectedCategory.id,
      createdAt: now,
    );
    final itemsTotal = items.fold<double>(0, (total, item) => total + item.totalPrice);
    final canLoadItems = draft.amount == null || (itemsTotal - draft.amount!).abs() < 0.01;
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
    if (selectedWallet != null && selectedWallet.id == widget.walletId) return selectedWallet;
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

  String? _resolvePartnerMemberId({required WalletModel wallet, required String currentUserId}) {
    WalletModel? memberSourceWallet = wallet;
    if (!wallet.isShared || !wallet.hasPartner) memberSourceWallet = _resolveConnectedSharedWallet(currentUserId: currentUserId);
    if (memberSourceWallet == null) return null;
    for (final memberId in memberSourceWallet.memberIds) {
      final normalized = memberId.trim();
      if (normalized.isNotEmpty && normalized != currentUserId) return normalized;
    }
    return null;
  }

  FinancialSplitConfiguration _resolveFinancialSplitConfiguration({required WalletModel wallet, required String currentUserMemberId}) {
    return _financialSplitConfigurationResolver.resolve(
      isSharedWallet: wallet.isShared,
      currentUserMemberId: currentUserMemberId,
      partnerMemberId: _resolvePartnerMemberId(wallet: wallet, currentUserId: currentUserMemberId),
    );
  }

  WalletModel _resolveTransactionWallet({required WalletModel activeWallet, required String currentUserId, required String purchaseDestination}) {
    final requiresSharedContext = purchaseDestination == FinancialSplitRules.purchaseForPartner || purchaseDestination == FinancialSplitRules.purchaseForBoth;
    if (!requiresSharedContext) return activeWallet;
    if (activeWallet.isShared && activeWallet.hasPartner) return activeWallet;
    final sharedWallet = _resolveConnectedSharedWallet(currentUserId: currentUserId);
    if (sharedWallet == null) throw Exception('Não foi possível identificar a carteira compartilhada.');
    return sharedWallet;
  }

  Future<void> _loadPartnerDisplayName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final activeWallet = _resolveActiveWallet();
    if (currentUser == null || activeWallet == null) return;
    final partnerMemberId = _resolvePartnerMemberId(wallet: activeWallet, currentUserId: currentUser.uid);
    if (partnerMemberId == null || partnerMemberId.isEmpty) {
      if (!mounted) return;
      setState(() { _partnerDisplayName = null; _loadedPartnerMemberId = null; });
      return;
    }
    if (_loadedPartnerMemberId == partnerMemberId && _partnerDisplayName != null) return;
    final displayName = await _userRepository.getUserDisplayName(partnerMemberId);
    if (!mounted) return;
    setState(() { _loadedPartnerMemberId = partnerMemberId; _partnerDisplayName = displayName; });
  }

  void _syncFinancialCategory() => purchaseController.setFinancialCategory(category: selectedCategory.name, subcategory: selectedSubcategory?.name ?? 'Sem subcategoria');

  void _syncCategoryFromPurchaseItems() {
    final items = purchaseController.items;
    if (items.isEmpty) {
      setState(() {
        selectedCategory = DuoTaxonomy.items.first;
        selectedSubcategory = selectedCategory.children.isNotEmpty ? selectedCategory.children.first : null;
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
      final counts = subcategoryCountsByCategory.putIfAbsent(categoryName, () => <String, int>{});
      counts[subcategoryName] = (counts[subcategoryName] ?? 0) + 1;
      firstSubcategoryPosition.putIfAbsent('$categoryName::$subcategoryName', () => index);
    }
    if (categoryCounts.isEmpty) return;
    final categoryName = categoryCounts.keys.reduce((current, next) {
      final a = categoryCounts[current] ?? 0, b = categoryCounts[next] ?? 0;
      if (b != a) return b > a ? next : current;
      return (firstCategoryPosition[next] ?? items.length) < (firstCategoryPosition[current] ?? items.length) ? next : current;
    });
    TaxonomyItem? category;
    for (final candidate in DuoTaxonomy.items) { if (candidate.name == categoryName) { category = candidate; break; } }
    if (category == null) return;
    final counts = subcategoryCountsByCategory[categoryName] ?? const <String, int>{};
    String? subName;
    if (counts.isNotEmpty) {
      subName = counts.keys.reduce((current, next) {
        final a = counts[current] ?? 0, b = counts[next] ?? 0;
        if (b != a) return b > a ? next : current;
        return (firstSubcategoryPosition['$categoryName::$next'] ?? items.length) < (firstSubcategoryPosition['$categoryName::$current'] ?? items.length) ? next : current;
      });
    }
    TaxonomyItem? sub;
    for (final candidate in category.children) { if (candidate.name == subName) { sub = candidate; break; } }
    final resolvedCategory = category;
    setState(() {
      selectedCategory = resolvedCategory;
      selectedSubcategory = sub ?? (resolvedCategory.children.isNotEmpty ? resolvedCategory.children.first : null);
    });
    _syncFinancialCategory();
  }

  void _changeCategory(TaxonomyItem category) { setState(() { selectedCategory = category; selectedSubcategory = category.children.isNotEmpty ? category.children.first : null; }); _syncFinancialCategory(); }
  void _changeSubcategory(TaxonomyItem? value) { setState(() => selectedSubcategory = value); _syncFinancialCategory(); }
  void _changeType(String value) => setState(() => type = value);
  void _changePayer(String value) => setState(() { selectedPayerMemberId = value; if (value == FirebaseAuth.instance.currentUser?.uid) selectedFinancialWalletId = _resolveSelectedFinancialWalletId(); });
  void _changePurchaseDestination(String value) => setState(() => selectedPurchaseDestination = value);
  void _changeSplitType(String value) => setState(() { selectedSplitType = value; if (value == FinancialSplitRules.splitTypeEqual) currentUserSplitPercent = 50; });
  void _changeCurrentUserSplitPercent(double value) => setState(() => currentUserSplitPercent = value);

  List<WalletModel> _currentUserIndividualWallets() {
    final id = FirebaseAuth.instance.currentUser?.uid;
    if (id == null || id.isEmpty) return const [];
    return widget.walletContext.wallets.where((wallet) => wallet.isIndividual && wallet.ownerId == id).toList(growable: false);
  }

  String? _resolveSelectedFinancialWalletId() {
    final wallets = _currentUserIndividualWallets();
    if (wallets.isEmpty) return null;
    if (selectedFinancialWalletId != null && wallets.any((wallet) => wallet.id == selectedFinancialWalletId)) return selectedFinancialWalletId;
    return wallets.first.id;
  }

  void _initializeFinancialWalletSelection() { if (!mounted) return; final id = _resolveSelectedFinancialWalletId(); if (id != selectedFinancialWalletId) setState(() => selectedFinancialWalletId = id); }
  Future<void> _loadCreditCards() async { try { final cards = await _creditCardRepository.getActiveCards(); if (!mounted) return; setState(() { _creditCards = cards; if (selectedCreditCardId == null && cards.isNotEmpty) selectedCreditCardId = cards.first.id; }); } catch (_) { if (!mounted) return; setState(() { _creditCards = const []; selectedCreditCardId = null; }); } }
  void _changePaymentMethod(PaymentMethod method) => setState(() { selectedPaymentMethod = method; if (method.isCreditCard && selectedCreditCardId == null && _creditCards.isNotEmpty) selectedCreditCardId = _creditCards.first.id; });
  CreditCardModel? _selectedCreditCard() { for (final card in _creditCards) { if (card.id == selectedCreditCardId) return card; } return null; }
  void _changeRecurring(bool value) => setState(() { isRecurring = value; if (value) isInstallment = false; else { recurringEndDate = null; recurringNeverEnds = true; } });
  void _changeInstallment(bool value) => setState(() { isInstallment = value; if (value) { isRecurring = false; recurringEndDate = null; recurringNeverEnds = true; } });
  void _changeInstallmentCount(int value) => setState(() => installmentCount = value);
  void _changeFirstInstallmentDate(DateTime value) => setState(() => firstInstallmentDate = value);
  void _changeRecurringFrequency(String value) => setState(() => recurringFrequency = value);
  void _changeRecurringStartDate(DateTime value) => setState(() { recurringStartDate = value; if (recurringEndDate != null && recurringEndDate!.isBefore(value)) recurringEndDate = null; });
  void _changeRecurringEndDate(DateTime? value) => setState(() => recurringEndDate = value);
  void _changeRecurringNeverEnds(bool value) => setState(() { recurringNeverEnds = value; if (value) recurringEndDate = null; });

  ({String? currentId, String? partnerId, String partnerLabel}) _itemMemberContext() {
    final user = FirebaseAuth.instance.currentUser;
    final wallet = _resolveActiveWallet();
    if (user == null || wallet == null) return (currentId: user?.uid, partnerId: null, partnerLabel: _partnerDisplayName ?? 'Parceiro');
    return (currentId: user.uid, partnerId: _resolvePartnerMemberId(wallet: wallet, currentUserId: user.uid), partnerLabel: _partnerDisplayName ?? 'Parceiro');
  }

  Future<void> _openAddItemPage() async {
    final members = _itemMemberContext();
    final result = await Navigator.push<TransactionItemModel>(context, MaterialPageRoute(builder: (_) => AddTransactionItemPage(productRepository: widget.productRepository, currentMemberId: members.currentId, partnerMemberId: members.partnerId, currentMemberLabel: 'Eu', partnerMemberLabel: members.partnerLabel)));
    if (result == null) return;
    purchaseController.addTransactionItem(result); transactionController.addItem(result); _refreshPurchaseState(); _showMessage('${result.name} adicionado.');
  }

  Future<void> _openEditItemPage(PurchaseItemModel item) async {
    final initial = purchaseController.toTransactionItem(item: item, transactionId: item.purchaseId);
    final members = _itemMemberContext();
    final updated = await Navigator.push<TransactionItemModel>(context, MaterialPageRoute(builder: (_) => AddTransactionItemPage(initialItem: initial, productRepository: widget.productRepository, currentMemberId: members.currentId, partnerMemberId: members.partnerId, currentMemberLabel: 'Eu', partnerMemberLabel: members.partnerLabel)));
    if (updated == null) return;
    purchaseController.updateTransactionItem(originalItemId: item.id, updatedItem: updated); transactionController.updateItem(originalItemId: item.id, updatedItem: updated); _refreshPurchaseState(); _showMessage('${updated.name} atualizado.');
  }

  void _removeItem(PurchaseItemModel item) { final transactionItem = purchaseController.toTransactionItem(item: item, transactionId: item.purchaseId); purchaseController.removeItem(item.id); transactionController.removeItem(transactionItem); _refreshPurchaseState(); _showMessage('${item.name} removido.'); }
  void _refreshPurchaseState() { _syncCategoryFromPurchaseItems(); _syncValueWithPurchaseTotal(); }
  void _syncValueWithPurchaseTotal() => valueController.text = purchaseController.total.toStringAsFixed(2).replaceAll('.', ',');
  Future<String?> _resolveConsumerId(String walletId) async { final selected = widget.consumerController.selectedConsumer; if (selected != null && selected.walletId == walletId) return selected.id; await widget.consumerController.initializeWallet(walletId: walletId); return widget.consumerController.selectedConsumer?.id; }

  Map<String, double>? _buildCustomMemberShares({required double value, required String currentUserId, required String? partnerMemberId}) {
    if (selectedSplitType != FinancialSplitRules.splitTypeCustom || partnerMemberId == null || partnerMemberId.isEmpty) return null;
    final current = (value * currentUserSplitPercent / 100 * 100).roundToDouble() / 100;
    return {currentUserId: current, partnerMemberId: ((value - current) * 100).roundToDouble() / 100};
  }

  Future<void> _saveTransaction() async {
    if (purchaseController.isSaving || transactionController.isSaving) return;
    final description = descriptionController.text.trim();
    final value = double.tryParse(valueController.text.replaceAll(',', '.'));
    if (description.isEmpty || value == null) { _showMessage('Preencha todos os campos.'); return; }
    if (value <= 0) { _showMessage('Informe um valor maior que zero.'); return; }
    if (purchaseController.hasItems && (purchaseController.total - value).abs() > 0.009) { _syncValueWithPurchaseTotal(); _showMessage('O valor foi ajustado para o total dos itens.'); return; }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { _showMessage('Usuário não autenticado.'); return; }
    final activeWallet = _resolveActiveWallet();
    if (activeWallet == null) { _showMessage('Não foi possível identificar a carteira selecionada.'); return; }
    final config = _resolveFinancialSplitConfiguration(wallet: activeWallet, currentUserMemberId: user.uid);
    final payerMemberId = config.resolvePayerMemberId(selectedPayerMemberId);
    final purchaseDestination = config.resolvePurchaseDestination(selectedPurchaseDestination);
    final partnerMemberId = config.partnerMemberId;
    if (selectedSplitType != FinancialSplitRules.splitTypeNone && (partnerMemberId == null || partnerMemberId.isEmpty)) { _showMessage('Conecte o parceiro para dividir esta transação.'); return; }
    var financialWalletId = payerMemberId == user.uid ? _resolveSelectedFinancialWalletId() : null;
    String? paymentSourceId;
    if (selectedPaymentMethod.isCreditCard) {
      if (payerMemberId != user.uid) { _showMessage('Somente o titular pode lançar uma compra no próprio cartão.'); return; }
      final card = _selectedCreditCard();
      if (card == null) { _showMessage('Cadastre ou selecione um cartão de crédito.'); return; }
      financialWalletId = card.walletId; paymentSourceId = card.id;
    } else if (selectedPaymentMethod.requiresPaymentSource) { paymentSourceId = financialWalletId; }
    if (payerMemberId == user.uid && financialWalletId == null) { _showMessage('Crie uma carteira individual para registrar esta movimentação.'); return; }
    final transactionWallet = _resolveTransactionWallet(activeWallet: activeWallet, currentUserId: user.uid, purchaseDestination: purchaseDestination);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final consumerId = await _resolveConsumerId(transactionWallet.id);
      if (purchaseController.hasItems) {
        final result = await purchaseController.completePurchase(CreatePurchaseCommand(id: id, userId: user.uid, walletId: transactionWallet.id, consumerId: consumerId, purchaseDate: DateTime.now()));
        if (purchaseController.errorMessage != null) { _showMessage(purchaseController.errorMessage!); return; }
        if (result == null) { _showMessage('Não foi possível concluir a compra.'); return; }
      }
      await transactionController.saveTransaction(
        transactionId: id, description: description, value: value, type: type,
        walletId: transactionWallet.id, wallet: transactionWallet, consumerId: consumerId,
        category: selectedCategory.name, subcategory: selectedSubcategory?.name ?? 'Sem subcategoria',
        paidByMemberId: payerMemberId, purchaseFor: purchaseDestination, partnerMemberId: partnerMemberId,
        splitType: selectedSplitType, memberShares: _buildCustomMemberShares(value: value, currentUserId: user.uid, partnerMemberId: partnerMemberId),
        isRecurring: isRecurring, recurringFrequency: isRecurring ? recurringFrequency : null,
        recurringStartDate: isRecurring ? recurringStartDate : null, recurringEndDate: isRecurring ? recurringEndDate : null,
        recurringNeverEnds: isRecurring ? recurringNeverEnds : true, isInstallment: isInstallment,
        installmentCount: installmentCount, firstInstallmentDate: isInstallment ? firstInstallmentDate : null,
        notes: notesController.text, financialWalletId: financialWalletId, paymentMethod: selectedPaymentMethod,
        paymentSourceId: paymentSourceId, transactionDate: transactionDate,
        householdListScopeId: HouseholdScopeId.forContext(
          currentUserId: user.uid,
          isShared: purchaseDestination ==
                  FinancialSplitRules.purchaseForPartner ||
              purchaseDestination == FinancialSplitRules.purchaseForBoth,
          memberIds: transactionWallet.memberIds,
        ),
      );
      if (!mounted) return; Navigator.pop(context);
    } catch (_) { _showMessage(transactionController.errorMessage ?? 'Não foi possível salvar a transação.'); }
  }

  void _showMessage(String message) { if (!mounted) return; ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating)); }

  Future<void> _openReceiptScanner() async {
    final draft = await Navigator.push<ReceiptTransactionDraft>(context, MaterialPageRoute(builder: (_) => const ReceiptScannerPage()));
    if (!mounted || draft == null) return;
    await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => NewTransactionPage(walletContext: widget.walletContext, walletId: widget.walletId, consumerController: widget.consumerController, purchaseController: widget.purchaseController, productRepository: widget.productRepository, receiptDraft: draft)));
  }

  Widget _buildPaymentSection({required bool enabled}) => DuoCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(children: [
          DuoDropdown<PaymentMethod>(label: 'Forma de pagamento', value: selectedPaymentMethod, icon: Icons.payments_outlined, items: PaymentMethod.values.map((method) => DropdownMenuItem(value: method, child: Text(method.label))).toList(growable: false), onChanged: !enabled ? null : (method) { if (method != null) _changePaymentMethod(method); }),
          if (selectedPaymentMethod.isCreditCard) ...[
            const SizedBox(height: AppSpacing.lg),
            DuoDropdown<String>(key: ValueKey('credit-card-${selectedCreditCardId ?? 'none'}'), label: 'Cartão', value: _selectedCreditCard()?.id, icon: Icons.credit_card_rounded, helperText: 'A compra entrará na fatura e não debitará a conta agora.', items: _creditCards.map((card) => DropdownMenuItem(value: card.id, child: Text(card.lastFourDigits == null ? card.name : '${card.name} •••• ${card.lastFourDigits}', overflow: TextOverflow.ellipsis))).toList(growable: false), onChanged: !enabled || _creditCards.isEmpty ? null : (id) => setState(() => selectedCreditCardId = id)),
            if (_creditCards.isEmpty) const Padding(padding: EdgeInsets.only(top: 10), child: Text('Nenhum cartão cadastrado. Adicione um pela Home.')),
          ],
        ]),
      );

  Widget _buildFinancialWalletSection({required List<WalletModel> wallets, required bool enabled}) {
    final id = _resolveSelectedFinancialWalletId();
    return DuoCard(borderRadius: 20, padding: const EdgeInsets.all(AppSpacing.lg), child: DuoDropdown<String>(key: ValueKey('financial-wallet-${id ?? 'none'}'), label: type == 'expense' ? 'Saiu de' : 'Entrou em', value: id, icon: Icons.account_balance_wallet_outlined, helperText: 'Esta é a carteira cujo saldo será movimentado.', items: wallets.map((wallet) => DropdownMenuItem(value: wallet.id, child: Text(wallet.name, overflow: TextOverflow.ellipsis))).toList(growable: false), onChanged: !enabled || wallets.isEmpty ? null : (value) => setState(() => selectedFinancialWalletId = value)));
  }

  @override
  Widget build(BuildContext context) {
    final activeWallet = _resolveActiveWallet();
    final currentUser = FirebaseAuth.instance.currentUser;
    final config = activeWallet != null && currentUser != null ? _resolveFinancialSplitConfiguration(wallet: activeWallet, currentUserMemberId: currentUser.uid) : null;
    final resolvedPayer = config?.resolvePayerMemberId(selectedPayerMemberId);
    final individualWallets = _currentUserIndividualWallets();
    final showWallet = currentUser != null && resolvedPayer == currentUser.uid && selectedPaymentMethod.affectsBalanceImmediately;

    return DuoPageScaffold(
      title: 'Nova transação',
      eyebrow: 'Registre uma movimentação',
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: [IconButton(tooltip: 'Scanner fiscal', onPressed: _openReceiptScanner, icon: const Icon(Icons.document_scanner_outlined))],
      body: AnimatedBuilder(
        animation: Listenable.merge([transactionController, purchaseController]),
        builder: (context, _) {
          final isSaving = purchaseController.isSaving || transactionController.isSaving;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TransactionBasicFieldsSection(
                descriptionController: descriptionController, valueController: valueController, type: type,
                hasPurchaseItems: purchaseController.hasItems, selectedCategory: selectedCategory, selectedSubcategory: selectedSubcategory,
                onTypeChanged: _changeType, onCategoryChanged: _changeCategory, onSubcategoryChanged: _changeSubcategory,
              ),
              const SizedBox(height: 18),
              PurchaseItemsSection(
                items: purchaseController.items, total: purchaseController.total,
                onAddItem: _openAddItemPage, onEditItem: _openEditItemPage, onRemoveItem: _removeItem,
              ),
              const SizedBox(height: 24),
              const _OrbitSectionLabel(icon: Icons.payments_outlined, title: 'Pagamento', subtitle: 'Como esta movimentação será paga?'),
              const SizedBox(height: 12),
              _buildPaymentSection(enabled: !isSaving),
              if (showWallet) ...[
                const SizedBox(height: 12),
                _buildFinancialWalletSection(wallets: individualWallets, enabled: !isSaving),
              ],
              if (config != null) ...[
                const SizedBox(height: 24),
                FinancialSplitSection(
                  enabled: !isSaving, configuration: config,
                  selectedPayerMemberId: config.resolvePayerMemberId(selectedPayerMemberId),
                  selectedPurchaseDestination: config.resolvePurchaseDestination(selectedPurchaseDestination),
                  selectedSplitType: selectedSplitType, currentUserPercent: currentUserSplitPercent,
                  partnerDisplayName: _partnerDisplayName, onPayerChanged: _changePayer,
                  onPurchaseDestinationChanged: _changePurchaseDestination, onSplitTypeChanged: _changeSplitType,
                  onCurrentUserPercentChanged: _changeCurrentUserSplitPercent,
                ),
              ],
              const SizedBox(height: 24),
              InstallmentTransactionSection(enabled: !isSaving, isInstallment: isInstallment, installmentCount: installmentCount, firstInstallmentDate: firstInstallmentDate, onInstallmentChanged: _changeInstallment, onInstallmentCountChanged: _changeInstallmentCount, onFirstInstallmentDateChanged: _changeFirstInstallmentDate),
              const SizedBox(height: 12),
              RecurringTransactionSection(enabled: !isSaving, isRecurring: isRecurring, recurringFrequency: recurringFrequency, recurringStartDate: recurringStartDate, recurringEndDate: recurringEndDate, recurringNeverEnds: recurringNeverEnds, onRecurringChanged: _changeRecurring, onFrequencyChanged: _changeRecurringFrequency, onStartDateChanged: _changeRecurringStartDate, onEndDateChanged: _changeRecurringEndDate, onNeverEndsChanged: _changeRecurringNeverEnds),
              const SizedBox(height: 24),
              const _OrbitSectionLabel(icon: Icons.notes_outlined, title: 'Observações', subtitle: 'Informações adicionais, se precisar.'),
              const SizedBox(height: 10),
              DuoTextField(controller: notesController, label: 'Observações', enabled: !isSaving, maxLines: 4, hintText: 'Adicione uma observação (opcional)', icon: Icons.notes_outlined),
              const SizedBox(height: 26),
              TransactionSaveButton(isSaving: isSaving, onPressed: _saveTransaction),
            ]),
          );
        },
      ),
    );
  }
}

class _OrbitSectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OrbitSectionLabel({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)])),
      ]);
}
