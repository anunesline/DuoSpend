import 'package:app/features/financial_intelligence/domain/models/financial_insight.dart';
import 'package:app/features/home/presentation/widgets/orbit_insight_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FinancialInsight insight({
    required String id,
    required FinancialInsightType type,
    required FinancialInsightSeverity severity,
  }) {
    return FinancialInsight(
      id: id,
      type: type,
      severity: severity,
      title: id,
      message: id,
      source: 'test',
    );
  }

  test('prioriza warning sobre attention e info', () {
    final selected = selectOrbitPriorityInsight([
      insight(
        id: 'info',
        type: FinancialInsightType.goal,
        severity: FinancialInsightSeverity.info,
      ),
      insight(
        id: 'attention',
        type: FinancialInsightType.budget,
        severity: FinancialInsightSeverity.attention,
      ),
      insight(
        id: 'warning',
        type: FinancialInsightType.projectedBalance,
        severity: FinancialInsightSeverity.warning,
      ),
    ]);

    expect(selected?.id, 'warning');
  });

  test('em mesma severidade prioriza risco de caixa', () {
    final selected = selectOrbitPriorityInsight([
      insight(
        id: 'budget',
        type: FinancialInsightType.budget,
        severity: FinancialInsightSeverity.warning,
      ),
      insight(
        id: 'cash-flow',
        type: FinancialInsightType.cashFlowRisk,
        severity: FinancialInsightSeverity.warning,
      ),
    ]);

    expect(selected?.id, 'cash-flow');
  });

  test('dados insuficientes só aparecem sem insight financeiro real', () {
    final insufficient = insight(
      id: 'empty',
      type: FinancialInsightType.insufficientData,
      severity: FinancialInsightSeverity.info,
    );
    final goal = insight(
      id: 'goal',
      type: FinancialInsightType.goal,
      severity: FinancialInsightSeverity.info,
    );

    expect(selectOrbitPriorityInsight([insufficient, goal])?.id, 'goal');
    expect(selectOrbitPriorityInsight([insufficient])?.id, 'empty');
  });
}
