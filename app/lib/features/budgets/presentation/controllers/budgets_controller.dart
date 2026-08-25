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
  final String currentUserId;
  final BudgetRepository _repository;
  final BudgetService _service;
  final BudgetConsumptionService _consumptionService;
  final TransactionRepository _transactionRepository;
  List<TransactionModel> transactions;
  List<Budget> budgets = const [];
  bool isLoading = false;
  bool isProcessing = false;
  String? errorMessage;

  BudgetsController({required this.wallet, required this.currentUserId, required this.transactions, BudgetRepository? repository, BudgetService? service, BudgetConsumptionService? consumptionService, TransactionRepository? transactionRepository})
      : _repository = repository ?? BudgetRepository(), _service = service ?? const BudgetService(), _consumptionService = consumptionService ?? const BudgetConsumptionService(), _transactionRepository = transactionRepository ?? TransactionRepository();

  bool get canManage => !wallet.isShared || wallet.isOwner(currentUserId);
  List<BudgetConsumption> forMonth(DateTime month) => List.unmodifiable(budgets.where((budget) => !budget.isArchived && budget.month.year == month.year && budget.month.month == month.month).map((budget) => _consumptionService.calculate(budget: budget, transactions: transactions)));

  Future<void> load() async {
    isLoading = true; errorMessage = null; notifyListeners();
    try {
      budgets = await _repository.getByWallet(wallet: wallet);
      transactions = await _transactionRepository.getTransactionsByWallet(
        wallet.id,
        wallet: wallet,
      );
    }
    catch (_) { errorMessage = 'Não foi possível carregar os orçamentos.'; budgets = const []; }
    finally { isLoading = false; notifyListeners(); }
  }

  Future<Budget?> create({required String category, required DateTime month, required double limitAmount}) async {
    if (!canManage || isProcessing) { errorMessage = 'Você não tem permissão para alterar estes orçamentos.'; notifyListeners(); return null; }
    isProcessing = true; errorMessage = null; notifyListeners();
    try {
      final budget = _service.create(id: _repository.createId(), walletId: wallet.id, category: category, month: month, limitAmount: limitAmount, createdByUserId: currentUserId);
      await _repository.create(budget: budget, wallet: wallet);
      budgets = List.unmodifiable([budget, ...budgets]); return budget;
    } catch (error) { errorMessage = error.toString(); return null; }
    finally { isProcessing = false; notifyListeners(); }
  }

  Future<Budget?> update(Budget budget, {required String category, required DateTime month, required double limitAmount}) async {
    if (!canManage || isProcessing) return null;
    isProcessing = true; errorMessage = null; notifyListeners();
    try {
      final updated = _service.update(budget: budget, category: category, month: month, limitAmount: limitAmount);
      await _repository.update(budget: updated, wallet: wallet);
      budgets = List.unmodifiable(budgets.map((item) => item.id == updated.id ? updated : item)); return updated;
    } catch (error) { errorMessage = error.toString(); return null; }
    finally { isProcessing = false; notifyListeners(); }
  }

  Future<Budget?> changeStatus(Budget budget, BudgetStatus status) async {
    if (!canManage || isProcessing) return null;
    isProcessing = true; errorMessage = null; notifyListeners();
    try {
      final updated = await _repository.changeStatus(budget: budget, status: status, wallet: wallet);
      budgets = List.unmodifiable(budgets.map((item) => item.id == updated.id ? updated : item)); return updated;
    } catch (error) { errorMessage = error.toString(); return null; }
    finally { isProcessing = false; notifyListeners(); }
  }
}
