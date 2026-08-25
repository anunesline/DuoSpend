import 'package:flutter/foundation.dart';

import '../../../budgets/data/repositories/budget_repository.dart';
import '../../../budgets/domain/services/budget_consumption_service.dart';
import '../../../goals/data/repositories/savings_goal_repository.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../home/data/repositories/credit_card_repository.dart';
import '../../../reports/domain/services/financial_report_service.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../../transactions/domain/calendar/financial_calendar_service.dart';
import '../../domain/models/financial_insight.dart';
import '../../domain/models/financial_intelligence_input.dart';
import '../../domain/services/financial_intelligence_service.dart';

class InsightsController extends ChangeNotifier {
  final WalletModel wallet;
  final TransactionRepository _transactionRepository;
  final BudgetRepository _budgetRepository;
  final SavingsGoalRepository _goalRepository;
  final CreditCardRepository _creditCardRepository;
  final FinancialReportService _reportService;
  final FinancialCalendarService _calendarService;
  final BudgetConsumptionService _budgetConsumptionService;
  final FinancialIntelligenceService _intelligenceService;

  List<FinancialInsight> insights = const [];
  bool isLoading = false;
  String? errorMessage;

  InsightsController({
    required this.wallet,
    TransactionRepository? transactionRepository,
    BudgetRepository? budgetRepository,
    SavingsGoalRepository? goalRepository,
    CreditCardRepository? creditCardRepository,
    FinancialReportService reportService = const FinancialReportService(),
    FinancialCalendarService calendarService = const FinancialCalendarService(),
    BudgetConsumptionService budgetConsumptionService =
        const BudgetConsumptionService(),
    FinancialIntelligenceService intelligenceService =
        const FinancialIntelligenceService(),
  })  : _transactionRepository = transactionRepository ?? TransactionRepository(),
        _budgetRepository = budgetRepository ?? BudgetRepository(),
        _goalRepository = goalRepository ?? SavingsGoalRepository(),
        _creditCardRepository = creditCardRepository ?? CreditCardRepository(),
        _reportService = reportService,
        _calendarService = calendarService,
        _budgetConsumptionService = budgetConsumptionService,
        _intelligenceService = intelligenceService;

  Future<void> load({DateTime? now}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final reference = now ?? DateTime.now();
    final currentMonth = DateTime(reference.year, reference.month);
    final previousMonth = DateTime(reference.year, reference.month - 1);
    try {
      final transactions = await _transactionRepository.getTransactionsByWallet(
        wallet.id,
        wallet: wallet,
      );
      final budgets = await _budgetRepository.getByWallet(wallet: wallet);
      final goals = await _goalRepository.getGoalsByWallet(wallet.id);
      final cards = await _creditCardRepository.getCards();
      final invoicesByCard = await Future.wait(
        cards
            .where((card) => card.walletId == wallet.id)
            .map((card) => _creditCardRepository.getInvoices(cardId: card.id)),
      );
      final invoices = invoicesByCard.expand((items) => items).toList();
      final projection = _calendarService.buildProjection(
        currentBalance: wallet.balance,
        transactions: transactions,
        invoices: invoices,
        rangeStart: reference,
        rangeEnd: DateTime(reference.year, reference.month + 1, 0),
        now: reference,
      );
      final currentReport = _reportService.buildMonthly(
        transactions: transactions,
        year: currentMonth.year,
        month: currentMonth.month,
        referenceDate: reference,
      );
      final previousReport = _reportService.buildMonthly(
        transactions: transactions,
        year: previousMonth.year,
        month: previousMonth.month,
        referenceDate: reference,
      );
      final historicalReports = _reportService
          .buildMonthlyEvolution(
            transactions: transactions,
            endYear: previousMonth.year,
            endMonth: previousMonth.month,
            monthCount: 3,
            referenceDate: reference,
          )
          .map((point) => point.report)
          .toList();
      final budgetConsumptions = budgets
          .where((budget) =>
              !budget.isArchived &&
              budget.month.year == currentMonth.year &&
              budget.month.month == currentMonth.month)
          .map((budget) => _budgetConsumptionService.calculate(
                budget: budget,
                transactions: transactions,
              ))
          .toList();
      final currentInvoices = invoices
          .where((invoice) =>
              invoice.referenceYear == currentMonth.year &&
              invoice.referenceMonth == currentMonth.month)
          .toList();
      final previousInvoices = invoices
          .where((invoice) =>
              invoice.referenceYear == previousMonth.year &&
              invoice.referenceMonth == previousMonth.month)
          .toList();
      insights = _intelligenceService.build(FinancialIntelligenceInput(
        currentMonth: currentReport,
        previousMonth: previousReport.transactions.isEmpty ? null : previousReport,
        historicalMonths: historicalReports,
        projection: projection,
        budgets: budgetConsumptions,
        goals: goals,
        currentInvoices: currentInvoices,
        previousInvoices: previousInvoices,
        now: reference,
      ));
    } catch (_) {
      insights = const [];
      errorMessage = 'Não foi possível carregar os insights financeiros.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
