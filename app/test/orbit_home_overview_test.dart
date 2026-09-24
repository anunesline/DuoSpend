import 'package:app/features/home/data/models/credit_card_invoice_model.dart';
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/home/domain/models/orbit_home_overview.dart';
import 'package:app/features/home/domain/services/orbit_home_overview_builder.dart';
import 'package:app/features/household_routines/domain/models/household_task.dart';
import 'package:app/features/transactions/data/models/balance_settlement_model.dart';
import 'package:app/features/transactions/domain/models/shared_transaction_confirmation_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/orbit_home_fixture.dart';

void main() {
  const builder = OrbitHomeOverviewBuilder();
  test(
    'shared totals exclude other wallets, rejected and unconfirmed splits',
    () {
      final data = builder.build(
        wallet: homeWallet(shared: true),
        currentUserId: 'one',
        reference: homeReference,
        transactions: [
          homeTransaction(value: 300, split: true),
          homeTransaction(id: 'partner', payer: 'two', value: 200, split: true),
          homeTransaction(id: 'personal', walletId: 'solo', value: 9999),
          homeTransaction(
            id: 'pending',
            value: 800,
            payer: 'two',
            split: true,
            confirmation: SharedTransactionConfirmationStatus.pending,
          ),
          homeTransaction(
            id: 'rejected',
            value: 500,
            split: true,
            confirmation: SharedTransactionConfirmationStatus.rejected,
          ),
        ],
      );
      expect(data.monthReport.totalExpense, 500);
      expect(data.contribution.members.first.amountPaid, 300);
      expect(data.contribution.members.last.amountPaid, 200);
      expect(data.pendingConfirmationCount, 1);
      expect(data.wallet.balance, 2486.32);
    },
  );

  test(
    'projection and next 30 days reuse calendar without double counting card purchases',
    () {
      final now = homeReference;
      final data = builder.build(
        wallet: homeWallet(),
        currentUserId: 'one',
        reference: now,
        transactions: [
          homeTransaction(
            walletId: 'solo',
            value: 80,
            date: now,
            financialStatus: 'invoice',
            paymentMethod: 'creditCard',
          ),
          homeTransaction(
            id: 'income',
            walletId: 'solo',
            value: 1000,
            type: 'income',
            date: DateTime(2026, 9, 25),
            financialStatus: 'pending',
          ),
          homeTransaction(
            id: 'bill',
            walletId: 'solo',
            value: 100,
            date: DateTime(2026, 10, 10),
            financialStatus: 'pending',
          ),
        ],
        invoices: [
          CreditCardInvoiceModel(
            id: 'invoice',
            cardId: 'c',
            ownerMemberId: 'one',
            referenceYear: 2026,
            referenceMonth: 9,
            closingDate: now,
            dueDate: DateTime(2026, 9, 25),
            total: 80,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      expect(data.projection!.projectedBalance, closeTo(3406.32, .001));
      expect(data.commitments, hasLength(2));
      expect(data.committedAmount, 180);
    },
  );

  test('shared view never includes personal invoices', () {
    final data = builder.build(
      wallet: homeWallet(shared: true),
      currentUserId: 'one',
      reference: homeReference,
      transactions: [],
      invoices: [
        CreditCardInvoiceModel(
          id: 'i',
          cardId: 'c',
          ownerMemberId: 'one',
          referenceYear: 2026,
          referenceMonth: 9,
          closingDate: homeReference,
          dueDate: homeReference,
          total: 9999,
          createdAt: homeReference,
          updatedAt: homeReference,
        ),
      ],
    );
    expect(data.commitments, isEmpty);
    expect(data.projection!.projectedBalance, data.wallet.balance);
  });

  test(
    'today includes completed tasks and never reclassifies earlier hours as overdue',
    () {
      final tasks = [
        homeTask('morning', dueAt: DateTime(2026, 9, 20, 7)),
        homeTask('manual', markedOverdueAt: homeReference),
        homeTask('yesterday', dueAt: DateTime(2026, 9, 19, 23)),
        homeTask(
          'completed',
          status: HouseholdTaskStatus.completed,
          completedAt: homeReference,
        ),
        homeTask('cancelled', status: HouseholdTaskStatus.cancelled),
        homeTask('shared', scopeId: 'household:one|two', shared: true),
      ];
      final solo = builder.build(
        wallet: homeWallet(),
        currentUserId: 'one',
        reference: homeReference,
        transactions: [],
        tasks: tasks,
      );
      expect(solo.todayTasks.map((task) => task.id), ['morning', 'completed']);
      expect(solo.overdueTaskCount, 2);
      final shared = builder.build(
        wallet: homeWallet(shared: true),
        currentUserId: 'one',
        reference: homeReference,
        transactions: [],
        tasks: tasks,
      );
      expect(shared.todayTasks.single.id, 'shared');
      expect(shared.overdueTaskCount, 0);
    },
  );

  test(
    'a shared wallet with only its owner does not expose personal routines',
    () {
      final wallet = WalletModel(
        id: 'new-shared',
        name: 'Casa',
        balance: 0,
        type: WalletType.shared,
        ownerId: 'one',
      );
      expect(OrbitHomeOverviewBuilder.taskScope(wallet, 'one'), isNull);
      final data = builder.build(
        wallet: wallet,
        currentUserId: 'one',
        reference: homeReference,
        transactions: [],
        tasks: [homeTask('private')],
      );
      expect(data.todayTasks, isEmpty);
    },
  );

  test(
    'only persisted active settlements in the selected wallet are shown',
    () {
      BalanceSettlementModel item(String id, String wallet, String status) =>
          BalanceSettlementModel(
            id: id,
            walletId: wallet,
            fromMemberId: 'two',
            toMemberId: 'one',
            amount: 10,
            createdAt: homeReference,
            status: status,
          );
      final data = builder.build(
        wallet: homeWallet(shared: true),
        currentUserId: 'one',
        reference: homeReference,
        transactions: [],
        settlements: [
          item('pending', 'shared', 'pending'),
          item('awaiting', 'shared', 'awaiting_confirmation'),
          item('done', 'shared', 'settled'),
          item('other', 'different-household', 'pending'),
        ],
      );
      expect(data.settlements.map((item) => item.id), ['pending', 'awaiting']);
      expect(data.hasPendingItems, isTrue);
    },
  );

  test(
    'failed calendar is unavailable instead of displaying a made-up zero forecast',
    () {
      final data = builder.build(
        wallet: homeWallet(),
        currentUserId: 'one',
        reference: homeReference,
        transactions: [],
        errors: {OrbitHomeSection.calendar: 'Unavailable'},
      );
      expect(data.projection, isNull);
      expect(data.insights, isEmpty);
      expect(data.errors, contains(OrbitHomeSection.calendar));
    },
  );
}
