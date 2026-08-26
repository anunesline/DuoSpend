class OrbitBudgetSummary {
  final double limitAmount;
  final double spentAmount;
  final int activeBudgetCount;
  final String? highestRiskCategory;

  const OrbitBudgetSummary({
    required this.limitAmount,
    required this.spentAmount,
    required this.activeBudgetCount,
    this.highestRiskCategory,
  });

  double get usage => limitAmount <= 0 ? 0 : (spentAmount / limitAmount).clamp(0.0, 99.0);
  double get usagePercentage => usage * 100;
  bool get isOverLimit => spentAmount > limitAmount && limitAmount > 0;
}

class OrbitGoalSummary {
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;

  const OrbitGoalSummary({
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
  });

  double get progress => targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0.0, 1.0);
  double get progressPercentage => progress * 100;
  double get remainingAmount => (targetAmount - savedAmount).clamp(0.0, double.infinity);
}

class OrbitInvoiceSummary {
  final double total;
  final DateTime dueDate;
  final int invoiceCount;

  const OrbitInvoiceSummary({
    required this.total,
    required this.dueDate,
    required this.invoiceCount,
  });
}

class OrbitDashboardSummary {
  final OrbitBudgetSummary? budget;
  final OrbitGoalSummary? goal;
  final OrbitInvoiceSummary? invoice;

  const OrbitDashboardSummary({this.budget, this.goal, this.invoice});

  static const empty = OrbitDashboardSummary();
}
