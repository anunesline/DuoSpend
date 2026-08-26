import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/budgets/data/repositories/budget_repository.dart';
import 'package:app/features/financial_intelligence/presentation/controllers/insights_controller.dart';
import 'package:app/features/goals/data/repositories/savings_goal_repository.dart';
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/home/data/repositories/credit_card_repository.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/transactions/data/repositories/transaction_repository.dart';

void main() {
  MockFirebaseAuth auth() => MockFirebaseAuth(
        mockUser: MockUser(uid: 'matheus'),
        signedIn: true,
      );

  final sharedWallet = WalletModel(
    id: 'shared-wallet',
    name: 'Casa',
    balance: 1000,
    type: WalletType.shared,
    ownerId: 'aline',
    memberIds: const ['aline', 'matheus'],
  );

  TransactionModel expense({
    required String id,
    required String walletId,
    required double value,
  }) {
    return TransactionModel(
      id: id,
      description: id,
      value: value,
      type: 'expense',
      date: DateTime(2026, 8, 26),
      walletId: walletId,
      financialStatus: 'pending',
      category: 'Outros',
      subcategory: 'Geral',
    );
  }

  test('Insights da carteira compartilhada não usa transações solo', () async {
    final firestore = FakeFirebaseFirestore();
    final transactionRepository = TransactionRepository(
      firestore: firestore,
      auth: auth(),
    );
    await transactionRepository.addTransaction(
      expense(id: 'shared-expense', walletId: sharedWallet.id, value: 100),
      wallet: sharedWallet,
    );
    await transactionRepository.addTransaction(
      expense(id: 'solo-expense', walletId: 'solo-wallet', value: 600),
    );

    final controller = InsightsController(
      wallet: sharedWallet,
      transactionRepository: transactionRepository,
      budgetRepository: BudgetRepository(firestore: firestore, auth: auth()),
      goalRepository: SavingsGoalRepository(firestore: firestore, auth: auth()),
      creditCardRepository: CreditCardRepository(
        firestore: firestore,
        auth: auth(),
      ),
    );

    await controller.load(now: DateTime(2026, 8, 25));

    final projection = controller.insights.firstWhere(
      (insight) => insight.id == 'projected-balance',
    );
    expect(controller.errorMessage, isNull);
    expect(projection.amount, 900);
  });
}
