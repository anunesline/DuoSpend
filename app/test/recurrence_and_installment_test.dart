import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/transactions/domain/models/recurring_transaction_frequency.dart';
import 'package:app/features/transactions/domain/services/installment_service.dart';
import 'package:app/features/transactions/domain/services/recurring_transaction_service.dart';
import 'package:app/features/transactions/domain/usecases/create_installment_transactions_usecase.dart';

void main() {
  const recurringService = RecurringTransactionService();
  const installmentService = InstallmentService();

  TransactionModel recurringTransaction({
    required String frequency,
    required DateTime start,
    DateTime? end,
    bool neverEnds = true,
  }) {
    return TransactionModel(
      id: 'recurring-test',
      description: 'Transação recorrente',
      value: 100,
      type: 'expense',
      date: start,
      walletId: 'wallet-test',
      category: 'Casa',
      subcategory: 'Contas',
      isRecurring: true,
      recurringId: 'series-test',
      recurringFrequency: frequency,
      recurringStartDate: start,
      recurringEndDate: end,
      recurringNeverEnds: neverEnds,
    );
  }

  group('Recorrências', () {
    test('calcula próxima ocorrência diária', () {
      final next = recurringService.calculateNextOccurrence(
        currentDate: DateTime(2026, 8, 25),
        frequency: RecurringTransactionFrequency.daily,
      );

      expect(next, DateTime(2026, 8, 26));
    });

    test('calcula próxima ocorrência semanal', () {
      final next = recurringService.calculateNextOccurrence(
        currentDate: DateTime(2026, 8, 25),
        frequency: RecurringTransactionFrequency.weekly,
      );

      expect(next, DateTime(2026, 9, 1));
    });

    test('mantém a âncora mensal após fevereiro', () {
      final transaction = recurringTransaction(
        frequency: 'monthly',
        start: DateTime(2027, 1, 31),
      );

      final occurrences = recurringService.generateOccurrences(
        transaction: transaction,
        rangeStart: DateTime(2027, 1, 1),
        rangeEnd: DateTime(2027, 4, 30),
      );

      expect(
        occurrences,
        [
          DateTime(2027, 1, 31),
          DateTime(2027, 2, 28),
          DateTime(2027, 3, 31),
          DateTime(2027, 4, 30),
        ],
      );
    });

    test('ajusta recorrência anual de 29 de fevereiro', () {
      final transaction = recurringTransaction(
        frequency: 'yearly',
        start: DateTime(2028, 2, 29),
      );

      final occurrences = recurringService.generateOccurrences(
        transaction: transaction,
        rangeStart: DateTime(2028, 1, 1),
        rangeEnd: DateTime(2032, 12, 31),
      );

      expect(
        occurrences,
        [
          DateTime(2028, 2, 29),
          DateTime(2029, 2, 28),
          DateTime(2030, 2, 28),
          DateTime(2031, 2, 28),
          DateTime(2032, 2, 29),
        ],
      );
    });

    test('recorrência diária respeita data final inclusiva', () {
      final transaction = recurringTransaction(
        frequency: 'daily',
        start: DateTime(2026, 8, 25),
        end: DateTime(2026, 8, 27),
        neverEnds: false,
      );

      final occurrences = recurringService.generateOccurrences(
        transaction: transaction,
        rangeStart: DateTime(2026, 8, 1),
        rangeEnd: DateTime(2026, 8, 31),
      );

      expect(
        occurrences,
        [
          DateTime(2026, 8, 25),
          DateTime(2026, 8, 26),
          DateTime(2026, 8, 27),
        ],
      );
    });

    test('recorrência semanal sem fim gera dentro do intervalo', () {
      final transaction = recurringTransaction(
        frequency: 'weekly',
        start: DateTime(2026, 8, 3),
      );

      final occurrences = recurringService.generateOccurrences(
        transaction: transaction,
        rangeStart: DateTime(2026, 8, 1),
        rangeEnd: DateTime(2026, 8, 31),
      );

      expect(
        occurrences,
        [
          DateTime(2026, 8, 3),
          DateTime(2026, 8, 10),
          DateTime(2026, 8, 17),
          DateTime(2026, 8, 24),
          DateTime(2026, 8, 31),
        ],
      );
    });

    test('não gera ocorrência depois do encerramento', () {
      final transaction = recurringTransaction(
        frequency: 'monthly',
        start: DateTime(2026, 1, 15),
        end: DateTime(2026, 3, 15),
        neverEnds: false,
      );

      final next = recurringService.findNextOccurrence(
        transaction: transaction,
        referenceDate: DateTime(2026, 4, 1),
      );

      expect(next, isNull);
    });

    test('rejeita intervalo invertido', () {
      final transaction = recurringTransaction(
        frequency: 'daily',
        start: DateTime(2026, 8, 25),
      );

      final occurrences = recurringService.generateOccurrences(
        transaction: transaction,
        rangeStart: DateTime(2026, 8, 31),
        rangeEnd: DateTime(2026, 8, 1),
      );

      expect(occurrences, isEmpty);
    });
  });

  group('Parcelamentos', () {
    test('divide o total em centavos sem perder valor', () {
      final plan = installmentService.createPlan(
        groupId: 'group-test',
        totalValue: 100,
        installmentCount: 3,
        firstInstallmentDate: DateTime(2026, 1, 31),
      );

      expect(
        plan.installments.map((item) => item.value).toList(),
        [33.34, 33.33, 33.33],
      );
      expect(
        plan.installments.fold<double>(
          0,
          (sum, item) => sum + item.value,
        ),
        closeTo(100, 0.001),
      );
    });

    test('preserva a âncora mensal no fim do mês', () {
      final plan = installmentService.createPlan(
        groupId: 'group-test',
        totalValue: 300,
        installmentCount: 3,
        firstInstallmentDate: DateTime(2027, 1, 31),
      );

      expect(
        plan.installments.map((item) => item.date).toList(),
        [
          DateTime(2027, 1, 31),
          DateTime(2027, 2, 28),
          DateTime(2027, 3, 31),
        ],
      );
    });

    test('rejeita parcelamento com menos de duas parcelas', () {
      expect(
        () => installmentService.createPlan(
          groupId: 'group-test',
          totalValue: 100,
          installmentCount: 1,
          firstInstallmentDate: DateTime(2026, 1, 1),
        ),
        throwsException,
      );
    });

    test('use case marca número, total e grupo de cada parcela', () {
      const useCase = CreateInstallmentTransactionsUseCase();
      final base = TransactionModel(
        id: 'purchase-test',
        description: 'Compra parcelada',
        value: 120,
        type: 'expense',
        date: DateTime(2026, 8, 25),
        walletId: 'wallet-test',
        category: 'Casa',
        subcategory: 'Compras',
      );

      final installments = useCase.execute(
        transaction: base,
        installmentCount: 3,
        firstInstallmentDate: DateTime(2026, 8, 25),
      );

      expect(installments, hasLength(3));
      expect(
        installments.map((item) => item.installmentNumber).toList(),
        [1, 2, 3],
      );
      expect(
        installments.every(
          (item) =>
              item.isInstallment &&
              item.installmentCount == 3 &&
              item.installmentGroupId == 'purchase-test',
        ),
        isTrue,
      );
    });

    test('não permite recorrência e parcelamento juntos', () {
      const useCase = CreateInstallmentTransactionsUseCase();
      final recurring = recurringTransaction(
        frequency: 'monthly',
        start: DateTime(2026, 8, 25),
      );

      expect(
        () => useCase.execute(
          transaction: recurring,
          installmentCount: 3,
          firstInstallmentDate: DateTime(2026, 8, 25),
        ),
        throwsException,
      );
    });
  });
}
