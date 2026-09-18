import 'package:flutter/foundation.dart';

import '../../../home/data/models/wallet_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../data/repositories/budget_repository.dart';
import '../../domain/models/budget.dart';
import '../../domain/models/budget_consumption.dart';
import '../../domain/services/budget_consumption_service.dart';
import '../../domain/services/budget_service.dart';

class BudgetsController extends ChangeNotifier {
  final WalletModel wallet;
  final List<WalletModel> availableWallets;
  final String currentUserId;
  final BudgetRepository _repository;
  final BudgetService _service;
  final BudgetConsumptionService _consumptionService;
  final TransactionRepository _transactionRepository;
  List<TransactionModel> transactions;
  final Map<String, List<TransactionModel>> _transactionsByWallet = {};
  List<Budget> budgets = const [];
  bool isLoading = false;
  bool isProcessing = false;
  String? errorMessage;

  BudgetsController({
    required this.wallet,
    required this.currentUserId,
    required this.transactions,
    this.availableWallets = const [],
    BudgetRepository? repository,
    BudgetService? service,
    BudgetConsumptionService? consumptionService,
    TransactionRepository? transactionRepository,
  }) : _repository = repository ?? BudgetRepository(),
       _service = service ?? const BudgetService(),
       _consumptionService =
           consumptionService ?? const BudgetConsumptionService(),
       _transactionRepository =
           transactionRepository ?? TransactionRepository();

  bool get canManage => wallet.hasMember(currentUserId);
  List<WalletModel> get scopeWallets =>
      availableWallets.isEmpty ? [wallet] : availableWallets;
  WalletModel? walletForScope(bool shared) {
    for (final candidate in scopeWallets) {
      if (candidate.isShared == shared) return candidate;
    }
    return null;
  }

  List<TransactionModel> transactionsFor(Budget budget) =>
      _transactionsByWallet[budget.walletId] ?? transactions;
  bool _isSharedBudget(Budget budget) {
    for (final item in scopeWallets) {
      if (item.id == budget.walletId) return item.isShared;
    }
    return wallet.isShared;
  }

  List<BudgetConsumption> forMonth(DateTime month) => List.unmodifiable(
    budgets
        .where(
          (budget) =>
              !budget.isArchived &&
              budget.month.year == month.year &&
              budget.month.month == month.month,
        )
        .map(
          (budget) => _consumptionService.calculate(
            budget: budget,
            transactions: transactionsFor(budget),
            walletIsShared: _isSharedBudget(budget),
          ),
        ),
  );

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final loaded = await Future.wait(
        scopeWallets.map((scopeWallet) async {
          final walletBudgets = await _repository.getByWallet(
            wallet: scopeWallet,
          );
          final walletTransactions = await _transactionRepository
              .getTransactionsByWallet(scopeWallet.id, wallet: scopeWallet);
          return (scopeWallet, walletBudgets, walletTransactions);
        }),
      );
      budgets = List.unmodifiable(loaded.expand((item) => item.$2));
      _transactionsByWallet
        ..clear()
        ..addEntries(loaded.map((item) => MapEntry(item.$1.id, item.$3)));
      transactions = List.unmodifiable(loaded.expand((item) => item.$3));
    } catch (_) {
      errorMessage = 'Não foi possível carregar os orçamentos.';
      budgets = const [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Budget?> create({
    required String category,
    required DateTime month,
    required double limitAmount,
    WalletModel? targetWallet,
  }) async {
    if (!canManage || isProcessing) {
      errorMessage = 'Você não tem permissão para alterar estes orçamentos.';
      notifyListeners();
      return null;
    }
    isProcessing = true;
    errorMessage = null;
    notifyListeners();
    try {
      final destination = targetWallet ?? wallet;
      if (!destination.hasMember(currentUserId))
        throw StateError('Você não tem acesso à carteira escolhida.');
      final budget = _service.create(
        id: _repository.createId(),
        walletId: destination.id,
        category: category,
        month: month,
        limitAmount: limitAmount,
        createdByUserId: currentUserId,
      );
      await _repository.create(budget: budget, wallet: destination);
      budgets = List.unmodifiable([budget, ...budgets]);
      return budget;
    } catch (error) {
      errorMessage = error.toString();
      return null;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  Future<Budget?> update(
    Budget budget, {
    required String category,
    required DateTime month,
    required double limitAmount,
  }) async {
    if (!canManage || isProcessing) return null;
    isProcessing = true;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = _service.update(
        budget: budget,
        category: category,
        month: month,
        limitAmount: limitAmount,
      );
      await _repository.update(budget: updated, wallet: wallet);
      budgets = List.unmodifiable(
        budgets.map((item) => item.id == updated.id ? updated : item),
      );
      return updated;
    } catch (error) {
      errorMessage = error.toString();
      return null;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  Future<Budget?> changeStatus(Budget budget, BudgetStatus status) async {
    if (!canManage || isProcessing) return null;
    isProcessing = true;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = await _repository.changeStatus(
        budget: budget,
        status: status,
        wallet: wallet,
      );
      budgets = List.unmodifiable(
        budgets.map((item) => item.id == updated.id ? updated : item),
      );
      return updated;
    } catch (error) {
      errorMessage = error.toString();
      return null;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }
}
