import 'package:flutter/foundation.dart';

import '../../../budgets/data/repositories/budget_repository.dart';
import '../../../budgets/domain/models/budget_consumption.dart';
import '../../../budgets/domain/services/budget_consumption_service.dart';
import '../../../goals/data/repositories/savings_goal_repository.dart';
import '../../../goals/domain/models/savings_goal.dart';
import '../../data/models/credit_card_invoice_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/credit_card_repository.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../..//domain/models/orbit_dashboard_summary.dart';

class OrbitDashboardController extends ChangeNotifier {
  final BudgetRepository _budgetRepository;
  final SavingsGoalRepository _goalRepository;
  final CreditCardRepository _creditCardRepository;
  final BudgetConsumptionService _budgetConsumptionService;

  OrbitDashboardSummary summary = OrbitDashboardSummary.empty;
  bool isLoading = false;
  String? errorMessage;

  OrbitDashboardController({
    BudgetRepository? budgetRepository,
    SavingsGoalRepository? goalRepository,
    CreditCardRepository? creditCardRepository,
    BudgetConsumptionService budgetConsumptionService = const BudgetConsumptionService(),
  })  : _budgetRepository = budgetRepository ?? BudgetRepository(),
        _goalRepository = goalRepository ?? SavingsGoalRepository(),
        _creditCardRepository = creditCardRepository ?? CreditCardRepository(),
        _budgetConsumptionService = budgetConsumptionService;

  Future<void> load({
    required WalletModel wallet,
    required List<TransactionModel> transactions,
    DateTime? now,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final reference = now ?? DateTime.now();

    try {
      final results = await Future.wait<dynamic>([
        _budgetRepository.getByWallet(wallet: wallet),
        _goalRepository.getGoalsByWallet(wallet.id),
        _creditCardRepository.getCards(),
      ]);
      final budgets = results[0] as List;
      final goals = (results[1] as List).cast<SavingsGoal>();
      final cards = results[2] as List;

      final walletCards = cards.where((card) => card.walletId == wallet.id).toList();
      final invoiceLists = await Future.wait(
        walletCards.map((card) => _creditCardRepository.getInvoices(cardId: card.id)),
      );
      final invoices = invoiceLists.expand((items) => items).toList();

      final consumptions = budgets
          .where((budget) =>
              budget.isActive &&
              budget.month.year == reference.year &&
              budget.month.month == reference.month)
          .map<BudgetConsumption>((budget) => _budgetConsumptionService.calculate(
                budget: budget,
                transactions: transactions,
              ))
          .toList();

      summary = OrbitDashboardSummary(
        budget: _buildBudgetSummary(consumptions),
        goal: _buildGoalSummary(goals, reference),
        invoice: _buildInvoiceSummary(invoices, reference),
      );
    } catch (_) {
      summary = OrbitDashboardSummary.empty;
      errorMessage = 'Não foi possível carregar o resumo do mês.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  OrbitBudgetSummary? _buildBudgetSummary(List<BudgetConsumption> consumptions) {
    if (consumptions.isEmpty) return null;
    final totalLimit = consumptions.fold<double>(0, (sum, item) => sum + item.budget.limitAmount);
    final totalSpent = consumptions.fold<double>(0, (sum, item) => sum + item.spentAmount);
    final ranked = [...consumptions]
      ..sort((a, b) {
        final aUsage = a.budget.limitAmount <= 0 ? 0 : a.spentAmount / a.budget.limitAmount;
        final bUsage = b.budget.limitAmount <= 0 ? 0 : b.spentAmount / b.budget.limitAmount;
        return bUsage.compareTo(aUsage);
      });
    return OrbitBudgetSummary(
      limitAmount: totalLimit,
      spentAmount: totalSpent,
      activeBudgetCount: consumptions.length,
      highestRiskCategory: ranked.first.budget.category,
    );
  }

  OrbitGoalSummary? _buildGoalSummary(List<SavingsGoal> goals, DateTime reference) {
    final active = goals.where((goal) => goal.isActive).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) {
      if (a.deadline == null && b.deadline == null) return b.progress.compareTo(a.progress);
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    });
    final goal = active.first;
    return OrbitGoalSummary(
      name: goal.name,
      targetAmount: goal.targetAmount,
      savedAmount: goal.savedAmount,
      deadline: goal.deadline,
    );
  }

  OrbitInvoiceSummary? _buildInvoiceSummary(List<CreditCardInvoiceModel> invoices, DateTime reference) {
    final current = invoices.where((invoice) =>
        !invoice.isPaid &&
        invoice.referenceYear == reference.year &&
        invoice.referenceMonth == reference.month).toList();
    if (current.isEmpty) return null;
    current.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return OrbitInvoiceSummary(
      total: current.fold<double>(0, (sum, invoice) => sum + invoice.total),
      dueDate: current.first.dueDate,
      invoiceCount: current.length,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
