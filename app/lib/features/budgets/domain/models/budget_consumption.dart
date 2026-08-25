import 'budget.dart';

enum BudgetHealth { healthy, attention, exceeded }

class BudgetConsumption {
  final Budget budget;
  final double spentAmount;

  const BudgetConsumption({required this.budget, required this.spentAmount});

  double get remainingAmount => budget.limitAmount - spentAmount;
  double get percentage => budget.limitAmount == 0 ? 0 : spentAmount / budget.limitAmount;
  double get percentageDisplay => percentage * 100;
  BudgetHealth get health => percentage > 1 ? BudgetHealth.exceeded : percentage >= .8 ? BudgetHealth.attention : BudgetHealth.healthy;
}
