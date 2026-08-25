import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/goals/data/models/savings_goal_model.dart';
import 'package:app/features/goals/data/repositories/savings_goal_repository.dart';
import 'package:app/features/goals/domain/models/savings_goal.dart';
import 'package:app/features/home/data/models/credit_card_model.dart';
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/home/data/repositories/credit_card_repository.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/transactions/data/repositories/transaction_repository.dart';

void main() {
  const userId = 'user-1';

  WalletModel wallet({
    required String id,
    double balance = 1000,
    String ownerId = userId,
  }) {
    return WalletModel(
      id: id,
      name: id,
      balance: balance,
      ownerId: ownerId,
      memberIds: [ownerId],
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
  }

  TransactionModel transaction({
    required String id,
    required String walletId,
    double value = 100,
    String type = 'expense',
    String? paidByMemberId = userId,
    String? paymentMethod = 'pix',
    String? paymentSourceId = 'financial-wallet',
    String financialStatus = 'pending',
  }) {
    return TransactionModel(
      id: id,
      description: id,
      value: value,
      type: type,
      date: DateTime(2026, 8, 10),
      walletId: walletId,
      paidByMemberId: paidByMemberId,
      paymentMethod: paymentMethod,
      paymentSourceId: paymentSourceId,
      financialStatus: financialStatus,
      category: 'Outros',
      subcategory: 'Geral',
    );
  }

  MockFirebaseAuth signedInAuth() {
    return MockFirebaseAuth(
      mockUser: MockUser(uid: userId),
      signedIn: true,
    );
  }

  group('operações financeiras idempotentes', () {
    test('settlement executado duas vezes movimenta o saldo uma vez', () async {
      final firestore = FakeFirebaseFirestore();
      final financialWallet = wallet(id: 'financial-wallet');
      final transactionWallet = wallet(id: 'transaction-wallet');
      final obligation = transaction(
        id: 'obligation-1',
        walletId: transactionWallet.id,
      );

      await firestore
          .collection('wallets')
          .doc(financialWallet.id)
          .set(financialWallet.toMap());
      await firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(obligation.id)
          .set(obligation.toMap());

      final repository = TransactionRepository(
        firestore: firestore,
        auth: signedInAuth(),
      );

      await repository.settleFinancialObligation(
        obligation: obligation,
        transactionWallet: transactionWallet,
        financialWallet: financialWallet,
      );
      final secondResult =
          await repository.settleFinancialObligation(
        obligation: obligation,
        transactionWallet: transactionWallet,
        financialWallet: financialWallet,
      );

      final savedWallet = await firestore
          .collection('wallets')
          .doc(financialWallet.id)
          .get();

      expect(savedWallet.data()!['balance'], 900);
      expect(secondResult.isFinanciallySettled, isTrue);
    });

    test(
      'settlement rejeita carteira persistida que não pertence ao pagador',
      () async {
        final firestore = FakeFirebaseFirestore();
        final selectedWallet = wallet(id: 'other-wallet');
        final transactionWallet = wallet(id: 'transaction-wallet');
        final obligation = transaction(
          id: 'obligation-2',
          walletId: transactionWallet.id,
          paymentSourceId: selectedWallet.id,
        );

        await firestore
            .collection('wallets')
            .doc(selectedWallet.id)
            .set(
              selectedWallet
                  .copyWith(ownerId: 'user-2', memberIds: const ['user-2'])
                  .toMap(),
            );
        await firestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc(obligation.id)
            .set(obligation.toMap());

        final repository = TransactionRepository(
          firestore: firestore,
          auth: signedInAuth(),
        );

        expect(
          repository.settleFinancialObligation(
            obligation: obligation,
            transactionWallet: transactionWallet,
            financialWallet: selectedWallet,
          ),
          throwsStateError,
        );
      },
    );

    test(
      'compra duplicada mantém uma cobrança e não debita a carteira',
      () async {
        final firestore = FakeFirebaseFirestore();
        final cardWallet = wallet(id: 'card-wallet');
        final card = CreditCardModel(
          id: 'card-1',
          ownerMemberId: userId,
          walletId: cardWallet.id,
          name: 'Cartão',
          creditLimit: 2000,
          closingDay: 20,
          dueDay: 10,
        );
        final purchase = transaction(
          id: 'purchase-1',
          walletId: cardWallet.id,
          value: 120,
          paymentMethod: 'creditCard',
          paymentSourceId: card.id,
          financialStatus: 'invoice',
        );

        await firestore
            .collection('wallets')
            .doc(cardWallet.id)
            .set(cardWallet.toMap());
        await firestore
            .collection('creditCards')
            .doc(card.id)
            .set(card.toMap());

        final repository = CreditCardRepository(
          firestore: firestore,
          auth: signedInAuth(),
        );

        final firstInvoice = await repository.registerPurchase(
          cardId: card.id,
          transactionModel: purchase,
          transactionWallet: cardWallet,
        );
        final secondInvoice = await repository.registerPurchase(
          cardId: card.id,
          transactionModel: purchase,
          transactionWallet: cardWallet,
        );

        final savedWallet = await firestore
            .collection('wallets')
            .doc(cardWallet.id)
            .get();
        final savedCard = await firestore
            .collection('creditCards')
            .doc(card.id)
            .get();
        final charges = await firestore
            .collection('creditCards')
            .doc(card.id)
            .collection('charges')
            .get();

        expect(firstInvoice.total, 120);
        expect(secondInvoice.total, 120);
        expect(savedWallet.data()!['balance'], 1000);
        expect(savedCard.data()!['usedLimit'], 120);
        expect(charges.docs, hasLength(1));
      },
    );

    test(
      'pagamento duplicado de fatura debita a carteira uma vez',
      () async {
        final firestore = FakeFirebaseFirestore();
        final cardWallet = wallet(id: 'card-wallet');
        final card = CreditCardModel(
          id: 'card-1',
          ownerMemberId: userId,
          walletId: cardWallet.id,
          name: 'Cartão',
          creditLimit: 2000,
          closingDay: 20,
          dueDay: 10,
        );
        final purchase = transaction(
          id: 'purchase-1',
          walletId: cardWallet.id,
          value: 120,
          paymentMethod: 'creditCard',
          paymentSourceId: card.id,
          financialStatus: 'invoice',
        );

        await firestore
            .collection('wallets')
            .doc(cardWallet.id)
            .set(cardWallet.toMap());
        await firestore
            .collection('creditCards')
            .doc(card.id)
            .set(card.toMap());

        final repository = CreditCardRepository(
          firestore: firestore,
          auth: signedInAuth(),
        );
        final invoice = await repository.registerPurchase(
          cardId: card.id,
          transactionModel: purchase,
          transactionWallet: cardWallet,
        );

        await repository.payInvoice(
          cardId: card.id,
          invoiceId: invoice.id,
          paidAt: DateTime(2026, 8, 15),
        );
        final secondResult = await repository.payInvoice(
          cardId: card.id,
          invoiceId: invoice.id,
          paidAt: DateTime(2026, 8, 16),
        );

        final savedWallet = await firestore
            .collection('wallets')
            .doc(cardWallet.id)
            .get();
        final savedCard = await firestore
            .collection('creditCards')
            .doc(card.id)
            .get();
        final transactions = await firestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .get();

        expect(savedWallet.data()!['balance'], 880);
        expect(savedCard.data()!['usedLimit'], 0);
        expect(secondResult.isPaid, isTrue);
        expect(transactions.docs, hasLength(1));
      },
    );

    test('aporte duplicado usa operationId e debita uma vez', () async {
      final firestore = FakeFirebaseFirestore();
      final sourceWallet = wallet(id: 'goal-wallet');
      final goal = SavingsGoal(
        id: 'goal-1',
        name: 'Reserva',
        targetAmount: 1000,
        walletId: 'context-wallet',
        createdByUserId: userId,
        memberIds: const [userId],
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

      await firestore
          .collection('wallets')
          .doc(sourceWallet.id)
          .set(sourceWallet.toMap());
      await firestore
          .collection('savingsGoals')
          .doc(goal.id)
          .set(SavingsGoalModel.toMap(goal));

      final repository = SavingsGoalRepository(
        firestore: firestore,
        auth: signedInAuth(),
      );

      await repository.contribute(
        goalId: goal.id,
        sourceWallet: sourceWallet,
        amount: 200,
        operationId: 'contribution-1',
      );
      final secondResult = await repository.contribute(
        goalId: goal.id,
        sourceWallet: sourceWallet,
        amount: 200,
        operationId: 'contribution-1',
      );

      final savedWallet = await firestore
          .collection('wallets')
          .doc(sourceWallet.id)
          .get();
      final movements = await firestore
          .collection('savingsGoals')
          .doc(goal.id)
          .collection('movements')
          .get();

      expect(savedWallet.data()!['balance'], 800);
      expect(secondResult.savedAmount, 200);
      expect(movements.docs, hasLength(1));
    });

    test('retirada duplicada usa operationId e credita uma vez', () async {
      final firestore = FakeFirebaseFirestore();
      final destinationWallet = wallet(
        id: 'goal-wallet',
        balance: 800,
      );
      final goal = SavingsGoal(
        id: 'goal-1',
        name: 'Reserva',
        targetAmount: 1000,
        savedAmount: 500,
        walletId: 'context-wallet',
        createdByUserId: userId,
        memberIds: const [userId],
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

      await firestore
          .collection('wallets')
          .doc(destinationWallet.id)
          .set(destinationWallet.toMap());
      await firestore
          .collection('savingsGoals')
          .doc(goal.id)
          .set(SavingsGoalModel.toMap(goal));

      final repository = SavingsGoalRepository(
        firestore: firestore,
        auth: signedInAuth(),
      );

      await repository.withdraw(
        goalId: goal.id,
        destinationWallet: destinationWallet,
        amount: 100,
        operationId: 'withdrawal-1',
      );
      final secondResult = await repository.withdraw(
        goalId: goal.id,
        destinationWallet: destinationWallet,
        amount: 100,
        operationId: 'withdrawal-1',
      );

      final savedWallet = await firestore
          .collection('wallets')
          .doc(destinationWallet.id)
          .get();

      expect(savedWallet.data()!['balance'], 900);
      expect(secondResult.savedAmount, 400);
    });

    test('aporte com saldo insuficiente não movimenta valores', () async {
      final firestore = FakeFirebaseFirestore();
      final sourceWallet = wallet(
        id: 'goal-wallet',
        balance: 50,
      );
      final goal = SavingsGoal(
        id: 'goal-1',
        name: 'Reserva',
        targetAmount: 1000,
        walletId: 'context-wallet',
        createdByUserId: userId,
        memberIds: const [userId],
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

      await firestore
          .collection('wallets')
          .doc(sourceWallet.id)
          .set(sourceWallet.toMap());
      await firestore
          .collection('savingsGoals')
          .doc(goal.id)
          .set(SavingsGoalModel.toMap(goal));

      final repository = SavingsGoalRepository(
        firestore: firestore,
        auth: signedInAuth(),
      );

      expect(
        repository.contribute(
          goalId: goal.id,
          sourceWallet: sourceWallet,
          amount: 100,
          operationId: 'contribution-1',
        ),
        throwsStateError,
      );

      final savedWallet = await firestore
          .collection('wallets')
          .doc(sourceWallet.id)
          .get();
      final savedGoal = await firestore
          .collection('savingsGoals')
          .doc(goal.id)
          .get();

      expect(savedWallet.data()!['balance'], 50);
      expect(savedGoal.data()!['savedAmount'], 0);
    });
  });
}
