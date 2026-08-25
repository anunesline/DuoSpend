import '../../../budgets/domain/models/budget_consumption.dart';
import '../models/financial_insight.dart';
import '../models/financial_intelligence_input.dart';

class FinancialIntelligenceService {
  const FinancialIntelligenceService();

  List<FinancialInsight> build(FinancialIntelligenceInput input) {
    final insights = <FinancialInsight>[];
    _addBudgetInsights(input.budgets, insights);
    _addProjectionInsight(input, insights);
    _addGoalInsights(input, insights);
    _addTrendInsights(input, insights);
    _addCardInsights(input, insights);

    if (insights.isEmpty) {
      insights.add(const FinancialInsight(
        id: 'insufficient-financial-data',
        type: FinancialInsightType.insufficientData,
        severity: FinancialInsightSeverity.info,
        title: 'Dados insuficientes',
        message: 'Adicione transações para receber insights financeiros.',
        source: 'Transações registradas',
      ));
    }

    return List.unmodifiable(insights);
  }

  void _addBudgetInsights(List<BudgetConsumption> budgets, List<FinancialInsight> insights) {
    for (final consumption in budgets) {
      if (consumption.health == BudgetHealth.healthy) continue;
      final exceeded = consumption.health == BudgetHealth.exceeded;
      insights.add(FinancialInsight(
        id: 'budget-${consumption.budget.id}',
        type: FinancialInsightType.budget,
        severity: exceeded ? FinancialInsightSeverity.warning : FinancialInsightSeverity.attention,
        title: exceeded ? 'Orçamento estourado' : 'Orçamento em atenção',
        message: '${consumption.budget.category} já consumiu ${consumption.percentageDisplay.round()}% do orçamento.',
        source: 'Orçamento de ${consumption.budget.category}: limite e transações do mês',
        amount: consumption.remainingAmount,
      ));
    }
  }

  void _addProjectionInsight(FinancialIntelligenceInput input, List<FinancialInsight> insights) {
    if (input.projection.entries.isEmpty) return;
    final negative = input.projection.projectedBalance < 0;
    insights.add(FinancialInsight(
      id: 'projected-balance',
      type: FinancialInsightType.projectedBalance,
      severity: negative ? FinancialInsightSeverity.warning : FinancialInsightSeverity.info,
      title: negative ? 'Risco de saldo negativo' : 'Saldo previsto até o fim do mês',
      message: negative
          ? 'Com os lançamentos previstos, a carteira pode terminar o mês no negativo.'
          : 'Com os lançamentos previstos, a carteira deve terminar o mês com saldo positivo.',
      source: 'Saldo atual + lançamentos futuros e recorrências',
      amount: input.projection.projectedBalance,
    ));
  }

  void _addGoalInsights(FinancialIntelligenceInput input, List<FinancialInsight> insights) {
    for (final goal in input.goals.where((goal) => goal.isActive && goal.hasDeadline)) {
      final deadline = goal.deadline!;
      final months = _monthsUntil(input.now, deadline);
      if (months <= 0 && goal.remainingAmount > 0) {
        insights.add(FinancialInsight(
          id: 'goal-late-${goal.id}', type: FinancialInsightType.goal, severity: FinancialInsightSeverity.warning,
          title: 'Meta atrasada', message: '${goal.name} ainda precisa de reserva para ser concluída.',
          source: 'Meta, valor guardado e prazo', amount: goal.remainingAmount,
        ));
      } else if (months > 0) {
        insights.add(FinancialInsight(
          id: 'goal-monthly-${goal.id}', type: FinancialInsightType.goal, severity: FinancialInsightSeverity.info,
          title: 'Reserva mensal para ${goal.name}', message: 'Para atingir a meta no prazo, reserve o valor mensal indicado.',
          source: 'Valor restante da meta dividido pelos meses até o prazo', amount: goal.remainingAmount / months,
        ));
      }
    }
  }

  void _addTrendInsights(FinancialIntelligenceInput input, List<FinancialInsight> insights) {
    final previous = input.previousMonth;
    if (previous == null || previous.totalExpense <= 0 || input.currentMonth.totalExpense <= previous.totalExpense) return;
    final increase = ((input.currentMonth.totalExpense - previous.totalExpense) / previous.totalExpense) * 100;
    insights.add(FinancialInsight(
      id: 'monthly-expense-trend', type: FinancialInsightType.spendingTrend, severity: FinancialInsightSeverity.attention,
      title: 'Gastos acima do mês anterior', message: 'As despesas do mês estão ${increase.round()}% acima do período anterior.',
      source: 'Comparação de despesas mensais', amount: input.currentMonth.totalExpense - previous.totalExpense,
    ));
  }

  void _addCardInsights(FinancialIntelligenceInput input, List<FinancialInsight> insights) {
    if (input.currentInvoices.isEmpty || input.previousInvoices.isEmpty) return;
    final current = input.currentInvoices.fold<double>(0, (sum, invoice) => sum + invoice.total);
    final previous = input.previousInvoices.fold<double>(0, (sum, invoice) => sum + invoice.total);
    if (previous <= 0 || current <= previous) return;
    insights.add(FinancialInsight(
      id: 'card-invoice-trend', type: FinancialInsightType.cardInvoice, severity: FinancialInsightSeverity.attention,
      title: 'Fatura acima do mês passado', message: 'A fatura atual está acima da referência anterior.',
      source: 'Soma das faturas atuais e do mês anterior', amount: current - previous,
    ));
  }

  int _monthsUntil(DateTime now, DateTime deadline) => (deadline.year - now.year) * 12 + deadline.month - now.month;
}
