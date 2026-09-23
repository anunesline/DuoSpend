import 'package:app/features/home/data/models/credit_card_invoice_model.dart';
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/home/domain/services/orbit_home_overview_builder.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/transactions/domain/calendar/financial_calendar_service.dart';
import 'package:app/features/transactions/domain/calendar/financial_projection.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  const service = FinancialCalendarService();
  final today = DateTime(2026, 9, 23);
  final afterMidnight = DateTime(2026, 9, 23, 15);

  TransactionModel movement(
    String id,
    double value, {
    String type = 'expense',
    String status = 'pending',
    DateTime? date,
    bool recurring = false,
    String? paymentMethod,
  }) => TransactionModel(
    id: id,
    description: id,
    value: value,
    type: type,
    date: date ?? today,
    walletId: 'solo',
    category: 'Casa',
    subcategory: 'Outros',
    financialStatus: status,
    paymentMethod: paymentMethod,
    isRecurring: recurring,
    recurringId: recurring ? id : null,
    recurringFrequency: recurring ? 'monthly' : null,
    recurringStartDate: recurring ? DateTime(2026, 8, 23) : null,
  );

  FinancialProjection projection({
    required DateTime now,
    List<TransactionModel> transactions = const [],
    List<CreditCardInvoiceModel> invoices = const [],
  }) => service.buildProjection(
    currentBalance: 1000,
    transactions: transactions,
    invoices: invoices,
    rangeStart: DateTime(now.year, now.month, now.day),
    rangeEnd: DateTime(2026, 9, 30),
    now: now,
  );

  test('receita e despesa futuras e de hoje compõem a projeção', () {
    final transactions = [
      movement('receita', 900, type: 'income'),
      movement('despesa', 550),
      movement('futura', 100, date: DateTime(2026, 9, 25)),
    ];
    final result = projection(now: afterMidnight, transactions: transactions);
    expect(result.projectedIncome, 900);
    expect(result.projectedExpense, 650);
    expect(result.projectedBalance, 1250);
  });

  test('virada do dia não remove recorrência ainda não efetivada', () {
    final transactions = [
      movement('Vale', 900, type: 'income', recurring: true),
      movement('Tokita', 550, recurring: true),
    ];
    final yesterday = projection(
      now: DateTime(2026, 9, 22, 15),
      transactions: transactions,
    );
    final current = projection(now: afterMidnight, transactions: transactions);
    expect(yesterday.projectedBalance, 1350);
    expect(current.projectedBalance, 1350);
    expect(current.entries.where((entry) => entry.isProjected), hasLength(2));
  });

  test('efetivada fica na lista mas não é efeito pendente adicional', () {
    final pending = movement('Vale', 900, type: 'income');
    final before = projection(now: afterMidnight, transactions: [pending]);
    final settled = movement('Vale', 900, type: 'income', status: 'settled');
    final after = service.buildProjection(
      currentBalance: 1900,
      transactions: [settled],
      invoices: const [],
      rangeStart: today,
      rangeEnd: DateTime(2026, 9, 30),
      now: afterMidnight,
    );
    expect(before.projectedBalance, 1900);
    expect(after.projectedBalance, 1900);
    expect(after.entries.single.transaction?.id, 'Vale');
    expect(after.entries.single.isProjected, isFalse);
  });

  test('ocorrência original recorrente efetivada não é somada outra vez', () {
    final original = TransactionModel(
      id: 'recorrente',
      description: 'recorrente',
      value: 200,
      type: 'expense',
      date: today,
      walletId: 'solo',
      category: 'Casa',
      subcategory: 'Outros',
      financialStatus: 'settled',
      isRecurring: true,
      recurringId: 'recorrente',
      recurringFrequency: 'monthly',
      recurringStartDate: today,
    );
    final result = projection(now: afterMidnight, transactions: [original]);
    expect(result.entries.single.isProjected, isFalse);
    expect(result.projectedBalance, 1000);
  });

  test('fatura não é duplicada por compra no crédito', () {
    final invoice = CreditCardInvoiceModel(
      id: 'fatura',
      cardId: 'cartao',
      ownerMemberId: 'one',
      referenceYear: 2026,
      referenceMonth: 9,
      closingDate: today,
      dueDate: today,
      total: 1500,
      createdAt: today,
      updatedAt: today,
    );
    final result = projection(
      now: afterMidnight,
      transactions: [
        movement(
          'compra',
          1500,
          status: 'invoice',
          paymentMethod: 'creditCard',
        ),
      ],
      invoices: [invoice],
    );
    expect(result.projectedExpense, 1500);
    expect(result.projectedBalance, -500);
  });

  test('pendência vencida não entra fora do horizonte atual', () {
    final result = projection(
      now: afterMidnight,
      transactions: [movement('vencida', 200, date: DateTime(2026, 9, 22))],
    );
    expect(result.projectedBalance, 1000);
  });

  test('Home e Calendário preservam o mesmo resultado após recarga', () {
    final wallet = WalletModel(
      id: 'solo',
      name: 'Solo',
      balance: 1000,
      type: WalletType.individual,
      ownerId: 'one',
      memberIds: const ['one'],
    );
    final transactions = [
      movement('Vale', 900, type: 'income', recurring: true),
      movement('Tokita', 550, recurring: true),
    ];
    final home = const OrbitHomeOverviewBuilder().build(
      wallet: wallet,
      currentUserId: 'one',
      reference: afterMidnight,
      transactions: transactions,
    );
    final calendar = service.buildProjection(
      currentBalance: home.wallet.balance,
      transactions: transactions,
      invoices: const [],
      rangeStart: today,
      rangeEnd: DateTime(2026, 9, 30),
      now: afterMidnight,
    );
    final reloaded = service.buildProjection(
      currentBalance: home.wallet.balance,
      transactions: transactions,
      invoices: const [],
      rangeStart: today,
      rangeEnd: DateTime(2026, 9, 30),
      now: afterMidnight,
    );
    expect(home.projection!.projectedBalance, calendar.projectedBalance);
    expect(reloaded.projectedBalance, calendar.projectedBalance);
  });
}
