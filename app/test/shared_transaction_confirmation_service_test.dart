import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/transactions/domain/financial_split/financial_split_service.dart';
import 'package:app/features/transactions/domain/models/shared_transaction_confirmation_status.dart';
import 'package:app/features/transactions/domain/services/shared_transaction_confirmation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = SharedTransactionConfirmationService();

  final soloWallet = WalletModel(
    id: 'solo',
    name: 'Pessoal',
    balance: 0,
    ownerId: 'aline',
    memberIds: const ['aline'],
  );
  final sharedWallet = WalletModel(
    id: 'shared',
    name: 'Casa',
    balance: 0,
    type: WalletType.shared,
    ownerId: 'aline',
    memberIds: const ['aline', 'matheus'],
  );

  test('não pede confirmação para despesa individual', () {
    final decision = service.resolve(
      wallet: soloWallet,
      transactionType: 'expense',
      hasFinancialSplit: true,
      isSettlement: false,
    );

    expect(
      decision.status,
      SharedTransactionConfirmationStatus.accepted,
    );
    expect(decision.requestedAt, isNull);
    expect(decision.shouldSynchronizeSettlement, isTrue);
  });

  test('pede confirmação para despesa compartilhada dividida', () {
    final decision = service.resolve(
      wallet: sharedWallet,
      transactionType: 'expense',
      hasFinancialSplit: true,
      isSettlement: false,
    );

    expect(
      decision.status,
      SharedTransactionConfirmationStatus.pending,
    );
    expect(decision.requestedAt, isNotNull);
    expect(decision.requiresPartnerConfirmation, isTrue);
    expect(decision.shouldSynchronizeSettlement, isFalse);
  });

  test('não pede confirmação para receita, sem split ou acerto', () {
    for (final scenario in [
      (transactionType: 'income', hasSplit: true, isSettlement: false),
      (transactionType: 'expense', hasSplit: false, isSettlement: false),
      (transactionType: 'expense', hasSplit: true, isSettlement: true),
    ]) {
      final decision = service.resolve(
        wallet: sharedWallet,
        transactionType: scenario.transactionType,
        hasFinancialSplit: scenario.hasSplit,
        isSettlement: scenario.isSettlement,
      );

      expect(
        decision.status,
        SharedTransactionConfirmationStatus.accepted,
      );
    }
  });

  test('divisão 50/50 mantém os centavos no total da compra', () {
    final shares = const FinancialSplitService().calculateAutomaticSplit(
      value: 99.99,
      payerMemberId: 'aline',
      partnerMemberId: 'matheus',
      purchaseFor: 'both',
    );

    expect(shares.memberShares['aline'], 50.0);
    expect(shares.memberShares['matheus'], 49.99);
    expect(shares.totalValue, 99.99);
  });
}
