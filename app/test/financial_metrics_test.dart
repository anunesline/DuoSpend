import 'package:app/features/financial_intelligence/domain/facts/financial_facts.dart';
import 'package:app/features/financial_intelligence/domain/metrics/financial_metrics.dart';
import 'package:app/features/budgets/domain/models/budget.dart';
import 'package:app/features/home/data/models/credit_card_model.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/home/data/models/credit_card_invoice_model.dart';

FinancialFactBundle _bundle({
  required String id,
  required DateTime date,
  required FinancialEconomicNature nature,
  required double amount,
  String? category,
  FinancialKnownCommitment? commitment,
}) {
  return FinancialFactBundle(
    source: FinancialFactSource(
      kind: FinancialFactSourceKind.transaction,
      id: id,
      walletId: 'w',
      walletScope: FinancialWalletScope.individualWallet,
      category: category,
    ),
    economic: FinancialEconomicFact(
      nature: nature,
      amount: amount,
      occurredAt: date,
    ),
    commitment: commitment,
  );
}

FinancialFactBundle _fact({
  String id = 'fact',
  FinancialFactSourceKind kind = FinancialFactSourceKind.transaction,
  DateTime? economicAt,
  FinancialEconomicNature? economicNature,
  double economicAmount = 0,
  DateTime? cashAt,
  FinancialCashNature? cashNature,
  double cashAmount = 0,
  FinancialKnownCommitment? commitment,
  List<FinancialMemberResponsibility> responsibilities = const [],
  String? category,
  String? paidByMemberId,
  String? purchaseFor,
}) => FinancialFactBundle(
  source: FinancialFactSource(
    kind: kind,
    id: id,
    walletId: 'w',
    walletScope: FinancialWalletScope.individualWallet,
    category: category,
    paidByMemberId: paidByMemberId,
    purchaseFor: purchaseFor,
  ),
  economic: economicNature == null || economicAt == null
      ? null
      : FinancialEconomicFact(
          nature: economicNature,
          amount: economicAmount,
          occurredAt: economicAt,
        ),
  cash: cashNature == null || cashAt == null
      ? null
      : FinancialCashFact(
          nature: cashNature,
          amount: cashAmount,
          occurredAt: cashAt,
        ),
  commitment: commitment,
  responsibilities: responsibilities,
);

FinancialFactNormalizationResult _facts(List<FinancialFactBundle> values) =>
    FinancialFactNormalizationResult(
      facts: values,
      suppressedSources: const [],
    );

TransactionModel _transaction({required String id, required String status}) =>
    TransactionModel(
      id: id,
      description: id,
      value: 100,
      type: 'expense',
      date: DateTime(2026, 9, 10),
      walletId: 'w',
      category: 'food',
      subcategory: 'general',
      financialStatus: status,
    );

void main() {
  const calculator = FinancialMetricsCalculator();

  test('interval is inclusive and categories are calculated after summing', () {
    final result = calculator.calculate(
      facts: FinancialFactNormalizationResult(
        facts: [
          _bundle(
            id: 'start',
            date: DateTime(2026, 9, 1),
            nature: FinancialEconomicNature.expense,
            amount: 20,
            category: 'food',
          ),
          _bundle(
            id: 'end',
            date: DateTime(2026, 9, 21),
            nature: FinancialEconomicNature.expense,
            amount: 30,
            category: 'food',
          ),
          _bundle(
            id: 'outside',
            date: DateTime(2026, 9, 22),
            nature: FinancialEconomicNature.expense,
            amount: 99,
            category: 'food',
          ),
        ],
        suppressedSources: const [],
      ),
      periodStart: DateTime(2026, 9, 1),
      periodEnd: DateTime(2026, 9, 21),
    );
    expect(result.realizedExpense.value, 50);
    expect(result.categories.single.shareOfExpense, 1);
  });

  test('linked invoice commitment does not duplicate its transaction', () {
    final result = calculator.calculate(
      facts: FinancialFactNormalizationResult(
        facts: [
          _bundle(
            id: 'tx',
            date: DateTime(2026, 9, 10),
            nature: FinancialEconomicNature.expense,
            amount: 100,
            commitment: FinancialKnownCommitment(
              kind: FinancialCommitmentKind.installment,
              direction: FinancialCommitmentDirection.outflow,
              amount: 100,
              dueAt: DateTime(2026, 9, 10),
            ),
          ),
          FinancialFactBundle(
            source: const FinancialFactSource(
              kind: FinancialFactSourceKind.creditCardInvoice,
              id: 'card:inv',
              walletId: 'w',
              walletScope: FinancialWalletScope.individualWallet,
            ),
            commitment: FinancialKnownCommitment(
              kind: FinancialCommitmentKind.creditCardInvoice,
              direction: FinancialCommitmentDirection.outflow,
              amount: 100,
              dueAt: DateTime(2026, 9, 20),
            ),
          ),
        ],
        suppressedSources: const [],
      ),
      periodStart: DateTime(2026, 9, 1),
      periodEnd: DateTime(2026, 9, 30),
      invoiceLinks: const [
        FinancialInvoiceTransactionLink(transactionId: 'tx', invoiceId: 'inv'),
      ],
      invoices: [_invoice('inv', DateTime(2026, 9, 20))],
    );
    expect(result.realizedExpense.value, 100);
    expect(result.commitmentOutflow.value, 100);
  });

  test('invoice horizon filters open invoices and validates links', () {
    final facts = FinancialFactNormalizationResult(
      facts: [
        _bundle(
          id: 'tx',
          date: DateTime(2026, 9, 10),
          nature: FinancialEconomicNature.expense,
          amount: 100,
          commitment: FinancialKnownCommitment(
            kind: FinancialCommitmentKind.installment,
            direction: FinancialCommitmentDirection.outflow,
            amount: 100,
            dueAt: DateTime(2026, 9, 10),
          ),
        ),
      ],
      suppressedSources: const [],
    );
    final result = calculator.calculate(
      facts: facts,
      periodStart: DateTime(2026, 9, 1),
      periodEnd: DateTime(2026, 9, 30),
      commitmentRangeEnd: DateTime(2026, 9, 21),
      invoiceLinks: const [
        FinancialInvoiceTransactionLink(
          transactionId: 'tx',
          invoiceId: 'missing',
        ),
      ],
      invoices: [
        _invoice('inside', DateTime(2026, 9, 20)),
        _invoice('outside', DateTime(2026, 10, 1)),
        _invoice('paid', DateTime(2026, 9, 15), paid: true),
      ],
    );
    expect(result.commitmentOutflow.value, 100);
    expect(result.realizedExpense.value, 100);
  });

  test('zero expense has finite category shares and invalid period throws', () {
    final facts = FinancialFactNormalizationResult(
      facts: const [],
      suppressedSources: const [],
    );
    final result = calculator.calculate(
      facts: facts,
      periodStart: DateTime(2026, 9, 1),
      periodEnd: DateTime(2026, 9, 1),
    );
    expect(result.realizedExpense.value, 0);
    expect(result.categories, isEmpty);
    expect(
      () => calculator.calculate(
        facts: facts,
        periodStart: DateTime(2026, 9, 2),
        periodEnd: DateTime(2026, 9, 1),
      ),
      throwsArgumentError,
    );
  });

  test('commitment direction aggregates inflow, outflow and net', () {
    final result = calculator.calculate(
      facts: FinancialFactNormalizationResult(
        facts: [
          _bundle(
            id: 'out',
            date: DateTime(2026, 9, 10),
            nature: FinancialEconomicNature.expense,
            amount: 500,
            commitment: FinancialKnownCommitment(
              kind: FinancialCommitmentKind.pending,
              direction: FinancialCommitmentDirection.outflow,
              amount: 500,
              dueAt: DateTime(2026, 9, 10),
            ),
          ),
          _bundle(
            id: 'in',
            date: DateTime(2026, 9, 11),
            nature: FinancialEconomicNature.income,
            amount: 200,
            commitment: FinancialKnownCommitment(
              kind: FinancialCommitmentKind.pending,
              direction: FinancialCommitmentDirection.inflow,
              amount: 200,
              dueAt: DateTime(2026, 9, 11),
            ),
          ),
        ],
        suppressedSources: const [],
      ),
      periodStart: DateTime(2026, 9, 1),
      periodEnd: DateTime(2026, 9, 30),
    );
    expect(result.commitmentOutflow.value, 500);
    expect(result.commitmentInflow.value, 200);
    expect(result.commitmentNet.value, -300);
  });

  test('A B1 B2 B3 B4 B22 economic and cash dimensions remain independent', () {
    final result = calculator.calculate(
      facts: _facts([
        _fact(
          id: 'income',
          economicAt: DateTime(2026, 9, 10),
          economicNature: FinancialEconomicNature.income,
          economicAmount: 100,
          cashAt: DateTime(2026, 9, 10),
          cashNature: FinancialCashNature.inflow,
          cashAmount: 100,
        ),
        _fact(
          id: 'debit',
          economicAt: DateTime(2026, 9, 10),
          economicNature: FinancialEconomicNature.expense,
          economicAmount: 40,
          cashAt: DateTime(2026, 9, 10),
          cashNature: FinancialCashNature.outflow,
          cashAmount: 40,
        ),
        _fact(
          id: 'card',
          economicAt: DateTime(2026, 9, 11),
          economicNature: FinancialEconomicNature.expense,
          economicAmount: 60,
        ),
        _fact(
          id: 'invoice-payment',
          cashAt: DateTime(2026, 9, 12),
          cashNature: FinancialCashNature.invoicePaymentOut,
          cashAmount: 60,
        ),
        _fact(
          id: 'transfer',
          kind: FinancialFactSourceKind.accountTransfer,
          cashAt: DateTime(2026, 9, 12),
          cashNature: FinancialCashNature.internalTransferOut,
          cashAmount: 20,
        ),
        _fact(
          id: 'settlement',
          kind: FinancialFactSourceKind.settlement,
          cashAt: DateTime(2026, 9, 12),
          cashNature: FinancialCashNature.settlementOut,
          cashAmount: 10,
        ),
      ]),
      periodStart: DateTime(2026, 9, 1),
      periodEnd: DateTime(2026, 9, 30),
    );
    expect(result.realizedIncome.value, 100);
    expect(result.realizedExpense.value, 100);
    expect(result.economicNet.value, 0);
    expect(result.cashInflow.value, 100);
    expect(result.cashOutflow.value, 130);
    expect(result.cashNet.value, -30);
  });

  test(
    'B5 B6 D pending and future installment are commitments, not economic facts',
    () {
      final result = calculator.calculate(
        facts: _facts([
          _fact(
            id: 'current',
            economicAt: DateTime(2026, 9, 10),
            economicNature: FinancialEconomicNature.expense,
            economicAmount: 100,
          ),
          _fact(
            id: 'future',
            commitment: FinancialKnownCommitment(
              kind: FinancialCommitmentKind.installment,
              direction: FinancialCommitmentDirection.outflow,
              amount: 100,
              dueAt: DateTime(2026, 9, 20),
            ),
          ),
          _fact(
            id: 'pending',
            commitment: FinancialKnownCommitment(
              kind: FinancialCommitmentKind.pending,
              direction: FinancialCommitmentDirection.outflow,
              amount: 40,
              dueAt: DateTime(2026, 9, 15),
            ),
          ),
        ]),
        periodStart: DateTime(2026, 9, 1),
        periodEnd: DateTime(2026, 9, 30),
      );
      expect(result.realizedExpense.value, 100);
      expect(result.commitmentOutflow.value, 140);
    },
  );

  test('F B9 B10 B11 responsibilities are decomposition only', () {
    final result = calculator.calculate(
      facts: _facts([
        _fact(
          id: 'shared',
          economicAt: DateTime(2026, 9, 10),
          economicNature: FinancialEconomicNature.expense,
          economicAmount: 100,
          paidByMemberId: 'payer',
          purchaseFor: 'both',
          responsibilities: const [
            FinancialMemberResponsibility(memberId: 'one', amount: 50),
            FinancialMemberResponsibility(memberId: 'two', amount: 50),
          ],
        ),
        _fact(
          id: 'metadata-only',
          economicAt: DateTime(2026, 9, 10),
          economicNature: FinancialEconomicNature.expense,
          economicAmount: 20,
          paidByMemberId: 'other',
          purchaseFor: 'partner',
        ),
      ]),
      periodStart: DateTime(2026, 9, 1),
      periodEnd: DateTime(2026, 9, 30),
    );
    expect(result.realizedExpense.value, 120);
    expect(
      result.responsibilities.map((x) => x.amount).reduce((a, b) => a + b),
      100,
    );
    expect(
      result.responsibilities.map((x) => x.memberId),
      isNot(contains('payer')),
    );
  });

  test('G B7 B8 categories use eligible expenses and zero stays finite', () {
    final result = calculator.calculate(
      facts: _facts([
        _fact(
          id: 'food',
          economicAt: DateTime(2026, 9, 10),
          economicNature: FinancialEconomicNature.expense,
          economicAmount: 30,
          category: 'food',
        ),
        _fact(
          id: 'home',
          economicAt: DateTime(2026, 9, 10),
          economicNature: FinancialEconomicNature.expense,
          economicAmount: 70,
          category: 'home',
        ),
        _fact(
          id: 'income',
          economicAt: DateTime(2026, 9, 10),
          economicNature: FinancialEconomicNature.income,
          economicAmount: 99,
          category: 'food',
        ),
      ]),
      periodStart: DateTime(2026, 9, 1),
      periodEnd: DateTime(2026, 9, 30),
    );
    expect(result.categories.map((x) => x.amount).reduce((a, b) => a + b), 100);
    expect(
      result.categories.map((x) => x.shareOfExpense).reduce((a, b) => a + b),
      1,
    );
    expect(result.categories.every((x) => x.shareOfExpense.isFinite), isTrue);
  });

  test(
    'E B14 budget consumption intentionally diverges from economic facts',
    () {
      final budget = Budget(
        id: 'b',
        walletId: 'w',
        category: 'food',
        month: DateTime(2026, 9),
        limitAmount: 200,
        createdByUserId: 'u',
        createdAt: DateTime(2026, 9),
        updatedAt: DateTime(2026, 9),
      );
      final result = calculator.calculate(
        facts: _facts(const []),
        periodStart: DateTime(2026, 9, 1),
        periodEnd: DateTime(2026, 9, 30),
        budget: budget,
        budgetTransactions: [_transaction(id: 'pending', status: 'pending')],
      );
      expect(result.realizedExpense.value, 0);
      expect(result.budget?.consumed.value, 100);
    },
  );

  test('B15 B16 card metrics use snapshot and model clamp', () {
    const card = CreditCardModel(
      id: 'c',
      ownerMemberId: 'u',
      name: 'card',
      creditLimit: 100,
      usedLimit: 140,
      closingDay: 1,
      dueDay: 10,
    );
    final result = calculator.calculate(
      facts: _facts(const []),
      periodStart: DateTime(2026, 9, 1),
      periodEnd: DateTime(2026, 9, 30),
      card: card,
    );
    expect(result.card?.usedLimit.value, 140);
    expect(result.card?.availableLimit.value, 0);
  });

  test(
    'B20 B21 zero and suppressed values are distinct and calculator has no global scope',
    () {
      const suppressed = FinancialMetricValue.suppressed('not applicable');
      final result = calculator.calculate(
        facts: _facts(const []),
        periodStart: DateTime(2026, 9, 1),
        periodEnd: DateTime(2026, 9, 30),
      );
      expect(result.realizedExpense.value, 0);
      expect(result.realizedExpense.isAvailable, isTrue);
      expect(suppressed.isAvailable, isFalse);
      expect(suppressed.value, isNull);
    },
  );
  test(
    'commitment outflow inflow empty and outside horizon stay separated',
    () {
      FinancialFactNormalizationResult withCommitment(
        FinancialCommitmentDirection direction,
        DateTime dueAt,
      ) => _facts([
        _fact(
          commitment: FinancialKnownCommitment(
            kind: FinancialCommitmentKind.pending,
            direction: direction,
            amount: 25,
            dueAt: dueAt,
          ),
        ),
      ]);
      final out = calculator.calculate(
        facts: withCommitment(
          FinancialCommitmentDirection.outflow,
          DateTime(2026, 9, 10),
        ),
        periodStart: DateTime(2026, 9, 1),
        periodEnd: DateTime(2026, 9, 30),
      );
      final incoming = calculator.calculate(
        facts: withCommitment(
          FinancialCommitmentDirection.inflow,
          DateTime(2026, 9, 10),
        ),
        periodStart: DateTime(2026, 9, 1),
        periodEnd: DateTime(2026, 9, 30),
      );
      final empty = calculator.calculate(
        facts: _facts(const []),
        periodStart: DateTime(2026, 9, 1),
        periodEnd: DateTime(2026, 9, 30),
      );
      final outside = calculator.calculate(
        facts: withCommitment(
          FinancialCommitmentDirection.outflow,
          DateTime(2026, 10, 1),
        ),
        periodStart: DateTime(2026, 9, 1),
        periodEnd: DateTime(2026, 9, 30),
      );
      expect(
        [
          out.commitmentOutflow.value,
          out.commitmentInflow.value,
          out.commitmentNet.value,
        ],
        [25, 0, -25],
      );
      expect(
        [
          incoming.commitmentOutflow.value,
          incoming.commitmentInflow.value,
          incoming.commitmentNet.value,
        ],
        [0, 25, 25],
      );
      expect(
        [
          empty.commitmentOutflow.value,
          empty.commitmentInflow.value,
          empty.commitmentNet.value,
        ],
        [0, 0, 0],
      );
      expect(outside.commitmentOutflow.value, 0);
    },
  );
}

CreditCardInvoiceModel _invoice(
  String id,
  DateTime dueDate, {
  bool paid = false,
}) {
  return CreditCardInvoiceModel(
    id: id,
    cardId: 'card',
    ownerMemberId: 'member',
    referenceYear: dueDate.year,
    referenceMonth: dueDate.month,
    closingDate: dueDate.subtract(const Duration(days: 10)),
    dueDate: dueDate,
    total: 100,
    status: paid
        ? CreditCardInvoiceModel.paidStatus
        : CreditCardInvoiceModel.openStatus,
    paidAt: paid ? dueDate : null,
    createdAt: dueDate,
    updatedAt: dueDate,
  );
}
