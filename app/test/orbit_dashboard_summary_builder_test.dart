import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/budgets/domain/models/budget.dart';
import 'package:app/features/budgets/domain/models/budget_consumption.dart';
import 'package:app/features/goals/domain/models/savings_goal.dart';
import 'package:app/features/home/data/models/credit_card_invoice_model.dart';
import 'package:app/features/home/domain/services/orbit_dashboard_summary_builder.dart';

void main() {
  const builder = OrbitDashboardSummaryBuilder();
  final reference = DateTime(2026, 8, 26);

  Budget budget(String id, String category, double limit) => Budget(
        id: id,
        walletId: 'wallet-1',
        category: category,
        month: DateTime(2026, 8),
        limitAmount: limit,
        createdByUserId: 'user-1',
        createdAt: reference,
        updatedAt: reference,
      );

  SavingsGoal goal({
    required String id,
    required String name,
    required double saved,
    DateTime? deadline,
    SavingsGoalStatus status = SavingsGoalStatus.active,
  }) => SavingsGoal(
        id: id,
        name: name,
        targetAmount: 1000,
        savedAmount: saved,
        deadline: deadline,
        walletId: 'wallet-1',
        createdByUserId: 'user-1',
        status: status,
        createdAt: reference,
        updatedAt: reference,
      );

  CreditCardInvoiceModel invoice({
    required String id,
    required double total,
    required DateTime dueDate,
    int year = 2026,
    int month = 8,
    String status = CreditCardInvoiceModel.openStatus,
  }) => CreditCardInvoiceModel(
        id: id,
        cardId: 'card-1',
        ownerMemberId: 'user-1',
        referenceYear: year,
        referenceMonth: month,
        closingDate: DateTime(year, month, 20),
        dueDate: dueDate,
        total: total,
        status: status,
        createdAt: reference,
        updatedAt: reference,
      );

  test('aggregates budgets and identifies highest risk category', () {
    final result = builder.buildBudget([
      BudgetConsumption(budget: budget('b1', 'Mercado', 1000), spentAmount: 900),
      BudgetConsumption(budget: budget('b2', 'Lazer', 500), spentAmount: 100),
    ]);

    expect(result, isNotNull);
    expect(result!.limitAmount, 1500);
    expect(result.spentAmount, 1000);
    expect(result.activeBudgetCount, 2);
    expect(result.highestRiskCategory, 'Mercado');
  });

  test('selects active goal with nearest deadline', () {
    final result = builder.buildGoal([
      goal(id: 'later', name: 'Viagem', saved: 800, deadline: DateTime(2026, 12, 1)),
      goal(id: 'soon', name: 'Reserva', saved: 200, deadline: DateTime(2026, 9, 1)),
      goal(id: 'archived', name: 'Antiga', saved: 100, deadline: DateTime(2026, 8, 27), status: SavingsGoalStatus.archived),
    ]);

    expect(result, isNotNull);
    expect(result!.name, 'Reserva');
    expect(result.deadline, DateTime(2026, 9, 1));
  });

  test('prefers deadline goals over goals without deadline', () {
    final result = builder.buildGoal([
      goal(id: 'no-date', name: 'Sem prazo', saved: 900),
      goal(id: 'dated', name: 'Com prazo', saved: 100, deadline: DateTime(2026, 10, 1)),
    ]);

    expect(result!.name, 'Com prazo');
  });

  test('sums only open current-month invoices and uses nearest due date', () {
    final result = builder.buildInvoice([
      invoice(id: 'one', total: 400, dueDate: DateTime(2026, 8, 15)),
      invoice(id: 'two', total: 250, dueDate: DateTime(2026, 8, 10)),
      invoice(id: 'paid', total: 999, dueDate: DateTime(2026, 8, 5), status: CreditCardInvoiceModel.paidStatus),
      invoice(id: 'old', total: 800, dueDate: DateTime(2026, 7, 10), month: 7),
    ], reference);

    expect(result, isNotNull);
    expect(result!.total, 650);
    expect(result.invoiceCount, 2);
    expect(result.dueDate, DateTime(2026, 8, 10));
  });

  test('returns empty summary when no dashboard data exists', () {
    final result = builder.build(
      consumptions: const [],
      goals: const [],
      invoices: const [],
      reference: reference,
    );

    expect(result.budget, isNull);
    expect(result.goal, isNull);
    expect(result.invoice, isNull);
  });
}
