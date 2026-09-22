import 'package:app/features/financial_intelligence/domain/services/financial_intelligence_coordinator.dart';
import 'package:app/features/financial_intelligence/domain/facts/financial_facts.dart';
import 'package:app/features/financial_intelligence/domain/signals/financial_signals.dart';
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/home/data/models/credit_card_invoice_model.dart';
import 'package:app/features/budgets/domain/models/budget.dart';
import 'package:app/features/orbit_intelligence/domain/orbit_intelligence_item.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final wallet = WalletModel(
    id: 'wallet-a',
    name: 'A',
    balance: 0,
    ownerId: 'user-a',
    memberIds: const ['user-a'],
  );

  TransactionModel tx(String id, double value, DateTime date) =>
      TransactionModel(
        id: id,
        description: id,
        value: value,
        type: 'expense',
        date: date,
        walletId: wallet.id,
        category: 'Casa',
        subcategory: 'Geral',
        purchaseFor: 'self',
        splitType: 'none',
        financialStatus: 'settled',
        financialSettledAt: date,
      );

  test('real data traverses FI-A through FI-D without signal injection', () {
    final signals = const FinancialIntelligenceCoordinator().build(
      wallet: wallet,
      transactions: [
        tx('previous', 200, DateTime(2026, 8, 10)),
        tx('current', 260, DateTime(2026, 9, 10)),
      ],
      referenceAt: DateTime(2026, 9, 21),
    );
    expect(signals, hasLength(2));
    expect(
      signals.map((signal) => signal.type),
      contains(FinancialSignalType.spendingChanged),
    );
    expect(signals.every((signal) => signal.walletId == wallet.id), isTrue);
    expect(
      signals.map((signal) => signal.sourceMetric),
      contains(FinancialSignalMetric.realizedExpense),
    );
  });

  test('below threshold and missing history remain silent', () {
    final coordinator = const FinancialIntelligenceCoordinator();
    final below = coordinator.build(
      wallet: wallet,
      transactions: [
        tx('previous', 100, DateTime(2026, 8, 10)),
        tx('current', 130, DateTime(2026, 9, 10)),
      ],
      referenceAt: DateTime(2026, 9, 21),
    );
    final missing = coordinator.build(
      wallet: wallet,
      transactions: [tx('current', 260, DateTime(2026, 9, 10))],
      referenceAt: DateTime(2026, 9, 21),
    );
    expect(below, isEmpty);
    expect(missing, isEmpty);
  });

  test('foreign wallet sources do not generate signals', () {
    final other = tx(
      'foreign',
      900,
      DateTime(2026, 9, 10),
    ).copyWith(walletId: 'wallet-b');
    final signals = const FinancialIntelligenceCoordinator().build(
      wallet: wallet,
      transactions: [other],
      referenceAt: DateTime(2026, 9, 21),
    );
    expect(signals, isEmpty);
  });

  Budget budget(double limit, String walletId) => Budget(
    id: 'budget-$walletId',
    walletId: walletId,
    category: 'Casa',
    month: DateTime(2026, 9),
    limitAmount: limit,
    createdByUserId: 'user-a',
    createdAt: DateTime(2026, 1),
    updatedAt: DateTime(2026, 1),
  );

  test('budget current-state uses BudgetConsumptionService semantics', () {
    final coordinator = const FinancialIntelligenceCoordinator();
    final transactions = [tx('spent', 120, DateTime(2026, 9, 10))];
    expect(
      coordinator
          .build(
            wallet: wallet,
            transactions: transactions,
            budgets: [budget(100, wallet.id)],
            referenceAt: DateTime(2026, 9, 22),
          )
          .where((s) => s.type == FinancialSignalType.budgetExceeded),
      hasLength(1),
    );
    for (final limit in [120.0, 140.0]) {
      expect(
        coordinator
            .build(
              wallet: wallet,
              transactions: transactions,
              budgets: [budget(limit, wallet.id)],
              referenceAt: DateTime(2026, 9, 22),
            )
            .where((s) => s.type == FinancialSignalType.budgetExceeded),
        isEmpty,
      );
    }
    expect(
      coordinator
          .build(
            wallet: wallet,
            transactions: transactions,
            budgets: [budget(100, 'wallet-b')],
            referenceAt: DateTime(2026, 9, 22),
          )
          .where((s) => s.type == FinancialSignalType.budgetExceeded),
      isEmpty,
    );
  });

  test('commitment horizon is the current month end', () {
    TransactionModel pending(DateTime date) => tx(
      'pending-${date.day}',
      80,
      date,
    ).copyWith(financialStatus: 'pending');
    final coordinator = const FinancialIntelligenceCoordinator();
    final inside = coordinator.build(
      wallet: wallet,
      transactions: [pending(DateTime(2026, 9, 28))],
      referenceAt: DateTime(2026, 9, 22),
    );
    final outside = coordinator.build(
      wallet: wallet,
      transactions: [tx('future-settled', 80, DateTime(2026, 10, 10))],
      referenceAt: DateTime(2026, 9, 22),
    );
    expect(
      inside.where((s) => s.type == FinancialSignalType.knownCommitment),
      hasLength(1),
    );
    expect(
      outside.where((s) => s.type == FinancialSignalType.knownCommitment),
      isEmpty,
    );
    for (final date in [
      DateTime(2026, 9, 22),
      DateTime(2026, 1, 15),
      DateTime(2024, 2, 10),
      DateTime(2023, 2, 10),
    ]) {
      final last = DateTime(date.year, date.month + 1, 0);
      expect(last.day, anyOf(28, 29, 30, 31));
    }
  });

  CreditCardInvoiceModel invoice(DateTime due, String status) =>
      CreditCardInvoiceModel(
        id: 'invoice-${due.day}-$status',
        cardId: 'card-a',
        ownerMemberId: 'user-a',
        referenceYear: 2026,
        referenceMonth: 9,
        closingDate: DateTime(2026, 9, 1),
        dueDate: due,
        total: 200,
        status: status,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );

  test('invoice current-state distinguishes due, overdue, paid and wallet', () {
    final coordinator = const FinancialIntelligenceCoordinator();
    List<FinancialSignal> run(
      CreditCardInvoiceModel item, {
      String walletId = 'wallet-a',
    }) => coordinator.build(
      wallet: wallet,
      transactions: const [],
      referenceAt: DateTime(2026, 9, 22),
      invoices: [FinancialCardInvoiceSource(invoice: item, walletId: walletId)],
    );
    expect(
      run(
        invoice(DateTime(2026, 9, 22), CreditCardInvoiceModel.openStatus),
      ).where((s) => s.type == FinancialSignalType.invoiceDue),
      hasLength(1),
    );
    expect(
      run(
        invoice(DateTime(2026, 9, 30), CreditCardInvoiceModel.openStatus),
      ).where((s) => s.type == FinancialSignalType.invoiceDue),
      hasLength(1),
    );
    expect(
      run(
        invoice(DateTime(2026, 9, 21), CreditCardInvoiceModel.openStatus),
      ).where((s) => s.type == FinancialSignalType.invoiceOverdue),
      hasLength(1),
    );
    expect(
      run(
        invoice(DateTime(2026, 9, 21), CreditCardInvoiceModel.paidStatus),
      ).where((s) => s.type.toString().contains('invoice')),
      isEmpty,
    );
    expect(
      run(
        invoice(DateTime(2026, 9, 21), CreditCardInvoiceModel.openStatus),
        walletId: 'wallet-b',
      ),
      isEmpty,
    );
  });

  test('current-state reaches Central as financial insight', () {
    final signals = const FinancialIntelligenceCoordinator().build(
      wallet: wallet,
      transactions: const [],
      invoices: [
        FinancialCardInvoiceSource(
          invoice: invoice(
            DateTime(2026, 9, 30),
            CreditCardInvoiceModel.openStatus,
          ),
          walletId: wallet.id,
        ),
      ],
      referenceAt: DateTime(2026, 9, 22),
    );
    final items = const OrbitIntelligenceOrchestrator().build(
      consumption: [],
      financial: FinancialCentralAdapter().adapt(signals),
    );
    expect(items, isNotEmpty);
    final financial = items
        .where((item) => item.domain == OrbitIntelligenceDomain.financial)
        .toList();
    expect(financial, isNotEmpty);
    expect(
      financial.every((item) => item.kind == OrbitIntelligenceKind.insight),
      isTrue,
    );
    expect(financial.every((item) => item.action == null), isTrue);
  });
}
