import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/home/domain/models/orbit_dashboard_summary.dart';

void main() {
  group('OrbitBudgetSummary', () {
    test('keeps real usage above 100% while bounding visual progress', () {
      const summary = OrbitBudgetSummary(
        limitAmount: 1000,
        spentAmount: 1500,
        activeBudgetCount: 2,
        highestRiskCategory: 'Mercado',
      );

      expect(summary.usage, 1.5);
      expect(summary.usagePercentage, 150);
      expect(summary.progress, 1);
      expect(summary.isOverLimit, isTrue);
    });

    test('returns zero usage safely when limit is zero', () {
      const summary = OrbitBudgetSummary(
        limitAmount: 0,
        spentAmount: 200,
        activeBudgetCount: 1,
      );

      expect(summary.usage, 0);
      expect(summary.progress, 0);
      expect(summary.usagePercentage, 0);
      expect(summary.isOverLimit, isFalse);
    });
  });

  group('OrbitGoalSummary', () {
    test('bounds progress at 100% and never exposes negative remaining amount', () {
      const summary = OrbitGoalSummary(
        name: 'Viagem',
        targetAmount: 1000,
        savedAmount: 1200,
      );

      expect(summary.progress, 1);
      expect(summary.progressPercentage, 100);
      expect(summary.remainingAmount, 0);
    });

    test('returns zero progress safely when target is zero', () {
      const summary = OrbitGoalSummary(
        name: 'Reserva',
        targetAmount: 0,
        savedAmount: 100,
      );

      expect(summary.progress, 0);
      expect(summary.remainingAmount, 0);
    });
  });

  test('empty dashboard has no fabricated financial data', () {
    expect(OrbitDashboardSummary.empty.budget, isNull);
    expect(OrbitDashboardSummary.empty.goal, isNull);
    expect(OrbitDashboardSummary.empty.invoice, isNull);
  });
}
