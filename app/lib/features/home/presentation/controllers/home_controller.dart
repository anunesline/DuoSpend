import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/context/wallet_context.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../../transactions/domain/purchase/services/balance_engine.dart';
import '../../../transactions/domain/purchase/services/balance_summary.dart';
import '../../data/models/partner_invite_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/partner_invite_repository.dart';
import '../../data/repositories/wallet_repository.dart';

class HomeController extends ChangeNotifier {
  static const String _defaultSharedWalletName = 'Carteira do casal';

  final FirebaseAuth _auth;
  final WalletRepository _walletRepository;
  final PartnerInviteRepository _partnerInviteRepository;
  final TransactionRepository _transactionRepository;
  final WalletContext _walletContext;
  final BalanceEngine _balanceEngine;

  HomeController({
    FirebaseAuth? auth,
    WalletRepository? walletRepository,
    PartnerInviteRepository? partnerInviteRepository,
    TransactionRepository? transactionRepository,
    WalletContext? walletContext,
    BalanceEngine? balanceEngine,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _walletRepository = walletRepository ?? WalletRepository(),
       _partnerInviteRepository =
           partnerInviteRepository ?? PartnerInviteRepository(),
       _transactionRepository =
           transactionRepository ?? TransactionRepository(),
       _walletContext = walletContext ?? WalletContext(),
       _balanceEngine = balanceEngine ?? const BalanceEngine() {
    _walletContext.addListener(_handleWalletContextChanged);
  }

  User? user;

  /// Carteira atualmente selecionada.
  ///
  /// O nome `wallet` é preservado para manter compatibilidade com as telas
  /// e widgets que já consomem o HomeController.
  ///
  /// A fonte real deste estado é o WalletContext.
  WalletModel? get wallet => _walletContext.selectedWallet;

  /// Todas as carteiras às quais o usuário autenticado possui acesso.
  ///
  /// A fonte real desta lista é o WalletContext.
  List<WalletModel> get wallets => _walletContext.wallets;

  /// Todas as transações carregadas do repositório.
  ///
  /// Esta lista é mantida internamente para permitir a troca de carteira
  /// sem exigir uma nova leitura do Firestore a cada seleção.
  List<TransactionModel> _allTransactions = [];

  /// Transações pertencentes à carteira atualmente selecionada.
  List<TransactionModel> transactions = [];

  double totalIncome = 0;
  double totalExpense = 0;

  /// Resultado bruto calculado pelo Balance Engine.
  ///
  /// Fica disponível apenas quando uma carteira compartilhada
  /// está selecionada.
  BalanceResult? balanceResult;

  bool isLoading = true;
  bool isCreatingSharedWallet = false;
  bool isSendingPartnerInvite = false;

  String? errorMessage;

  String get userName {
    final name = user?.displayName?.trim();

    if (name == null || name.isEmpty) {
      return 'usuário';
    }

    return name.split(' ').first;
  }

  String? get userPhotoUrl => user?.photoURL;

  String? get selectedWalletId => _walletContext.walletId;

  WalletUsageMode get usageMode => _walletContext.usageMode;

  bool get hasWallets => wallets.isNotEmpty;

  bool get hasMultipleWallets => wallets.length > 1;

  bool get hasSharedWallet => sharedWallets.isNotEmpty;

  bool get isSoloMode => _walletContext.isSoloMode;

  bool get isCoupleMode => _walletContext.isCoupleMode;

  bool get isIndividualWalletSelected {
    return wallet?.isIndividual ?? false;
  }

  bool get isSharedWalletSelected {
    return wallet?.isShared ?? false;
  }

  /// Resumo financeiro do membro autenticado.
  ///
  /// Retorna nulo quando:
  /// - não existe usuário autenticado;
  /// - a carteira selecionada não é compartilhada;
  /// - o Balance Engine ainda não foi calculado.
  BalanceSummary? get balanceSummary {
    final currentUserId = user?.uid;
    final currentResult = balanceResult;

    if (currentUserId == null ||
        currentUserId.isEmpty ||
        currentResult == null ||
        !isSharedWalletSelected) {
      return null;
    }

    return BalanceSummary(
      result: currentResult,
      currentMemberId: currentUserId,
    );
  }

  /// Indica se existe algum acerto pendente
  /// na carteira compartilhada selecionada.
  bool get hasPendingBalance {
    return balanceResult?.hasPendingTransfers ?? false;
  }

  bool get canInvitePartner {
    final selectedWallet = wallet;

    if (selectedWallet == null) {
      return false;
    }

    return selectedWallet.isShared &&
        selectedWallet.isOwner(user?.uid ?? '') &&
        selectedWallet.canInvitePartner;
  }

  List<WalletModel> get individualWallets {
    return List<WalletModel>.unmodifiable(
      wallets.where(
        (currentWallet) => currentWallet.isIndividual,
      ),
    );
  }

  List<WalletModel> get sharedWallets {
    return List<WalletModel>.unmodifiable(
      wallets.where(
        (currentWallet) => currentWallet.isShared,
      ),
    );
  }

  Future<void> loadHome() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      user = _auth.currentUser;

      if (user == null) {
        _clearHomeData();
        errorMessage = 'Usuário não autenticado.';
        return;
      }

      final loadedWallets = await _walletRepository.getUserWallets();
      final mainWallet = await _walletRepository.getMainWallet();
      final loadedTransactions =
          await _transactionRepository.getTransactions();

      final mergedWallets = _mergeWallets(
        loadedWallets: loadedWallets,
        mainWallet: mainWallet,
      );

      _allTransactions = List<TransactionModel>.unmodifiable(
        loadedTransactions,
      );

      final selectedWallet = _resolveSelectedWallet(
        availableWallets: mergedWallets,
        currentWalletId: wallet?.id,
        mainWallet: mainWallet,
      );

      _walletContext.initialize(
        wallets: mergedWallets,
        selectedWallet: selectedWallet,
        sharedWalletIds: mergedWallets
            .where(
              (currentWallet) => currentWallet.isShared,
            )
            .map(
              (currentWallet) => currentWallet.id,
            )
            .toSet(),
      );
    } catch (error, stackTrace) {
      debugPrint('Erro ao carregar a Home: $error');
      debugPrintStack(stackTrace: stackTrace);

      _clearHomeData();
      errorMessage = 'Não foi possível carregar os dados da Home.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectWallet(WalletModel selectedWallet) {
    _walletContext.selectWallet(selectedWallet.id);
  }

  void selectWalletById(String walletId) {
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      return;
    }

    _walletContext.selectWallet(normalizedWalletId);
  }

  void useSoloMode() {
    _walletContext.useSoloMode();
  }

  void useCoupleMode() {
    _walletContext.useCoupleMode();
  }

  Future<WalletModel?> createSharedWallet({
    String name = _defaultSharedWalletName,
  }) async {
    if (isCreatingSharedWallet) {
      return null;
    }

    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      errorMessage = 'Usuário não autenticado.';
      notifyListeners();
      return null;
    }

    final existingSharedWallet = _findOwnedSharedWallet(
      currentUser.uid,
    );

    if (existingSharedWallet != null) {
      _walletContext.registerSharedWallet(existingSharedWallet);
      return existingSharedWallet;
    }

    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      errorMessage = 'Informe um nome para a carteira compartilhada.';
      notifyListeners();
      return null;
    }

    isCreatingSharedWallet = true;
    errorMessage = null;
    notifyListeners();

    try {
      final createdWallet = await _walletRepository.createWallet(
        name: normalizedName,
        type: WalletType.shared,
      );

      _walletContext.registerSharedWallet(createdWallet);

      return createdWallet;
    } catch (error, stackTrace) {
      debugPrint('Erro ao criar carteira compartilhada: $error');
      debugPrintStack(stackTrace: stackTrace);

      errorMessage =
          'Não foi possível criar a carteira compartilhada.';

      return null;
    } finally {
      isCreatingSharedWallet = false;
      notifyListeners();
    }
  }

  Future<PartnerInviteModel?> sendPartnerInvite({
    required String invitedEmail,
  }) async {
    if (isSendingPartnerInvite) {
      return null;
    }

    final selectedWallet = wallet;
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      errorMessage = 'Usuário não autenticado.';
      notifyListeners();
      return null;
    }

    if (selectedWallet == null || !selectedWallet.isShared) {
      errorMessage =
          'Selecione uma carteira compartilhada para enviar o convite.';
      notifyListeners();
      return null;
    }

    if (!selectedWallet.isOwner(currentUser.uid)) {
      errorMessage =
          'Somente o responsável pela carteira pode convidar o parceiro.';
      notifyListeners();
      return null;
    }

    if (!selectedWallet.canInvitePartner) {
      errorMessage = 'Esta carteira já possui um parceiro.';
      notifyListeners();
      return null;
    }

    final normalizedEmail = invitedEmail.trim().toLowerCase();

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      errorMessage = 'Informe um e-mail válido.';
      notifyListeners();
      return null;
    }

    final currentUserEmail =
        currentUser.email?.trim().toLowerCase();

    if (currentUserEmail != null &&
        currentUserEmail == normalizedEmail) {
      errorMessage = 'Você não pode convidar o seu próprio e-mail.';
      notifyListeners();
      return null;
    }

    isSendingPartnerInvite = true;
    errorMessage = null;
    notifyListeners();

    try {
      return await _partnerInviteRepository.createInvite(
        walletId: selectedWallet.id,
        invitedEmail: normalizedEmail,
      );
    } catch (error, stackTrace) {
      debugPrint('Erro ao enviar convite do parceiro: $error');
      debugPrintStack(stackTrace: stackTrace);

      errorMessage = 'Não foi possível enviar o convite.';

      return null;
    } finally {
      isSendingPartnerInvite = false;
      notifyListeners();
    }
  }

  Future<void> refreshSelectedWallet() async {
    final currentWalletId = wallet?.id;

    if (currentWalletId == null || currentWalletId.isEmpty) {
      await loadHome();
      return;
    }

    try {
      final refreshedWallet = await _walletRepository.getWalletById(
        currentWalletId,
      );

      if (refreshedWallet == null) {
        await loadHome();
        return;
      }

      final refreshedWallets = List<WalletModel>.unmodifiable(
        wallets.map((currentWallet) {
          if (currentWallet.id == refreshedWallet.id) {
            return refreshedWallet;
          }

          return currentWallet;
        }),
      );

      _walletContext.updateWallets(refreshedWallets);

      if (refreshedWallet.isShared) {
        _walletContext.markWalletAsShared(refreshedWallet.id);
      } else {
        _walletContext.markWalletAsSolo(refreshedWallet.id);
      }

      _walletContext.updateSelectedWallet(refreshedWallet);
    } catch (error, stackTrace) {
      debugPrint('Erro ao atualizar a carteira selecionada: $error');
      debugPrintStack(stackTrace: stackTrace);

      errorMessage = 'Não foi possível atualizar a carteira.';
      notifyListeners();
    }
  }

  Future<void> updateSelectedWalletBalance(double balance) async {
    final selectedWallet = wallet;

    if (selectedWallet == null) {
      return;
    }

    try {
      await _walletRepository.updateBalance(
        balance,
        walletId: selectedWallet.id,
      );

      final updatedWallet = selectedWallet.copyWith(
        balance: balance,
        updatedAt: DateTime.now(),
      );

      _walletContext.updateSelectedWallet(updatedWallet);
    } catch (error, stackTrace) {
      debugPrint('Erro ao atualizar saldo da carteira: $error');
      debugPrintStack(stackTrace: stackTrace);

      errorMessage = 'Não foi possível atualizar o saldo da carteira.';
      notifyListeners();
    }
  }

  WalletModel? _findOwnedSharedWallet(String userId) {
    for (final currentWallet in sharedWallets) {
      if (currentWallet.isOwner(userId)) {
        return currentWallet;
      }
    }

    return null;
  }

  List<WalletModel> _mergeWallets({
    required List<WalletModel> loadedWallets,
    required WalletModel? mainWallet,
  }) {
    final mergedWallets = <WalletModel>[];
    final registeredIds = <String>{};

    void addWallet(WalletModel currentWallet) {
      if (currentWallet.id.isEmpty) {
        return;
      }

      if (registeredIds.add(currentWallet.id)) {
        mergedWallets.add(currentWallet);
      }
    }

    if (mainWallet != null) {
      addWallet(mainWallet);
    }

    for (final currentWallet in loadedWallets) {
      addWallet(currentWallet);
    }

    return List<WalletModel>.unmodifiable(mergedWallets);
  }

  WalletModel? _resolveSelectedWallet({
    required List<WalletModel> availableWallets,
    required String? currentWalletId,
    required WalletModel? mainWallet,
  }) {
    if (currentWalletId != null && currentWalletId.isNotEmpty) {
      for (final currentWallet in availableWallets) {
        if (currentWallet.id == currentWalletId) {
          return currentWallet;
        }
      }
    }

    if (mainWallet != null) {
      for (final currentWallet in availableWallets) {
        if (currentWallet.id == mainWallet.id) {
          return currentWallet;
        }
      }
    }

    for (final currentWallet in availableWallets) {
      if (currentWallet.isIndividual) {
        return currentWallet;
      }
    }

    if (availableWallets.isEmpty) {
      return null;
    }

    return availableWallets.first;
  }

  void _handleWalletContextChanged() {
    _applySelectedWallet();
    notifyListeners();
  }

  void _applySelectedWallet() {
    final selectedWallet = wallet;

    if (selectedWallet == null) {
      transactions = [];
      totalIncome = 0;
      totalExpense = 0;
      balanceResult = null;
      return;
    }

    transactions = List<TransactionModel>.unmodifiable(
      _allTransactions.where(
        (transaction) => transaction.walletId == selectedWallet.id,
      ),
    );

    _calculateTotals();
    _calculateSharedBalance();
  }

  void _calculateTotals() {
    var income = 0.0;
    var expense = 0.0;

    for (final transaction in transactions) {
      if (transaction.type == 'income') {
        income += transaction.value;
      } else if (transaction.type == 'expense') {
        expense += transaction.value;
      }
    }

    totalIncome = income;
    totalExpense = expense;
  }

  /// Calcula automaticamente os valores que cada membro
  /// precisa pagar ou receber.
  ///
  /// Carteiras individuais não possuem acerto financeiro
  /// entre membros, portanto o resultado é limpo.
  void _calculateSharedBalance() {
    final selectedWallet = wallet;

    if (selectedWallet == null || !selectedWallet.isShared) {
      balanceResult = null;
      return;
    }

    balanceResult = _balanceEngine.calculate(
      transactions: transactions,
      walletId: selectedWallet.id,
    );
  }

  void _clearHomeData() {
    user = null;
    _allTransactions = [];
    transactions = [];
    totalIncome = 0;
    totalExpense = 0;
    balanceResult = null;
    isCreatingSharedWallet = false;
    isSendingPartnerInvite = false;

    _walletContext.clear();
  }

  @override
  void dispose() {
    _walletContext.removeListener(_handleWalletContextChanged);
    super.dispose();
  }
}