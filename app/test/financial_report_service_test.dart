import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/reports/domain/services/financial_report_service.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/transactions/domain/models/shared_transaction_confirmation_status.dart';

void main() {
  const service = FinancialReportService();

  TransactionModel transaction({
    required String id,
    required double value,
    required String type,
    required DateTime date,
    String category = 'Outros',
    String financialStatus = 'settled',
    bool isSettlement = false,
    String splitType = 'none',
    Map<String, double> memberShares = const {},
    SharedTransactionConfirmationStatus confirmationStatus =
        SharedTransactionConfirmationStatus.accepted,
  }) {
    return TransactionModel(
      id: id,
      description: id,
      value: value,
      type: type,
      date: date,
      walletId: 'wallet-1',
      category: category,
      subcategory: 'Geral',
      financialStatus: financialStatus,
      isSettlement: isSettlement,
      splitType: splitType,
      memberShares: memberShares,
      purchaseFor: splitType == 'none' ? 'self' : 'both',
      confirmationStatus: confirmationStatus,
    );
  }

  group('FinancialReportService', () {
    test('calcula receitas, despesas e resultado mensal', () {
      final report = service.buildMonthly(
        year: 2026,
        month: DateTime.august,
        transactions: [
          transaction(
            id: 'income',
            value: 3000,
            type: 'income',
            date: DateTime(2026, 8, 1),
          ),
          transaction(
            id: 'expense',
            value: 1250,
            type: 'expense',
            date: DateTime(2026, 8, 31),
          ),
          transaction(
            id: 'outside',
            value: 500,
            type: 'expense',
            date: DateTime(2026, 9, 1),
          ),
        ],
      );

      expect(report.totalIncome, 3000);
      expect(report.totalExpense, 1250);
      expect(report.balance, 1750);
      expect(report.transactions, hasLength(2));
    });

    test('agrupa despesas por categoria e ordena pelo maior valor', () {
      final report = service.buildMonthly(
        year: 2026,
        month: DateTime.august,
        transactions: [
          transaction(
            id: 'market-1',
            value: 300,
            type: 'expense',
            category: 'Mercado',
            date: DateTime(2026, 8, 2),
          ),
          transaction(
            id: 'home',
            value: 200,
            type: 'expense',
            category: 'Casa',
            date: DateTime(2026, 8, 3),
          ),
          transaction(
            id: 'market-2',
            value: 100,
            type: 'expense',
            category: 'Mercado',
            date: DateTime(2026, 8, 4),
          ),
        ],
      );

      expect(report.expenseByCategory, hasLength(2));
      expect(report.expenseByCategory.first.category, 'Mercado');
      expect(report.expenseByCategory.first.amount, 400);
      expect(report.expenseByCategory.first.percentage, closeTo(66.67, 0.01));
      expect(report.expenseByCategory.last.category, 'Casa');
    });

    test('ignora obrigações pendentes, faturas e acertos internos', () {
      final report = service.buildMonthly(
        year: 2026,
        month: DateTime.august,
        transactions: [
          transaction(
            id: 'settled',
            value: 100,
            type: 'expense',
            date: DateTime(2026, 8, 1),
          ),
          transaction(
            id: 'pending',
            value: 200,
            type: 'expense',
            date: DateTime(2026, 8, 2),
            financialStatus: 'pending',
          ),
          transaction(
            id: 'invoice',
            value: 300,
            type: 'expense',
            date: DateTime(2026, 8, 3),
            financialStatus: 'invoice',
          ),
          transaction(
            id: 'settlement',
            value: 400,
            type: 'income',
            date: DateTime(2026, 8, 4),
            isSettlement: true,
          ),
        ],
      );

      expect(report.totalIncome, 0);
      expect(report.totalExpense, 100);
      expect(report.transactions.single.id, 'settled');
    });

    test('ignora despesa compartilhada ainda não confirmada', () {
      final report = service.buildMonthly(
        year: 2026,
        month: DateTime.august,
        transactions: [
          transaction(
            id: 'pending-shared',
            value: 150,
            type: 'expense',
            date: DateTime(2026, 8, 5),
            splitType: 'equal',
            memberShares: const {
              'user-1': 75,
              'user-2': 75,
            },
            confirmationStatus:
                SharedTransactionConfirmationStatus.pending,
          ),
        ],
      );

      expect(report.isEmpty, isTrue);
      expect(report.totalExpense, 0);
    });

    test('inclui as datas inicial e final do período', () {
      final report = service.build(
        startDate: DateTime(2026, 8, 10, 18),
        endDate: DateTime(2026, 8, 20, 8),
        transactions: [
          transaction(
            id: 'start',
            value: 10,
            type: 'expense',
            date: DateTime(2026, 8, 10),
          ),
          transaction(
            id: 'end',
            value: 20,
            type: 'expense',
            date: DateTime(2026, 8, 20, 23, 59),
          ),
        ],
      );

      expect(report.totalExpense, 30);
    });

    test('rejeita período invertido e mês inválido', () {
      expect(
        () => service.build(
          transactions: const [],
          startDate: DateTime(2026, 8, 2),
          endDate: DateTime(2026, 8, 1),
        ),
        throwsArgumentError,
      );

      expect(
        () => service.buildMonthly(
          transactions: const [],
          year: 2026,
          month: 13,
        ),
        throwsArgumentError,
      );
    });
  });
}
