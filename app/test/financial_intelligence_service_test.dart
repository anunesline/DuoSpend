import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/budgets/domain/models/budget.dart';
import 'package:app/features/budgets/domain/models/budget_consumption.dart';
import 'package:app/features/financial_intelligence/domain/models/financial_insight.dart';
import 'package:app/features/financial_intelligence/domain/models/financial_intelligence_input.dart';
import 'package:app/features/financial_intelligence/domain/services/financial_intelligence_service.dart';
import 'package:app/features/goals/domain/models/savings_goal.dart';
import 'package:app/features/reports/domain/models/financial_report.dart';
import 'package:app/features/transactions/domain/calendar/financial_projection.dart';

void main() {
  const service = FinancialIntelligenceService();
  final now = DateTime(2026, 8, 15);

  FinancialReport report({double expense = 0, List<FinancialCategoryTotal> categories = const []}) {
    return FinancialReport(
      startDate: DateTime(2026, 8),
      endDate: DateTime(2026, 8, 31),
      totalIncome: 0,
      totalExpense: expense,
      expenseByCategory: categories,
      transactions: const [],
    );
  }

  FinancialIntelligenceInput input({
    FinancialReport? current,
    FinancialReport? previous,
    List<BudgetConsumption> budgets = const [],
    List<SavingsGoal> goals = const [],
  }) => FinancialIntelligenceInput(
    currentMonth: current ?? report(),
    previousMonth: previous,
    projection: FinancialProjection.empty(100),
    budgets: budgets,
    goals: goals,
    now: now,
  );

  test('retorna dados insuficientes sem dados financeiros', () {
    final insights = service.build(input());
    expect(insights.single.type, FinancialInsightType.insufficientData);
  });

  test('alerta orçamento em atenção e estourado sem persistir consumo', () {
    final base = Budget(
      id: 'b', walletId: 'w', category: 'Mercado', month: now,
      limitAmount: 100, createdByUserId: 'u', createdAt: now, updatedAt: now,
    );
    final insights = service.build(input(budgets: [
      BudgetConsumption(budget: base, spentAmount: 80),
      BudgetConsumption(budget: base.copyWith(category: 'Lazer'), spentAmount: 101),
    ]));
    expect(insights.where((item) => item.type == FinancialInsightType.budget), hasLength(2));
    expect(base.limitAmount, 100);
  });

  test('calcula reserva mensal para meta com prazo e informa meta sem prazo', () {
    final goal = SavingsGoal(
      id: 'g', name: 'Viagem', targetAmount: 1000, savedAmount: 400,
      deadline: DateTime(2026, 11), walletId: 'w', createdByUserId: 'u',
      createdAt: now, updatedAt: now,
    );
    final noDeadline = goal.copyWith(id: 'g2', name: 'Casa', clearDeadline: true);
    final insights = service.build(input(goals: [goal, noDeadline]));
    expect(insights.firstWhere((item) => item.id == 'goal-monthly-g').amount, 200);
    expect(insights.any((item) => item.id == 'goal-no-deadline-g2'), isTrue);
  });

  test('compara despesas e categorias apenas quando há histórico suficiente', () {
    final insights = service.build(input(
      current: report(expense: 150, categories: const [FinancialCategoryTotal(category: 'Lazer', amount: 100, percentage: 1)]),
      previous: report(expense: 100, categories: const [FinancialCategoryTotal(category: 'Lazer', amount: 50, percentage: 1)]),
    ));
    expect(insights.any((item) => item.id == 'monthly-expense-trend'), isTrue);
    expect(insights.any((item) => item.id == 'category-trend-Lazer'), isTrue);
  });
}
