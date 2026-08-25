import '../../../budgets/domain/models/budget_consumption.dart';
import '../../../goals/domain/models/savings_goal.dart';
import '../../../home/data/models/credit_card_invoice_model.dart';
import '../../../reports/domain/models/financial_report.dart';
import '../../../transactions/domain/calendar/financial_projection.dart';
import '../../../transactions/data/models/transaction_model.dart';

class FinancialIntelligenceInput {
  final FinancialReport currentMonth;
  final FinancialReport? previousMonth;
  final FinancialProjection projection;
  final List<BudgetConsumption> budgets;
  final List<SavingsGoal> goals;
  final List<CreditCardInvoiceModel> currentInvoices;
  final List<CreditCardInvoiceModel> previousInvoices;
  final List<TransactionModel> recurringTransactions;
  final DateTime now;

  const FinancialIntelligenceInput({
    required this.currentMonth,
    required this.projection,
    this.previousMonth,
    this.budgets = const [],
    this.goals = const [],
    this.currentInvoices = const [],
    this.previousInvoices = const [],
    this.recurringTransactions = const [],
    required this.now,
  });
}
