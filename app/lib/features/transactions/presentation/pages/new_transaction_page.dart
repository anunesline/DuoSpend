import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/context/wallet_context.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/knowledge/products/product_repository.dart';
import '../../../../shared/knowledge/taxonomy/duo_taxonomy.dart';
import '../../../../shared/knowledge/taxonomy/taxonomy_item.dart';
import '../../../consumers/presentation/controllers/consumer_controller.dart';
import '../../../home/data/models/credit_card_model.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../home/data/repositories/credit_card_repository.dart';
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
  final TextEditingController descriptionController =
      TextEditingController();

  final TextEditingController valueController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  final TransactionController transactionController =
      TransactionController();

  final FinancialSplitConfigurationResolver
      _financialSplitConfigurationResolver =
      const FinancialSplitConfigurationResolver();

  final UserRepository _userRepository = UserRepository();
  final CreditCardRepository _creditCardRepository =
      CreditCardRepository();

  String? _partnerDisplayName;
  String? _loadedPartnerMemberId;

  PurchaseController get purchaseController {
    return widget.purchaseController;
  }

  String type = 'expense';

  String? selectedPayerMemberId;

  String? selectedPurchaseDestination;

  String? selectedFinancialWalletId;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFinancialWalletSelection();
      _loadCreditCards();
      _loadPartnerDisplayName();
    });
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

    if (selectedWallet != null &&
        selectedWallet.id == widget.walletId) {
      return selectedWallet;
    }

    for (final wallet in widget.walletContext.wallets) {
      if (wallet.id == widget.walletId) {
        return wallet;
      }
    }

    return null;
  }

  WalletModel? _resolveConnectedSharedWallet({
    required String currentUserId,
  }) {
    for (final wallet in widget.walletContext.sharedWallets) {
      if (!wallet.hasPartner) {
        continue;
      }

      if (!wallet.memberIds.contains(currentUserId)) {
        continue;
      }

      return wallet;
    }

    return null;
  }

  String? _resolvePartnerMemberId({
    required WalletModel wallet,
    required String currentUserId,
  }) {
    WalletModel? memberSourceWallet = wallet;

    if (!wallet.isShared || !wallet.hasPartner) {
      memberSourceWallet = _resolveConnectedSharedWallet(
        currentUserId: currentUserId,
      );
    }

    if (memberSourceWallet == null) {
      return null;
    }

    for (final memberId in memberSourceWallet.memberIds) {
      final normalizedMemberId = memberId.trim();

      if (normalizedMemberId.isNotEmpty &&
          normalizedMemberId != currentUserId) {
        return normalizedMemberId;
      }
    }

    return null;
  }

  FinancialSplitConfiguration
      _resolveFinancialSplitConfiguration({
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
        purchaseDestination ==
                FinancialSplitRules.purchaseForPartner ||
            purchaseDestination ==
                FinancialSplitRules.purchaseForBoth;

    if (!requiresSharedContext) {
      return activeWallet;
    }

    if (activeWallet.isShared && activeWallet.hasPartner) {
      return activeWallet;
    }

    final sharedWallet = _resolveConnectedSharedWallet(
      currentUserId: currentUserId,
    );

    if (sharedWallet == null) {
      throw Exception(
        'Não foi possível identificar a carteira compartilhada.',
      );
    }

    return sharedWallet;
  }

  Future<void> _loadPartnerDisplayName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final activeWallet = _resolveActiveWallet();

    if (currentUser == null || activeWallet == null) {
      return;
    }

    final partnerMemberId = _resolvePartnerMemberId(
      wallet: activeWallet,
      currentUserId: currentUser.uid,
    );

    if (partnerMemberId == null ||
        partnerMemberId.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _partnerDisplayName = null;
        _loadedPartnerMemberId = null;
      });

      return;
    }

    if (_loadedPartnerMemberId == partnerMemberId &&
        _partnerDisplayName != null) {
      return;
    }

    final displayName =
        await _userRepository.getUserDisplayName(
      partnerMemberId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loadedPartnerMemberId = partnerMemberId;
      _partnerDisplayName = displayName;
    });
  }

  void _syncFinancialCategory() {
    purchaseController.setFinancialCategory(
      category: selectedCategory.name,
      subcategory:
          selectedSubcategory?.name ?? 'Sem subcategoria',
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
    final subcategoryCountsByCategory =
        <String, Map<String, int>>{};
    final firstCategoryPosition = <String, int>{};
    final firstSubcategoryPosition = <String, int>{};

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final categoryName = item.financialCategory.trim();
      final subcategoryName =
          item.financialSubcategory.trim();

      if (categoryName.isEmpty) {
        continue;
      }

      categoryCounts[categoryName] =
          (categoryCounts[categoryName] ?? 0) + 1;

      firstCategoryPosition.putIfAbsent(
        categoryName,
        () => index,
      );

      if (subcategoryName.isEmpty) {
        continue;
      }

      final subcategoryCounts =
          subcategoryCountsByCategory.putIfAbsent(
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

    final predominantCategoryName =
        categoryCounts.keys.reduce((current, next) {
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

      final nextPosition =
          firstCategoryPosition[next] ?? items.length;

      return nextPosition < currentPosition
          ? next
          : current;
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
      predominantSubcategoryName =
          subcategoryCounts.keys.reduce((current, next) {
        final currentCount =
            subcategoryCounts[current] ?? 0;

        final nextCount =
            subcategoryCounts[next] ?? 0;

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

        return nextPosition < currentPosition
            ? next
            : current;
      });
    }

    TaxonomyItem? predominantSubcategory;

    for (final subcategory
        in predominantCategory.children) {
      if (subcategory.name ==
          predominantSubcategoryName) {
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

  void _changePayer(String memberId) {
    setState(() {
      selectedPayerMemberId = memberId;

      final currentUserId =
          FirebaseAuth.instance.currentUser?.uid;

      if (memberId == currentUserId) {
        selectedFinancialWalletId =
            _resolveSelectedFinancialWalletId();
      }
    });
  }

  List<WalletModel> _currentUserIndividualWallets() {
    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null || currentUserId.isEmpty) {
      return const [];
    }

    return widget.walletContext.wallets
        .where(
          (wallet) =>
              wallet.isIndividual &&
              wallet.ownerId == currentUserId,
        )
        .toList(growable: false);
  }

  String? _resolveSelectedFinancialWalletId() {
    final wallets = _currentUserIndividualWallets();

    if (wallets.isEmpty) {
      return null;
    }

    final selectedId = selectedFinancialWalletId;

    if (selectedId != null &&
        wallets.any((wallet) => wallet.id == selectedId)) {
      return selectedId;
    }

    return wallets.first.id;
  }

  void _initializeFinancialWalletSelection() {
    if (!mounted) {
      return;
    }

    final resolvedWalletId =
        _resolveSelectedFinancialWalletId();

    if (resolvedWalletId == selectedFinancialWalletId) {
      return;
    }

    setState(() {
      selectedFinancialWalletId = resolvedWalletId;
    });
  }

  Future<void> _loadCreditCards() async {
    try {
      final cards =
          await _creditCardRepository.getActiveCards();

      if (!mounted) {
        return;
      }

      setState(() {
        _creditCards = cards;

        if (selectedCreditCardId == null &&
            cards.isNotEmpty) {
          selectedCreditCardId = cards.first.id;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _creditCards = const [];
        selectedCreditCardId = null;
      });
    }
  }

  void _changePaymentMethod(PaymentMethod method) {
    setState(() {
      selectedPaymentMethod = method;

      if (method.isCreditCard &&
          selectedCreditCardId == null &&
          _creditCards.isNotEmpty) {
        selectedCreditCardId = _creditCards.first.id;
      }
    });
  }

  CreditCardModel? _selectedCreditCard() {
    final selectedId = selectedCreditCardId;

    if (selectedId == null) {
      return null;
    }

    for (final card in _creditCards) {
      if (card.id == selectedId) {
        return card;
      }
    }

    return null;
  }

  void _changePurchaseDestination(String value) {
    setState(() {
      selectedPurchaseDestination = value;
    });
  }

  void _changeRecurring(bool value) {
    setState(() {
      isRecurring = value;

      if (value) {
        isInstallment = false;
      } else {
        recurringEndDate = null;
        recurringNeverEnds = true;
      }
    });
  }

  void _changeInstallment(bool value) {
    setState(() {
      isInstallment = value;

      if (value) {
        isRecurring = false;
        recurringEndDate = null;
        recurringNeverEnds = true;
      }
    });
  }

  void _changeInstallmentCount(int value) {
    setState(() {
      installmentCount = value;
    });
  }

  void _changeFirstInstallmentDate(DateTime value) {
    setState(() {
      firstInstallmentDate = value;
    });
  }

  void _changeRecurringFrequency(String value) {
    setState(() {
      recurringFrequency = value;
    });
  }

  void _changeRecurringStartDate(DateTime value) {
    setState(() {
      recurringStartDate = value;

      if (recurringEndDate != null &&
          recurringEndDate!.isBefore(value)) {
        recurringEndDate = null;
      }
    });
  }

  void _changeRecurringEndDate(DateTime? value) {
    setState(() {
      recurringEndDate = value;
    });
  }

  void _changeRecurringNeverEnds(bool value) {
    setState(() {
      recurringNeverEnds = value;

      if (value) {
        recurringEndDate = null;
      }
    });
  }

  Future<void> _openAddItemPage() async {
    final result =
        await Navigator.push<TransactionItemModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionItemPage(
          productRepository: widget.productRepository,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    purchaseController.addTransactionItem(result);
    transactionController.addItem(result);

    _refreshPurchaseState();
    _showMessage('${result.name} adicionado.');
  }

  Future<void> _openEditItemPage(
    PurchaseItemModel purchaseItem,
  ) async {
    final initialTransactionItem =
        purchaseController.toTransactionItem(
      item: purchaseItem,
      transactionId: purchaseItem.purchaseId,
    );

    final updatedItem =
        await Navigator.push<TransactionItemModel>(
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

    _refreshPurchaseState();
    _showMessage('${updatedItem.name} atualizado.');
  }

  void _removeItem(PurchaseItemModel item) {
    final transactionItem =
        purchaseController.toTransactionItem(
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

  void _syncValueWithPurchaseTotal() {
    valueController.text = purchaseController.total
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  Future<String?> _resolveConsumerId(
    String walletId,
  ) async {
    final selectedConsumer =
        widget.consumerController.selectedConsumer;

    if (selectedConsumer != null &&
        selectedConsumer.walletId == walletId) {
      return selectedConsumer.id;
    }

    await widget.consumerController.initializeWallet(
      walletId: walletId,
    );

    return widget
        .consumerController.selectedConsumer?.id;
  }

  Future<void> _saveTransaction() async {
    if (purchaseController.isSaving ||
        transactionController.isSaving) {
      return;
    }

    final description =
        descriptionController.text.trim();

    final value = double.tryParse(
      valueController.text.replaceAll(',', '.'),
    );

    if (description.isEmpty || value == null) {
      _showMessage('Preencha todos os campos.');
      return;
    }

    if (value <= 0) {
      _showMessage('Informe um valor maior que zero.');
      return;
    }

    if (purchaseController.hasItems) {
      final purchaseTotal = purchaseController.total;
      final difference = (purchaseTotal - value).abs();

      if (difference > 0.009) {
        _syncValueWithPurchaseTotal();
        _showMessage(
          'O valor foi ajustado para o total dos itens.',
        );
        return;
      }
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Usuário não autenticado.');
      return;
    }

    final activeWallet = _resolveActiveWallet();

    if (activeWallet == null) {
      _showMessage(
        'Não foi possível identificar a carteira selecionada.',
      );

      return;
    }

    final financialSplitConfiguration =
        _resolveFinancialSplitConfiguration(
      wallet: activeWallet,
      currentUserMemberId: user.uid,
    );

    final payerMemberId =
        financialSplitConfiguration.resolvePayerMemberId(
      selectedPayerMemberId,
    );

    final purchaseDestination =
        financialSplitConfiguration
            .resolvePurchaseDestination(
      selectedPurchaseDestination,
    );

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

      final selectedCard = _selectedCreditCard();

      if (selectedCard == null) {
        _showMessage(
          'Cadastre ou selecione um cartão de crédito.',
        );
        return;
      }

      financialWalletId = selectedCard.walletId;
      paymentSourceId = selectedCard.id;
    } else if (selectedPaymentMethod.requiresPaymentSource) {
      paymentSourceId = financialWalletId;
    }

    if (payerMemberId == user.uid &&
        financialWalletId == null) {
      _showMessage(
        'Crie uma carteira individual para registrar esta movimentação.',
      );
      return;
    }

    final transactionWallet = _resolveTransactionWallet(
      activeWallet: activeWallet,
      currentUserId: user.uid,
      purchaseDestination: purchaseDestination,
    );

    final id =
        DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final consumerId =
          await _resolveConsumerId(transactionWallet.id);

      if (purchaseController.hasItems) {
        final purchaseResult =
            await purchaseController.completePurchase(
          CreatePurchaseCommand(
            id: id,
            userId: user.uid,
            walletId: transactionWallet.id,
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
        walletId: transactionWallet.id,
        wallet: transactionWallet,
        consumerId: consumerId,
        category: selectedCategory.name,
        subcategory:
            selectedSubcategory?.name ??
            'Sem subcategoria',
        paidByMemberId: payerMemberId,
        purchaseFor: purchaseDestination,
        partnerMemberId:
            financialSplitConfiguration.partnerMemberId,
        isRecurring: isRecurring,
        recurringFrequency:
            isRecurring ? recurringFrequency : null,
        recurringStartDate:
            isRecurring ? recurringStartDate : null,
        recurringEndDate:
            isRecurring ? recurringEndDate : null,
        recurringNeverEnds:
            isRecurring ? recurringNeverEnds : true,
        isInstallment: isInstallment,
        installmentCount: installmentCount,
        firstInstallmentDate:
            isInstallment ? firstInstallmentDate : null,
        notes: notesController.text,
        financialWalletId: financialWalletId,
        paymentMethod: selectedPaymentMethod,
        paymentSourceId: paymentSourceId,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } catch (_) {
      final errorMessage =
          transactionController.errorMessage;

      _showMessage(
        errorMessage ??
            'Não foi possível salvar a transação.',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _buildPaymentSection({
    required bool enabled,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            DropdownButtonFormField<PaymentMethod>(
              initialValue: selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Forma de pagamento',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              items: PaymentMethod.values.map((method) {
                return DropdownMenuItem<PaymentMethod>(
                  value: method,
                  child: Text(method.label),
                );
              }).toList(growable: false),
              onChanged: !enabled
                  ? null
                  : (method) {
                      if (method != null) {
                        _changePaymentMethod(method);
                      }
                    },
            ),
            if (selectedPaymentMethod.isCreditCard) ...[
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'credit-card-${selectedCreditCardId ?? 'none'}',
                ),
                initialValue: _selectedCreditCard()?.id,
                decoration: const InputDecoration(
                  labelText: 'Cartão',
                  prefixIcon: Icon(Icons.credit_card_rounded),
                  helperText:
                      'A compra entrará na fatura e não debitará a conta agora.',
                ),
                items: _creditCards.map((card) {
                  return DropdownMenuItem<String>(
                    value: card.id,
                    child: Text(
                      card.lastFourDigits == null
                          ? card.name
                          : '${card.name} •••• ${card.lastFourDigits}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(growable: false),
                onChanged: !enabled || _creditCards.isEmpty
                    ? null
                    : (cardId) {
                        setState(() {
                          selectedCreditCardId = cardId;
                        });
                      },
              ),
              if (_creditCards.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Nenhum cartão cadastrado. Adicione um pela Home.',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialWalletSection({
    required List<WalletModel> wallets,
    required bool enabled,
  }) {
    final selectedWalletId =
        _resolveSelectedFinancialWalletId();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: DropdownButtonFormField<String>(
          key: ValueKey(
            'financial-wallet-${selectedWalletId ?? 'none'}',
          ),
          initialValue: selectedWalletId,
          decoration: InputDecoration(
            labelText: type == 'expense'
                ? 'Saiu de'
                : 'Entrou em',
            prefixIcon:
                const Icon(Icons.account_balance_wallet_outlined),
            helperText:
                'Esta é a carteira cujo saldo será movimentado.',
          ),
          items: wallets.map((wallet) {
            return DropdownMenuItem<String>(
              value: wallet.id,
              child: Text(
                wallet.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(growable: false),
          onChanged: !enabled || wallets.isEmpty
              ? null
              : (walletId) {
                  setState(() {
                    selectedFinancialWalletId = walletId;
                  });
                },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeWallet = _resolveActiveWallet();
    final currentUser = FirebaseAuth.instance.currentUser;

    final financialSplitConfiguration =
        activeWallet != null && currentUser != null
            ? _resolveFinancialSplitConfiguration(
                wallet: activeWallet,
                currentUserMemberId: currentUser.uid,
              )
            : null;
    final resolvedPayerMemberId =
        financialSplitConfiguration?.resolvePayerMemberId(
      selectedPayerMemberId,
    );
    final currentUserIndividualWallets =
        _currentUserIndividualWallets();
    final shouldShowFinancialWallet =
        currentUser != null &&
        resolvedPayerMemberId == currentUser.uid &&
        selectedPaymentMethod.affectsBalanceImmediately;

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
          final isSaving =
              purchaseController.isSaving ||
              transactionController.isSaving;

          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(AppSpacing.lg),
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
                if (financialSplitConfiguration != null)
                  FinancialSplitSection(
                    enabled: !isSaving,
                    configuration:
                        financialSplitConfiguration,
                    selectedPayerMemberId:
                        financialSplitConfiguration
                            .resolvePayerMemberId(
                      selectedPayerMemberId,
                    ),
                    selectedPurchaseDestination:
                        financialSplitConfiguration
                            .resolvePurchaseDestination(
                      selectedPurchaseDestination,
                    ),
                    partnerDisplayName:
                        _partnerDisplayName,
                    onPayerChanged: _changePayer,
                    onPurchaseDestinationChanged:
                        _changePurchaseDestination,
                  ),
                const SizedBox(
                  height: AppSpacing.lg,
                ),
                _buildPaymentSection(
                  enabled: !isSaving,
                ),
                const SizedBox(
                  height: AppSpacing.lg,
                ),
                if (shouldShowFinancialWallet)
                  _buildFinancialWalletSection(
                    wallets: currentUserIndividualWallets,
                    enabled: !isSaving,
                  ),
                if (shouldShowFinancialWallet)
                  const SizedBox(
                    height: AppSpacing.lg,
                  ),
                InstallmentTransactionSection(
                  enabled: !isSaving,
                  isInstallment: isInstallment,
                  installmentCount: installmentCount,
                  firstInstallmentDate: firstInstallmentDate,
                  onInstallmentChanged: _changeInstallment,
                  onInstallmentCountChanged:
                      _changeInstallmentCount,
                  onFirstInstallmentDateChanged:
                      _changeFirstInstallmentDate,
                ),
                const SizedBox(
                  height: AppSpacing.lg,
                ),
                RecurringTransactionSection(
                  enabled: !isSaving,
                  isRecurring: isRecurring,
                  recurringFrequency:
                      recurringFrequency,
                  recurringStartDate:
                      recurringStartDate,
                  recurringEndDate:
                      recurringEndDate,
                  recurringNeverEnds:
                      recurringNeverEnds,
                  onRecurringChanged:
                      _changeRecurring,
                  onFrequencyChanged:
                      _changeRecurringFrequency,
                  onStartDateChanged:
                      _changeRecurringStartDate,
                  onEndDateChanged:
                      _changeRecurringEndDate,
                  onNeverEndsChanged:
                      _changeRecurringNeverEnds,
                ),
                const SizedBox(
                  height: AppSpacing.lg,
                ),
                PurchaseItemsSection(
                  items: purchaseController.items,
                  total: purchaseController.total,
                  onAddItem: _openAddItemPage,
                  onEditItem: _openEditItemPage,
                  onRemoveItem: _removeItem,
                ),
                const SizedBox(
                  height: AppSpacing.lg,
                ),
                TextField(
                  controller: notesController,
                  enabled: !isSaving,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization:
                      TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    hintText:
                        'Adicione alguma informação importante (opcional)',
                    alignLabelWithHint: true,
                    prefixIcon:
                        Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(
                  height: AppSpacing.xl,
                ),
                TransactionSaveButton(
                  isSaving: isSaving,
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