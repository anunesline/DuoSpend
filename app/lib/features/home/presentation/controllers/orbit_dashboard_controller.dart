import 'package:flutter/foundation.dart';

import '../../../budgets/data/repositories/budget_repository.dart';
import '../../../budgets/domain/services/budget_consumption_service.dart';
import '../../../goals/data/repositories/savings_goal_repository.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/credit_card_repository.dart';
import '../../domain/models/orbit_dashboard_summary.dart';
import '../../domain/services/orbit_dashboard_summary_builder.dart';

class OrbitDashboardController extends ChangeNotifier {
  final BudgetRepository _budgetRepository;
  final SavingsGoalRepository _goalRepository;
  final CreditCardRepository _creditCardRepository;
  final BudgetConsumptionService _budgetConsumptionService;
  final OrbitDashboardSummaryBuilder _summaryBuilder;

  OrbitDashboardSummary summary = OrbitDashboardSummary.empty;
  bool isLoading = false;
  String? errorMessage;

  OrbitDashboardController({
    BudgetRepository? budgetRepository,
    SavingsGoalRepository? goalRepository,
    CreditCardRepository? creditCardRepository,
    BudgetConsumptionService budgetConsumptionService = const BudgetConsumptionService(),
    OrbitDashboardSummaryBuilder summaryBuilder = const OrbitDashboardSummaryBuilder(),
  })  : _budgetRepository = budgetRepository ?? BudgetRepository(),
        _goalRepository = goalRepository ?? SavingsGoalRepository(),
        _creditCardRepository = creditCardRepository ?? CreditCardRepository(),
        _budgetConsumptionService = budgetConsumptionService,
        _summaryBuilder = summaryBuilder;

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
      final budgets = await _budgetRepository.getByWallet(wallet: wallet);
      final goals = await _goalRepository.getGoalsByWallet(wallet.id);
      final cards = await _creditCardRepository.getCards();
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
          .map((budget) => _budgetConsumptionService.calculate(
                budget: budget,
                transactions: transactions,
              ))
          .toList();

      summary = _summaryBuilder.build(
        consumptions: consumptions,
        goals: goals,
        invoices: invoices,
        reference: reference,
      );
    } catch (_) {
      summary = OrbitDashboardSummary.empty;
      errorMessage = 'Não foi possível carregar o resumo do mês.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
