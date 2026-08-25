import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/budgets/domain/models/budget.dart';
import 'package:app/features/budgets/domain/models/budget_consumption.dart';
import 'package:app/features/budgets/domain/services/budget_consumption_service.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';

void main() {
  const service = BudgetConsumptionService();
  final budget = Budget(id: 'budget', walletId: 'wallet', category: 'Mercado', month: DateTime(2026, 8), limitAmount: 100, createdByUserId: 'user', createdAt: DateTime(2026, 8, 1), updatedAt: DateTime(2026, 8, 1));
  TransactionModel expense({double value = 50, String category = 'Mercado', DateTime? date, bool settlement = false}) => TransactionModel(id: '${value}_${category}_${date}', description: 'Compra', value: value, type: 'expense', date: date ?? DateTime(2026, 8, 10), walletId: 'wallet', category: category, subcategory: 'Geral', isSettlement: settlement);

  test('calcula gasto abaixo do limite e categoria sem gasto', () {
    final result = service.calculate(budget: budget, transactions: [expense(value: 50)]);
    expect(result.spentAmount, 50); expect(result.remainingAmount, 50); expect(result.health, BudgetHealth.healthy);
    expect(service.calculate(budget: budget, transactions: [expense(category: 'Lazer')]).spentAmount, 0);
  });

  test('identifica atenção, limite exato e estouro', () {
    expect(service.calculate(budget: budget, transactions: [expense(value: 80)]).health, BudgetHealth.attention);
    final exact = service.calculate(budget: budget, transactions: [expense(value: 100)]);
    expect(exact.percentageDisplay, 100); expect(exact.remainingAmount, 0); expect(exact.health, BudgetHealth.attention);
    expect(service.calculate(budget: budget, transactions: [expense(value: 101)]).health, BudgetHealth.exceeded);
  });

  test('ignora outro mês, outra carteira, receitas e settlements', () {
    final income = TransactionModel(id: 'income', description: 'Salário', value: 500, type: 'income', date: DateTime(2026, 8, 1), walletId: 'wallet', category: 'Mercado', subcategory: 'Geral');
    final otherWallet = TransactionModel(id: 'other', description: 'Compra', value: 90, type: 'expense', date: DateTime(2026, 8, 1), walletId: 'other', category: 'Mercado', subcategory: 'Geral');
    final result = service.calculate(budget: budget, transactions: [expense(value: 20, date: DateTime(2026, 9, 1)), expense(value: 30, settlement: true), income, otherWallet]);
    expect(result.spentAmount, 0);
  });

  test('recalcula após alteração de categoria, mês ou exclusão', () {
    final original = expense(value: 70);
    expect(service.calculate(budget: budget, transactions: [original]).spentAmount, 70);

    final movedCategory = expense(value: 70, category: 'Lazer');
    expect(service.calculate(budget: budget, transactions: [movedCategory]).spentAmount, 0);

    final movedMonth = expense(value: 70, date: DateTime(2026, 9, 1));
    expect(service.calculate(budget: budget, transactions: [movedMonth]).spentAmount, 0);
    expect(service.calculate(budget: budget, transactions: const []).spentAmount, 0);
  });
}
