import '../../../budgets/domain/models/budget_consumption.dart';
import '../../../goals/domain/models/savings_goal.dart';
import '../../data/models/credit_card_invoice_model.dart';
import '../models/orbit_dashboard_summary.dart';

class OrbitDashboardSummaryBuilder {
  const OrbitDashboardSummaryBuilder();

  OrbitDashboardSummary build({
    required List<BudgetConsumption> consumptions,
    required List<SavingsGoal> goals,
    required List<CreditCardInvoiceModel> invoices,
    required DateTime reference,
  }) {
    return OrbitDashboardSummary(
      budget: buildBudget(consumptions),
      goal: buildGoal(goals),
      invoice: buildInvoice(invoices, reference),
    );
  }

  OrbitBudgetSummary? buildBudget(List<BudgetConsumption> consumptions) {
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

  OrbitGoalSummary? buildGoal(List<SavingsGoal> goals) {
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

  OrbitInvoiceSummary? buildInvoice(List<CreditCardInvoiceModel> invoices, DateTime reference) {
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
}
