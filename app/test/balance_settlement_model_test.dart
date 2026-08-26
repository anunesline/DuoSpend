import 'package:app/features/transactions/data/models/balance_settlement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 8, 25, 10);

  BalanceSettlementModel pendingSettlement() {
    return BalanceSettlementModel(
      id: 'settlement-1',
      walletId: 'shared-wallet',
      fromMemberId: 'matheus',
      toMemberId: 'aline',
      amount: 150,
      createdAt: createdAt,
    );
  }

  test('mantém histórico e saldo ao declarar e confirmar um acerto', () {
    final declared = pendingSettlement().declarePayment(
      declaredByMemberId: 'matheus',
      declaredAt: createdAt.add(const Duration(hours: 1)),
      payerWalletId: 'matheus-wallet',
    );
    final settled = declared.confirmReceipt(
      confirmedByMemberId: 'aline',
      confirmedAt: createdAt.add(const Duration(hours: 2)),
      transactionId: 'settlement-transaction',
      receiverWalletId: 'aline-wallet',
    );

    expect(declared.isAwaitingConfirmation, isTrue);
    expect(declared.hasPaymentDeclaration, isTrue);
    expect(settled.isSettled, isTrue);
    expect(settled.hasReceiptConfirmation, isTrue);
    expect(settled.settlementTransactionId, 'settlement-transaction');
    expect(settled.amount, 150);
    expect(settled.fromMemberId, 'matheus');
    expect(settled.toMemberId, 'aline');
  });

  test('bloqueia declaração e confirmação duplicadas do mesmo acerto', () {
    final declared = pendingSettlement().declarePayment(
      declaredByMemberId: 'matheus',
      declaredAt: createdAt.add(const Duration(hours: 1)),
      payerWalletId: 'matheus-wallet',
    );

    expect(
      () => declared.declarePayment(
        declaredByMemberId: 'matheus',
        declaredAt: createdAt.add(const Duration(hours: 1)),
        payerWalletId: 'matheus-wallet',
      ),
      throwsStateError,
    );

    final settled = declared.confirmReceipt(
      confirmedByMemberId: 'aline',
      confirmedAt: createdAt.add(const Duration(hours: 2)),
      transactionId: 'settlement-transaction',
      receiverWalletId: 'aline-wallet',
    );

    expect(
      () => settled.confirmReceipt(
        confirmedByMemberId: 'aline',
        confirmedAt: createdAt.add(const Duration(hours: 2)),
        transactionId: 'second-transaction',
        receiverWalletId: 'aline-wallet',
      ),
      throwsStateError,
    );
  });

  test('só permite o devedor declarar e o credor confirmar', () {
    expect(
      () => pendingSettlement().declarePayment(
        declaredByMemberId: 'aline',
        declaredAt: createdAt,
        payerWalletId: 'aline-wallet',
      ),
      throwsStateError,
    );

    final declared = pendingSettlement().declarePayment(
      declaredByMemberId: 'matheus',
      declaredAt: createdAt,
      payerWalletId: 'matheus-wallet',
    );

    expect(
      () => declared.confirmReceipt(
        confirmedByMemberId: 'matheus',
        confirmedAt: createdAt,
        transactionId: 'settlement-transaction',
        receiverWalletId: 'aline-wallet',
      ),
      throwsStateError,
    );
  });
}
