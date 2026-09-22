import 'package:app/features/financial_intelligence/domain/facts/financial_facts.dart';
import 'package:app/features/financial_intelligence/domain/services/financial_fact_normalizer.dart';
import 'package:app/features/finances/data/financial_accounts_repository.dart';
import 'package:app/features/home/data/models/credit_card_invoice_model.dart';
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/transactions/data/models/balance_settlement_model.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/transactions/domain/models/shared_transaction_confirmation_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const normalizer = FinancialFactNormalizer();
  final reference = DateTime(2026, 8, 15);

  final solo = WalletModel(
    id: 'solo',
    name: 'Conta pessoal',
    balance: 1000,
    ownerId: 'aline',
    memberIds: const ['aline'],
  );
  final shared = WalletModel(
    id: 'shared',
    name: 'Nós',
    balance: 1000,
    type: WalletType.shared,
    ownerId: 'aline',
    memberIds: const ['aline', 'matheus'],
  );

  TransactionModel transaction({
    String id = 'transaction',
    String walletId = 'solo',
    String type = 'expense',
    double value = 100,
    DateTime? date,
    String financialStatus = 'settled',
    DateTime? financialSettledAt,
    String? paymentMethod,
    bool isSettlement = false,
    bool isInstallment = false,
    int? installmentNumber,
    String? installmentGroupId,
    bool isRecurring = false,
    String? recurringFrequency,
    DateTime? recurringStartDate,
    String category = 'Casa',
    String purchaseFor = 'self',
    String splitType = 'none',
    Map<String, double> memberShares = const {},
    SharedTransactionConfirmationStatus confirmationStatus =
        SharedTransactionConfirmationStatus.accepted,
    String paidBy = 'aline',
  }) => TransactionModel(
    id: id,
    description: id,
    value: value,
    type: type,
    date: date ?? DateTime(2026, 8, 10),
    walletId: walletId,
    category: category,
    subcategory: 'Geral',
    paidByMemberId: paidBy,
    financialStatus: financialStatus,
    financialSettledAt: financialSettledAt,
    paymentMethod: paymentMethod,
    isSettlement: isSettlement,
    isInstallment: isInstallment,
    installmentCount: isInstallment ? 6 : null,
    installmentNumber: installmentNumber,
    installmentGroupId: installmentGroupId,
    isRecurring: isRecurring,
    recurringId: isRecurring ? 'recurring-$id' : null,
    recurringFrequency: recurringFrequency,
    recurringStartDate: recurringStartDate,
    purchaseFor: purchaseFor,
    splitType: splitType,
    memberShares: memberShares,
    confirmationStatus: confirmationStatus,
  );

  FinancialFactNormalizationResult normalize({
    WalletModel? wallet,
    List<TransactionModel> transactions = const [],
    List<FinancialCardInvoiceSource> invoices = const [],
    List<AccountTransfer> transfers = const [],
    List<BalanceSettlementModel> settlements = const [],
    DateTime? referenceAt,
    DateTime? until,
  }) => normalizer.normalize(
    FinancialFactNormalizationInput(
      wallet: wallet ?? solo,
      referenceAt: referenceAt ?? reference,
      commitmentRangeEnd: until ?? DateTime(2026, 9, 30),
      transactions: transactions,
      invoices: invoices,
      transfers: transfers,
      settlements: settlements,
    ),
  );

  CreditCardInvoiceModel invoice({
    String id = '2026-08',
    String cardId = 'card',
    double total = 100,
    String status = CreditCardInvoiceModel.openStatus,
    DateTime? paidAt,
    String? paymentWalletId,
  }) => CreditCardInvoiceModel(
    id: id,
    cardId: cardId,
    ownerMemberId: 'aline',
    referenceYear: 2026,
    referenceMonth: 8,
    closingDate: DateTime(2026, 8, 10),
    dueDate: DateTime(2026, 8, 25),
    total: total,
    status: status,
    paidAt: paidAt,
    paymentWalletId: paymentWalletId,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  test('1. despesa liquidada gera fato econômico e saída de caixa', () {
    final result = normalize(
      transactions: [transaction(financialSettledAt: DateTime(2026, 8, 11))],
    );
    final fact = result.facts.single;
    expect(fact.economic?.nature, FinancialEconomicNature.expense);
    expect(fact.economic?.occurredAt, DateTime(2026, 8, 10));
    expect(fact.cash?.nature, FinancialCashNature.outflow);
    expect(fact.cash?.occurredAt, DateTime(2026, 8, 11));
  });

  test('2. receita liquidada gera fato econômico e entrada de caixa', () {
    final fact = normalize(
      transactions: [transaction(type: 'income', value: 1000)],
    ).facts.single;
    expect(fact.economic?.nature, FinancialEconomicNature.income);
    expect(fact.cash?.nature, FinancialCashNature.inflow);
  });

  test('3. despesa pending é compromisso, não gasto realizado nem caixa', () {
    final fact = normalize(
      transactions: [transaction(financialStatus: 'pending')],
    ).facts.single;
    expect(fact.economic, isNull);
    expect(fact.cash, isNull);
    expect(fact.commitment?.kind, FinancialCommitmentKind.pending);
    expect(fact.commitment?.direction, FinancialCommitmentDirection.outflow);
  });

  test('4. receita pending é entrada conhecida, não receita realizada', () {
    final fact = normalize(
      transactions: [transaction(type: 'income', financialStatus: 'pending')],
    ).facts.single;
    expect(fact.economic, isNull);
    expect(fact.cash, isNull);
    expect(fact.commitment?.kind, FinancialCommitmentKind.pending);
    expect(fact.commitment?.direction, FinancialCommitmentDirection.inflow);
  });

  test('5. compra no cartão é econômica e não reduz caixa', () {
    final fact = normalize(
      transactions: [
        transaction(financialStatus: 'invoice', paymentMethod: 'creditCard'),
      ],
    ).facts.single;
    expect(fact.economic?.nature, FinancialEconomicNature.expense);
    expect(fact.cash, isNull);
    expect(
      fact.cashSuppressionReason,
      FinancialFactSuppressionReason.invoicePurchaseHasNoImmediateCashEffect,
    );
  });

  test('6. fatura aberta é somente compromisso conhecido', () {
    final fact = normalize(
      invoices: [
        FinancialCardInvoiceSource(invoice: invoice(), walletId: solo.id),
      ],
    ).facts.single;
    expect(fact.economic, isNull);
    expect(fact.cash, isNull);
    expect(fact.commitment?.kind, FinancialCommitmentKind.creditCardInvoice);
    expect(fact.commitment?.direction, FinancialCommitmentDirection.outflow);
    expect(fact.commitment?.dueAt, DateTime(2026, 8, 25));
    expect(fact.source.invoiceReferenceYear, 2026);
    expect(fact.source.invoiceReferenceMonth, 8);
    expect(fact.source.invoiceClosingDate, DateTime(2026, 8, 10));
    expect(fact.source.invoiceDueDate, DateTime(2026, 8, 25));
  });

  test(
    '7. pagamento de fatura cria caixa, nunca segunda despesa econômica',
    () {
      final result = normalize(
        transactions: [
          transaction(
            id: 'credit-purchase',
            financialStatus: 'invoice',
            paymentMethod: 'creditCard',
          ),
        ],
        invoices: [
          FinancialCardInvoiceSource(
            invoice: invoice(
              status: CreditCardInvoiceModel.paidStatus,
              paidAt: DateTime(2026, 8, 12),
              paymentWalletId: solo.id,
            ),
            walletId: solo.id,
          ),
        ],
      );
      expect(result.economicFacts, hasLength(1));
      expect(result.economicFacts.single.amount, 100);
      expect(result.cashFacts, hasLength(1));
      expect(
        result.cashFacts.single.nature,
        FinancialCashNature.invoicePaymentOut,
      );
    },
  );

  test('8. transferência não cria receita nem despesa econômica', () {
    final result = normalize(
      transfers: [
        AccountTransfer(
          id: 'transfer',
          fromId: solo.id,
          toId: 'other',
          fromName: 'A',
          toName: 'B',
          amount: 500,
          date: DateTime(2026, 8, 10),
        ),
      ],
    );
    expect(result.economicFacts, isEmpty);
    expect(
      result.cashFacts.single.nature,
      FinancialCashNature.internalTransferOut,
    );
    expect(result.facts.single.commitment, isNull);
  });

  test('9. settlement só produz caixa pelo settlement confirmado', () {
    final result = normalize(
      transactions: [transaction(id: 'settlement-tx', isSettlement: true)],
      settlements: [
        BalanceSettlementModel(
          id: 'settlement',
          walletId: shared.id,
          fromMemberId: 'aline',
          toMemberId: 'matheus',
          amount: 50,
          payerWalletId: solo.id,
          receiverWalletId: 'partner-wallet',
          createdAt: DateTime(2026, 8, 1),
          settledAt: DateTime(2026, 8, 12),
          status: BalanceSettlementModel.settledStatus,
        ),
      ],
    );
    expect(result.economicFacts, isEmpty);
    expect(result.cashFacts.single.nature, FinancialCashNature.settlementOut);
  });

  test('10. split 50/50 atribui shares sem duplicar despesa econômica', () {
    final fact = normalize(
      wallet: shared,
      transactions: [
        transaction(
          walletId: shared.id,
          value: 100,
          purchaseFor: 'both',
          splitType: 'equal',
          memberShares: const {'aline': 50, 'matheus': 50},
        ),
      ],
    ).facts.single;
    expect(fact.economic?.amount, 100);
    expect(fact.responsibilities.map((share) => share.amount), [50, 50]);
    expect(
      fact.responsibilities.fold<double>(0, (sum, item) => sum + item.amount),
      100,
    );
  });

  test('11. split customizado mantém a responsabilidade informada', () {
    final fact = normalize(
      wallet: shared,
      transactions: [
        transaction(
          walletId: shared.id,
          value: 100,
          purchaseFor: 'both',
          splitType: 'custom',
          memberShares: const {'aline': 30, 'matheus': 70},
        ),
      ],
    ).facts.single;
    expect(fact.responsibilities[0].amount, 30);
    expect(fact.responsibilities[1].amount, 70);
  });

  test('12. pagador diferente da responsabilidade permanece separado', () {
    final fact = normalize(
      wallet: shared,
      transactions: [
        transaction(
          walletId: shared.id,
          paidBy: 'aline',
          value: 100,
          purchaseFor: 'both',
          splitType: 'custom',
          memberShares: const {'aline': 20, 'matheus': 80},
        ),
      ],
    ).facts.single;
    expect(fact.source.paidByMemberId, 'aline');
    expect(fact.responsibilities[0].amount, 20);
    expect(fact.responsibilities[1].amount, 80);
  });

  test('13. purchaseFor both não vira responsabilidade sem split', () {
    final fact = normalize(
      wallet: shared,
      transactions: [transaction(walletId: shared.id, purchaseFor: 'both')],
    ).facts.single;
    expect(fact.source.purchaseFor, 'both');
    expect(fact.responsibilities, isEmpty);
  });

  test('14. parcela atual é gasto econômico pela própria parcela', () {
    final fact = normalize(
      transactions: [
        transaction(
          financialStatus: 'invoice',
          paymentMethod: 'creditCard',
          isInstallment: true,
          installmentNumber: 1,
          installmentGroupId: 'group',
        ),
      ],
    ).facts.single;
    expect(fact.economic?.amount, 100);
    expect(fact.commitment, isNull);
    expect(fact.source.installmentGroupId, 'group');
    expect(fact.source.installmentNumber, 1);
    expect(fact.source.installmentCount, 6);
  });

  test('15. parcela futura é compromisso e nunca gasto antecipado', () {
    final fact = normalize(
      transactions: [
        transaction(
          date: DateTime(2026, 9, 10),
          financialStatus: 'invoice',
          paymentMethod: 'creditCard',
          isInstallment: true,
          installmentNumber: 2,
          installmentGroupId: 'group',
        ),
      ],
    ).facts.single;
    expect(fact.economic, isNull);
    expect(fact.commitment?.kind, FinancialCommitmentKind.installment);
    expect(fact.commitment?.direction, FinancialCommitmentDirection.outflow);
  });

  test('parcelas-filhas evoluem de janeiro a março pelo estado recebido', () {
    final installments = [
      transaction(
        id: 'installment-1',
        date: DateTime(2026, 1, 10),
        financialStatus: 'invoice',
        paymentMethod: 'creditCard',
        isInstallment: true,
        installmentNumber: 1,
        installmentGroupId: 'purchase-600',
      ),
      transaction(
        id: 'installment-2',
        date: DateTime(2026, 2, 10),
        financialStatus: 'invoice',
        paymentMethod: 'creditCard',
        isInstallment: true,
        installmentNumber: 2,
        installmentGroupId: 'purchase-600',
      ),
      transaction(
        id: 'installment-3',
        date: DateTime(2026, 3, 10),
        financialStatus: 'pending',
        isInstallment: true,
        installmentNumber: 3,
        installmentGroupId: 'purchase-600',
      ),
    ];

    FinancialFactBundle factAt(DateTime referenceAt, String id) => normalize(
      transactions: installments,
      referenceAt: referenceAt,
      until: DateTime(2026, 6, 30),
    ).facts.singleWhere((fact) => fact.source.id == id);

    final januaryCurrent = factAt(DateTime(2026, 1, 31), 'installment-1');
    final januaryFuture = factAt(DateTime(2026, 1, 31), 'installment-2');
    expect(januaryCurrent.economic?.amount, 100);
    expect(januaryCurrent.cash, isNull);
    expect(januaryFuture.economic, isNull);
    expect(januaryFuture.commitment?.kind, FinancialCommitmentKind.installment);

    final februaryCurrent = factAt(DateTime(2026, 2, 28), 'installment-2');
    final februaryFuture = factAt(DateTime(2026, 2, 28), 'installment-3');
    expect(februaryCurrent.economic?.amount, 100);
    expect(februaryCurrent.cash, isNull);
    expect(februaryFuture.economic, isNull);
    expect(
      februaryFuture.commitment?.kind,
      FinancialCommitmentKind.installment,
    );

    final marchCurrent = factAt(DateTime(2026, 3, 31), 'installment-3');
    expect(marchCurrent.economic, isNull);
    expect(marchCurrent.cash, isNull);
    expect(marchCurrent.commitment?.kind, FinancialCommitmentKind.pending);
  });

  test('parcela atual pending é somente compromisso pending', () {
    final fact = normalize(
      transactions: [
        transaction(
          financialStatus: 'pending',
          isInstallment: true,
          installmentNumber: 2,
          installmentGroupId: 'group',
        ),
      ],
    ).facts.single;
    expect(fact.economic, isNull);
    expect(fact.cash, isNull);
    expect(fact.commitment?.kind, FinancialCommitmentKind.pending);
    expect(fact.commitment?.direction, FinancialCommitmentDirection.outflow);
  });

  test('competência da parcela independe de liquidação de caixa futura', () {
    final fact = normalize(
      transactions: [
        transaction(
          date: DateTime(2026, 8, 10),
          financialStatus: 'settled',
          financialSettledAt: DateTime(2026, 8, 20),
          isInstallment: true,
          installmentNumber: 1,
          installmentGroupId: 'group',
        ),
      ],
    ).facts.single;
    expect(fact.economic?.occurredAt, DateTime(2026, 8, 10));
    expect(fact.cash, isNull);
    expect(
      fact.cashSuppressionReason,
      FinancialFactSuppressionReason.futureDatedSettlement,
    );
  });

  test('parcela fora do horizonte não produz compromisso installment', () {
    final result = normalize(
      until: DateTime(2026, 9, 30),
      transactions: [
        transaction(
          id: 'within-horizon',
          date: DateTime(2026, 9, 10),
          financialStatus: 'invoice',
          isInstallment: true,
          installmentNumber: 2,
          installmentGroupId: 'group',
        ),
        transaction(
          id: 'outside-horizon',
          date: DateTime(2026, 10, 10),
          financialStatus: 'invoice',
          isInstallment: true,
          installmentNumber: 3,
          installmentGroupId: 'group',
        ),
      ],
    );
    final within = result.facts.singleWhere(
      (fact) => fact.source.id == 'within-horizon',
    );
    final outside = result.facts.singleWhere(
      (fact) => fact.source.id == 'outside-horizon',
    );
    expect(within.economic, isNull);
    expect(within.commitment?.kind, FinancialCommitmentKind.installment);
    expect(outside.economic, isNull);
    expect(outside.commitment, isNull);
    expect(
      outside.commitmentSuppressionReason,
      FinancialFactSuppressionReason.installmentOutsideCommitmentHorizon,
    );
  });

  test('16. ocorrência recorrente realizada é fato normal', () {
    final fact = normalize(
      transactions: [
        transaction(
          isRecurring: true,
          recurringFrequency: 'monthly',
          recurringStartDate: DateTime(2026, 8, 1),
          date: DateTime(2026, 8, 1),
        ),
      ],
    ).facts.first;
    expect(fact.economic?.nature, FinancialEconomicNature.expense);
    expect(fact.cash?.nature, FinancialCashNature.outflow);
    expect(fact.source.recurringId, 'recurring-transaction');
  });

  test('17. ocorrência recorrente futura é compromisso virtual', () {
    final result = normalize(
      transactions: [
        transaction(
          isRecurring: true,
          recurringFrequency: 'monthly',
          recurringStartDate: DateTime(2026, 8, 1),
          date: DateTime(2026, 8, 1),
        ),
      ],
    );
    final virtual = result.facts.firstWhere(
      (fact) => fact.source.kind == FinancialFactSourceKind.recurringOccurrence,
    );
    expect(virtual.economic, isNull);
    expect(virtual.commitment?.kind, FinancialCommitmentKind.recurring);
    expect(virtual.commitment?.direction, FinancialCommitmentDirection.outflow);
    expect(virtual.commitment?.dueAt, DateTime(2026, 9, 1));
  });

  test('18. categoria legada é canonicalizada para análise', () {
    final fact = normalize(
      transactions: [transaction(category: 'Casa')],
    ).facts.single;
    expect(fact.source.category, 'Moradia');
  });

  test('19. reembolso sem vínculo é receita independente', () {
    final result = normalize(
      transactions: [
        transaction(id: 'expense', value: 100),
        transaction(
          id: 'refund',
          type: 'income',
          value: 30,
          category: 'Receita',
        ),
      ],
    );
    expect(result.economicFacts.map((fact) => fact.amount).toList(), [100, 30]);
    expect(result.economicFacts.map((fact) => fact.nature).toList(), [
      FinancialEconomicNature.expense,
      FinancialEconomicNature.income,
    ]);
  });

  test('20. dado legado ambíguo é suprimido em vez de inferido', () {
    final fact = normalize(
      transactions: [transaction(type: 'transfer')],
    ).facts.single;
    expect(fact.economic, isNull);
    expect(fact.cash, isNull);
    expect(fact.commitment, isNull);
    expect(
      fact.economicSuppressionReason,
      FinancialFactSuppressionReason.invalidSource,
    );
  });

  test('responsabilidade pendente não alimenta atribuição definitiva', () {
    final fact = normalize(
      wallet: shared,
      transactions: [
        transaction(
          walletId: shared.id,
          purchaseFor: 'both',
          splitType: 'equal',
          memberShares: const {'aline': 50, 'matheus': 50},
          confirmationStatus: SharedTransactionConfirmationStatus.pending,
        ),
      ],
    ).facts.single;
    expect(fact.responsibilities, isEmpty);
    expect(
      fact.responsibilitySuppressionReason,
      FinancialFactSuppressionReason.unconfirmedSharedResponsibility,
    );
  });

  test('escopo estrangeiro é suprimido e não agrega carteiras', () {
    final result = normalize(
      transactions: [transaction(walletId: 'another-wallet')],
    );
    expect(result.facts, isEmpty);
    expect(
      result.suppressedSources.single.reason,
      FinancialFactSuppressionReason.foreignWalletSource,
    );
  });
}
