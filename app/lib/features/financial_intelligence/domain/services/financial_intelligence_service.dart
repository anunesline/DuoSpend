import '../../../budgets/domain/models/budget_consumption.dart';
import '../models/financial_insight.dart';
import '../models/financial_intelligence_input.dart';

class FinancialIntelligenceService {
  const FinancialIntelligenceService();

  List<FinancialInsight> build(FinancialIntelligenceInput input) {
    final insights = <FinancialInsight>[];
    _addBudgetInsights(input.budgets, insights);
    _addProjectionInsight(input, insights);
    _addCashFlowRiskInsight(input, insights);
    _addGoalInsights(input, insights);
    _addTrendInsights(input, insights);
    _addRecurringInsights(input, insights);
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

  void _addBudgetInsights(
    List<BudgetConsumption> budgets,
    List<FinancialInsight> insights,
  ) {
    for (final consumption in budgets) {
      if (consumption.health == BudgetHealth.healthy) continue;
      final exceeded = consumption.health == BudgetHealth.exceeded;
      insights.add(FinancialInsight(
        id: 'budget-${consumption.budget.id}',
        type: FinancialInsightType.budget,
        severity: exceeded ? FinancialInsightSeverity.warning : FinancialInsightSeverity.attention,
        title: exceeded ? 'Orçamento estourado' : 'Orçamento em atenção',
        message: '${consumption.budget.category} já consumiu '
            '${consumption.percentageDisplay.round()}% do orçamento.',
        source: 'Orçamento de ${consumption.budget.category}: limite e transações do mês',
        amount: consumption.remainingAmount,
      ));
    }
  }

  void _addProjectionInsight(
    FinancialIntelligenceInput input,
    List<FinancialInsight> insights,
  ) {
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

    if (!negative) {
      insights.add(FinancialInsight(
        id: 'available-to-spend',
        type: FinancialInsightType.projectedBalance,
        severity: FinancialInsightSeverity.info,
        title: 'Disponível até o fim do mês',
        message: 'Este é o saldo previsto depois dos compromissos já lançados.',
        source: 'Saldo atual + receitas previstas − despesas previstas',
        amount: input.projection.projectedBalance,
      ));
    }
  }

  void _addCashFlowRiskInsight(
    FinancialIntelligenceInput input,
    List<FinancialInsight> insights,
  ) {
    final projectedEntries = input.projection.entries
        .where((entry) => entry.isProjected)
        .toList()
      ..sort((first, second) => first.date.compareTo(second.date));
    if (projectedEntries.isEmpty) return;

    var runningBalance = input.projection.currentBalance;
    for (final entry in projectedEntries) {
      runningBalance += entry.signedValue;
      if (runningBalance >= 0 || !entry.isExpense) continue;
      insights.add(FinancialInsight(
        id: 'cash-flow-risk-${entry.id}',
        type: FinancialInsightType.cashFlowRisk,
        severity: FinancialInsightSeverity.warning,
        title: 'Risco antes da próxima entrada',
        message: 'O saldo pode ficar negativo em ${entry.date.day.toString().padLeft(2, '0')}/${entry.date.month.toString().padLeft(2, '0')} antes das próximas receitas previstas.',
        source: 'Ordem cronológica dos lançamentos futuros da carteira',
        amount: runningBalance,
      ));
      return;
    }
  }

  void _addGoalInsights(
    FinancialIntelligenceInput input,
    List<FinancialInsight> insights,
  ) {
    for (final goal in input.goals.where((goal) => goal.isActive)) {
      if (!goal.hasDeadline) {
        insights.add(FinancialInsight(
          id: 'goal-no-deadline-${goal.id}',
          type: FinancialInsightType.goal,
          severity: FinancialInsightSeverity.info,
          title: 'Meta sem prazo definido',
          message: '${goal.name} não possui prazo; não é possível calcular uma reserva mensal.',
          source: 'Meta e prazo cadastrados',
        ));
        continue;
      }
      final deadline = goal.deadline!;
      final months = _monthsUntil(input.now, deadline);
      if (months <= 0 && goal.remainingAmount > 0) {
        insights.add(FinancialInsight(
          id: 'goal-late-${goal.id}',
          type: FinancialInsightType.goal,
          severity: FinancialInsightSeverity.warning,
          title: 'Meta atrasada',
          message: '${goal.name} ainda precisa de reserva para ser concluída.',
          source: 'Meta, valor guardado e prazo',
          amount: goal.remainingAmount,
        ));
      } else if (months > 0) {
        insights.add(FinancialInsight(
          id: 'goal-monthly-${goal.id}',
          type: FinancialInsightType.goal,
          severity: FinancialInsightSeverity.info,
          title: 'Reserva mensal para ${goal.name}',
          message: 'Para atingir a meta no prazo, reserve o valor mensal indicado.',
          source: 'Valor restante da meta dividido pelos meses até o prazo',
          amount: goal.remainingAmount / months,
        ));
      }
    }
  }

  void _addTrendInsights(
    FinancialIntelligenceInput input,
    List<FinancialInsight> insights,
  ) {
    final previous = input.previousMonth;
    if (previous == null || previous.totalExpense <= 0 || input.currentMonth.totalExpense <= previous.totalExpense) return;
    final increase = ((input.currentMonth.totalExpense - previous.totalExpense) /
            previous.totalExpense) *
        100;
    insights.add(FinancialInsight(
      id: 'monthly-expense-trend',
      type: FinancialInsightType.spendingTrend,
      severity: FinancialInsightSeverity.attention,
      title: 'Gastos acima do mês anterior',
      message: 'As despesas do mês estão ${increase.round()}% acima do período anterior.',
      source: 'Comparação de despesas mensais',
      amount: input.currentMonth.totalExpense - previous.totalExpense,
    ));

    final previousCategories = {
      for (final total in previous.expenseByCategory) total.category: total.amount,
    };
    for (final total in input.currentMonth.expenseByCategory) {
      final previousAmount = previousCategories[total.category];
      if (previousAmount == null || previousAmount <= 0 ||
          total.amount <= previousAmount) {
        continue;
      }
      final categoryIncrease = ((total.amount - previousAmount) / previousAmount) * 100;
      insights.add(FinancialInsight(
        id: 'category-trend-${total.category}',
        type: FinancialInsightType.spendingTrend,
        severity: FinancialInsightSeverity.attention,
        title: '${total.category} acima do padrão recente',
        message: 'Os gastos em ${total.category} estão ${categoryIncrease.round()}% acima do mês anterior.',
        source: 'Comparação da categoria entre os dois últimos meses',
        amount: total.amount - previousAmount,
      ));
    }
  }

  void _addRecurringInsights(
    FinancialIntelligenceInput input,
    List<FinancialInsight> insights,
  ) {
    final monthlyExpense = input.recurringTransactions
        .where((transaction) => transaction.type == 'expense')
        .fold<double>(0, (sum, transaction) => sum + transaction.value);
    if (monthlyExpense <= 0) return;
    insights.add(FinancialInsight(
      id: 'recurring-monthly-weight',
      type: FinancialInsightType.recurring,
      severity: FinancialInsightSeverity.info,
      title: 'Recorrências do mês',
      message: 'Há despesas recorrentes que pesam no planejamento mensal.',
      source: 'Transações recorrentes ativas da carteira',
      amount: monthlyExpense,
    ));
  }

  void _addCardInsights(
    FinancialIntelligenceInput input,
    List<FinancialInsight> insights,
  ) {
    if (input.currentInvoices.isEmpty || input.previousInvoices.isEmpty) return;
    final current = input.currentInvoices.fold<double>(0, (sum, invoice) => sum + invoice.total);
    final previous = input.previousInvoices.fold<double>(0, (sum, invoice) => sum + invoice.total);
    if (previous <= 0 || current <= previous) return;
    insights.add(FinancialInsight(
      id: 'card-invoice-trend',
      type: FinancialInsightType.cardInvoice,
      severity: FinancialInsightSeverity.attention,
      title: 'Fatura acima do mês passado',
      message: 'A fatura atual está acima da referência anterior.',
      source: 'Soma das faturas atuais e do mês anterior',
      amount: current - previous,
    ));
  }

  int _monthsUntil(DateTime now, DateTime deadline) => (deadline.year - now.year) * 12 + deadline.month - now.month;
}
