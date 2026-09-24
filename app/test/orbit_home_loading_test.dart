import 'dart:async';

import 'package:app/core/context/wallet_context.dart';
import 'package:app/features/auth/data/repositories/user_repository.dart';
import 'package:app/features/budgets/data/repositories/budget_repository.dart';
import 'package:app/features/budgets/domain/models/budget.dart';
import 'package:app/features/goals/data/repositories/savings_goal_repository.dart';
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/home/data/repositories/credit_card_repository.dart';
import 'package:app/features/home/data/repositories/partner_invite_repository.dart';
import 'package:app/features/home/data/repositories/wallet_repository.dart';
import 'package:app/features/home/domain/models/orbit_home_overview.dart';
import 'package:app/features/home/presentation/controllers/home_controller.dart';
import 'package:app/features/home/presentation/controllers/orbit_dashboard_controller.dart';
import 'package:app/features/household_routines/data/repositories/firestore_household_task_repository.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/transactions/data/repositories/balance_settlement_repository.dart';
import 'package:app/features/transactions/data/repositories/transaction_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/orbit_home_fixture.dart';

class _DelayedBudgets extends BudgetRepository {
  final Map<String, Completer<List<Budget>>> pending = {};
  _DelayedBudgets(FakeFirebaseFirestore db, MockFirebaseAuth auth)
    : super(firestore: db, auth: auth);
  @override
  Future<List<Budget>> getByWallet({required WalletModel wallet}) =>
      (pending[wallet.id] = Completer<List<Budget>>()).future;
}

class _DelayedTransactions extends TransactionRepository {
  final Map<String, Completer<List<TransactionModel>>> pending = {};
  _DelayedTransactions(FakeFirebaseFirestore db, MockFirebaseAuth auth)
    : super(firestore: db, auth: auth);
  @override
  Future<List<TransactionModel>> getTransactionsByWallet(
    String walletId, {
    WalletModel? wallet,
  }) => (pending[walletId] = Completer<List<TransactionModel>>()).future;
}

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  setUp(() async {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'one', displayName: 'Pessoa Um'),
      signedIn: true,
    );
    for (final wallet in [homeWallet(), homeWallet(shared: true)]) {
      await db.collection('wallets').doc(wallet.id).set(wallet.toMap());
    }
  });

  OrbitDashboardController dashboard({BudgetRepository? budgets}) =>
      OrbitDashboardController(
        budgetRepository:
            budgets ?? BudgetRepository(firestore: db, auth: auth),
        goalRepository: SavingsGoalRepository(firestore: db, auth: auth),
        creditCardRepository: CreditCardRepository(firestore: db, auth: auth),
        settlementRepository: BalanceSettlementRepository(
          firestore: db,
          auth: auth,
        ),
        userRepository: UserRepository(firestore: db),
        taskRepository: FirestoreHouseholdTaskRepository(firestore: db),
      );

  test(
    'rapid Solo/Nós switch ignores the older summary after it finishes',
    () async {
      final delayed = _DelayedBudgets(db, auth);
      final controller = dashboard(budgets: delayed);
      addTearDown(controller.dispose);
      final first = controller.load(
        wallet: homeWallet(),
        transactions: [homeTransaction(walletId: 'solo', value: 9000)],
        currentUserId: 'one',
        now: homeReference,
      );
      expect(controller.overview, isNull);
      final second = controller.load(
        wallet: homeWallet(shared: true),
        transactions: [homeTransaction(value: 100)],
        currentUserId: 'one',
        now: homeReference,
      );
      delayed.pending['shared']!.complete([]);
      await second;
      expect(controller.overview!.wallet.id, 'shared');
      expect(controller.overview!.monthReport.totalExpense, 100);
      delayed.pending['solo']!.complete([]);
      await first;
      expect(controller.overview!.wallet.id, 'shared');
      expect(controller.overview!.monthReport.totalExpense, 100);
      expect(controller.isLoading, isFalse);
    },
  );

  test(
    'clear invalidates an in-flight summary while new transactions load',
    () async {
      final delayed = _DelayedBudgets(db, auth);
      final controller = dashboard(budgets: delayed);
      addTearDown(controller.dispose);
      final request = controller.load(
        wallet: homeWallet(),
        transactions: [],
        currentUserId: 'one',
      );
      controller.clear();
      delayed.pending['solo']!.complete([]);
      await request;
      expect(controller.overview, isNull);
      expect(controller.isLoading, isFalse);
    },
  );

  test(
    'one failed section does not become a fabricated zero or erase other sections',
    () async {
      final delayed = _DelayedBudgets(db, auth);
      final controller = dashboard(budgets: delayed);
      addTearDown(controller.dispose);
      final request = controller.load(
        wallet: homeWallet(),
        transactions: [homeTransaction(walletId: 'solo', value: 40)],
        currentUserId: 'one',
        now: homeReference,
      );
      delayed.pending['solo']!.completeError(StateError('Offline budgets'));
      await request;
      expect(controller.overview!.errors, contains(OrbitHomeSection.budget));
      expect(controller.overview!.summary.budget, isNull);
      expect(controller.overview!.monthReport.totalExpense, 40);
      expect(controller.overview!.projection, isNotNull);
      expect(controller.errorMessage, isNull);
    },
  );

  test(
    'disposing during a read never publishes to a disposed notifier',
    () async {
      final delayed = _DelayedBudgets(db, auth);
      final controller = dashboard(budgets: delayed);
      final request = controller.load(
        wallet: homeWallet(),
        transactions: [],
        currentUserId: 'one',
      );
      controller.dispose();
      delayed.pending['solo']!.complete([]);
      await expectLater(request, completes);
      expect(controller.overview, isNull);
    },
  );

  test(
    'Home selection waits for transactions and a late response cannot replace current wallet data',
    () async {
      final context = WalletContext()
        ..initialize(
          wallets: [homeWallet(), homeWallet(shared: true)],
          selectedWallet: homeWallet(),
        );
      final delayed = _DelayedTransactions(db, auth);
      final controller = HomeController(
        auth: auth,
        walletContext: context,
        walletRepository: WalletRepository(firestore: db, auth: auth),
        transactionRepository: delayed,
        partnerInviteRepository: PartnerInviteRepository(
          firestore: db,
          auth: auth,
          userRepository: UserRepository(firestore: db),
        ),
      );
      addTearDown(controller.dispose);
      addTearDown(context.dispose);
      var firstFinished = false;
      final first = controller
          .selectWalletById('shared')
          .then((_) => firstFinished = true);
      expect(controller.isLoadingTransactions, isTrue);
      expect(controller.transactions, isEmpty);
      expect(firstFinished, isFalse);
      final second = controller.selectWalletById('solo');
      delayed.pending['solo']!.complete([
        homeTransaction(walletId: 'solo', value: 25),
      ]);
      await second;
      expect(controller.transactions.single.value, 25);
      expect(controller.wallet!.id, 'solo');
      delayed.pending['shared']!.complete([homeTransaction(value: 999)]);
      await first;
      expect(controller.transactions.single.value, 25);
      expect(controller.isLoadingTransactions, isFalse);
    },
  );
}
