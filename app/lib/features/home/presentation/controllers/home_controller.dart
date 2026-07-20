import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/wallet_repository.dart';

class HomeController extends ChangeNotifier {
  final FirebaseAuth _auth;
  final WalletRepository _walletRepository;
  final TransactionRepository _transactionRepository;

  HomeController({
    FirebaseAuth? auth,
    WalletRepository? walletRepository,
    TransactionRepository? transactionRepository,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _walletRepository = walletRepository ?? WalletRepository(),
       _transactionRepository =
           transactionRepository ?? TransactionRepository();

  User? user;

  /// Carteira atualmente selecionada na Home.
  ///
  /// Mantemos o nome `wallet` para preservar compatibilidade com a
  /// interface e com os widgets que já dependem deste controller.
  WalletModel? wallet;

  /// Todas as carteiras às quais o usuário autenticado possui acesso.
  List<WalletModel> wallets = [];

  /// Todas as transações carregadas do repositório.
  ///
  /// Esta lista é mantida internamente para permitir a troca de carteira
  /// sem exigir uma nova leitura do Firestore a cada seleção.
  List<TransactionModel> _allTransactions = [];

  /// Transações pertencentes à carteira atualmente selecionada.
  List<TransactionModel> transactions = [];

  double totalIncome = 0;
  double totalExpense = 0;

  bool isLoading = true;
  String? errorMessage;

  String get userName {
    final name = user?.displayName?.trim();

    if (name == null || name.isEmpty) {
      return 'usuário';
    }

    return name.split(' ').first;
  }

  String? get userPhotoUrl => user?.photoURL;

  String? get selectedWalletId => wallet?.id;

  bool get hasWallets => wallets.isNotEmpty;

  bool get hasMultipleWallets => wallets.length > 1;

  bool get isIndividualWalletSelected {
    return wallet?.isIndividual ?? false;
  }

  bool get isSharedWalletSelected {
    return wallet?.isShared ?? false;
  }

  List<WalletModel> get individualWallets {
    return List<WalletModel>.unmodifiable(
      wallets.where((currentWallet) => currentWallet.isIndividual),
    );
  }

  List<WalletModel> get sharedWallets {
    return List<WalletModel>.unmodifiable(
      wallets.where((currentWallet) => currentWallet.isShared),
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
      final loadedTransactions = await _transactionRepository.getTransactions();

      wallets = _mergeWallets(
        loadedWallets: loadedWallets,
        mainWallet: mainWallet,
      );

      _allTransactions = List<TransactionModel>.unmodifiable(
        loadedTransactions,
      );

      wallet = _resolveSelectedWallet(
        currentWalletId: wallet?.id,
        mainWallet: mainWallet,
      );

      _applySelectedWallet();
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
    final walletExists = wallets.any(
      (currentWallet) => currentWallet.id == selectedWallet.id,
    );

    if (!walletExists) {
      return;
    }

    if (wallet?.id == selectedWallet.id) {
      return;
    }

    wallet = selectedWallet;
    _applySelectedWallet();
    notifyListeners();
  }

  void selectWalletById(String walletId) {
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      return;
    }

    for (final currentWallet in wallets) {
      if (currentWallet.id == normalizedWalletId) {
        selectWallet(currentWallet);
        return;
      }
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

      wallets = List<WalletModel>.unmodifiable(
        wallets.map((currentWallet) {
          if (currentWallet.id == refreshedWallet.id) {
            return refreshedWallet;
          }

          return currentWallet;
        }),
      );

      wallet = refreshedWallet;
      _applySelectedWallet();
      notifyListeners();
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

      wallets = List<WalletModel>.unmodifiable(
        wallets.map((currentWallet) {
          if (currentWallet.id == updatedWallet.id) {
            return updatedWallet;
          }

          return currentWallet;
        }),
      );

      wallet = updatedWallet;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Erro ao atualizar saldo da carteira: $error');
      debugPrintStack(stackTrace: stackTrace);

      errorMessage = 'Não foi possível atualizar o saldo da carteira.';
      notifyListeners();
    }
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
    required String? currentWalletId,
    required WalletModel? mainWallet,
  }) {
    if (currentWalletId != null && currentWalletId.isNotEmpty) {
      for (final currentWallet in wallets) {
        if (currentWallet.id == currentWalletId) {
          return currentWallet;
        }
      }
    }

    if (mainWallet != null) {
      for (final currentWallet in wallets) {
        if (currentWallet.id == mainWallet.id) {
          return currentWallet;
        }
      }
    }

    for (final currentWallet in wallets) {
      if (currentWallet.isIndividual) {
        return currentWallet;
      }
    }

    if (wallets.isEmpty) {
      return null;
    }

    return wallets.first;
  }

  void _applySelectedWallet() {
    final selectedWallet = wallet;

    if (selectedWallet == null) {
      transactions = [];
      totalIncome = 0;
      totalExpense = 0;
      return;
    }

    transactions = List<TransactionModel>.unmodifiable(
      _allTransactions.where(
        (transaction) => transaction.walletId == selectedWallet.id,
      ),
    );

    _calculateTotals();
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

  void _clearHomeData() {
    wallet = null;
    wallets = [];
    _allTransactions = [];
    transactions = [];
    totalIncome = 0;
    totalExpense = 0;
  }
}
