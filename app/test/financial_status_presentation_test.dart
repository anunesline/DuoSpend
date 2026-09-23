import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/transactions/domain/calendar/financial_calendar_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TransactionModel transaction(String status) => TransactionModel(
    id: status,
    description: 'Movimentação $status',
    value: 100,
    type: 'expense',
    date: DateTime(2026, 9, 23),
    walletId: 'solo',
    category: 'Casa',
    subcategory: 'Outros',
    financialStatus: status,
  );

  test('Calendário distingue previsão de efetivação', () {
    final pending = FinancialCalendarEntry(
      id: 'pending',
      title: 'Pendente',
      value: 100,
      type: 'expense',
      date: DateTime(2026, 9, 23),
      kind: FinancialCalendarEntryKind.transaction,
      isProjected: true,
    );
    final settled = FinancialCalendarEntry(
      id: 'settled',
      title: 'Liquidada',
      value: 100,
      type: 'expense',
      date: DateTime(2026, 9, 23),
      kind: FinancialCalendarEntryKind.transaction,
      isProjected: false,
    );
    expect(pending.financialStatusLabel, 'Prevista');
    expect(settled.financialStatusLabel, 'Efetivada');
  });

  test('detalhe recebe o estado financeiro do domínio', () {
    expect(transaction('pending').financialStatusLabel, 'Prevista');
    expect(transaction('settled').financialStatusLabel, 'Efetivada');
  });
}
