import 'package:app/features/auth/data/repositories/user_repository.dart';
import 'package:app/features/budgets/domain/models/budget.dart';
import 'package:app/features/budgets/domain/models/budget_consumption.dart';
import 'package:app/features/goals/domain/models/savings_goal.dart';
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/home/domain/models/orbit_home_overview.dart';
import 'package:app/features/home/domain/services/orbit_home_overview_builder.dart';
import 'package:app/features/household_routines/domain/models/household_task.dart';
import 'package:app/features/household_routines/domain/services/household_scope_id.dart';
import 'package:app/features/transactions/data/models/balance_settlement_model.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/transactions/domain/models/shared_transaction_confirmation_status.dart';

final homeReference = DateTime(2026, 9, 20, 15);
WalletModel homeWallet({bool shared = false, String? id}) => WalletModel(
  id: id ?? (shared ? 'shared' : 'solo'),
  name: shared ? 'Nossa carteira' : 'Carteira individual',
  balance: 2486.32,
  type: shared ? WalletType.shared : WalletType.individual,
  ownerId: 'one',
  memberIds: shared ? ['one', 'two'] : ['one'],
);

TransactionModel homeTransaction({
  String id = 'expense',
  String walletId = 'shared',
  double value = 100,
  DateTime? date,
  String type = 'expense',
  String financialStatus = 'settled',
  String? payer = 'one',
  bool split = false,
  SharedTransactionConfirmationStatus confirmation =
      SharedTransactionConfirmationStatus.accepted,
  String paymentMethod = 'cash',
}) => TransactionModel(
  id: id,
  walletId: walletId,
  description: 'Despesa $id',
  category: 'Casa',
  subcategory: 'Outros',
  value: value,
  type: type,
  date: date ?? DateTime(2026, 9, 10),
  financialStatus: financialStatus,
  paymentMethod: paymentMethod,
  paidByMemberId: payer,
  splitType: split ? 'equal' : 'none',
  purchaseFor: split ? 'both' : 'self',
  memberShares: split ? {'one': value / 2, 'two': value / 2} : const {},
  confirmationStatus: confirmation,
);

HouseholdTask homeTask(
  String id, {
  String scopeId = 'user:one',
  bool shared = false,
  DateTime? dueAt,
  HouseholdTaskStatus status = HouseholdTaskStatus.pending,
  DateTime? completedAt,
  DateTime? markedOverdueAt,
}) => HouseholdTask(
  id: id,
  title: id,
  scopeId: scopeId,
  scope: shared ? HouseholdTaskScope.shared : HouseholdTaskScope.personal,
  status: status,
  dueAt: dueAt ?? homeReference,
  completedAt: completedAt,
  markedOverdueAt: markedOverdueAt,
  createdAt: homeReference,
  updatedAt: homeReference,
);

OrbitHomeOverview homeFixture({
  bool shared = false,
  bool populated = true,
  Map<OrbitHomeSection, String> errors = const {},
}) {
  final wallet = homeWallet(shared: shared);
  final taskScope = shared
      ? HouseholdScopeId.shared(wallet.memberIds)
      : HouseholdScopeId.personal('one');
  return const OrbitHomeOverviewBuilder().build(
    wallet: wallet,
    currentUserId: 'one',
    reference: homeReference,
    errors: errors,
    profiles: const {
      'one': UserProfileSummary(userId: 'one', displayName: 'Pessoa Um'),
      'two': UserProfileSummary(userId: 'two', displayName: 'Pessoa Dois'),
    },
    transactions: !populated
        ? []
        : [
            homeTransaction(walletId: wallet.id, value: 2547.20, split: shared),
            homeTransaction(
              id: 'other',
              walletId: wallet.id,
              value: 2349.20,
              payer: 'two',
              split: shared,
            ),
            homeTransaction(
              id: 'aluguel',
              walletId: wallet.id,
              value: 1850,
              date: DateTime(2026, 9, 25),
              financialStatus: 'pending',
            ),
            homeTransaction(
              id: 'internet',
              walletId: wallet.id,
              value: 129.90,
              date: DateTime(2026, 9, 28),
              financialStatus: 'pending',
            ),
          ],
    consumptions: !populated
        ? []
        : [
            BudgetConsumption(
              budget: Budget(
                id: 'budget',
                walletId: wallet.id,
                category: 'Casa',
                month: DateTime(2026, 9),
                limitAmount: 6500,
                createdByUserId: 'one',
                createdAt: homeReference,
                updatedAt: homeReference,
              ),
              spentAmount: 4896.40,
            ),
          ],
    goals: !populated
        ? []
        : [
            for (final category in [
              SavingsGoalCategory.travel,
              SavingsGoalCategory.housing,
            ])
              SavingsGoal(
                id: category.name,
                name: category == SavingsGoalCategory.travel
                    ? 'Viagem dos sonhos'
                    : 'Casa própria',
                category: category,
                targetAmount: 10000,
                savedAmount: 6800,
                walletId: wallet.id,
                createdByUserId: 'one',
                memberIds: wallet.memberIds,
                deadline: DateTime(2027, 6, 1),
                createdAt: homeReference,
                updatedAt: homeReference,
              ),
          ],
    settlements: !shared || !populated
        ? []
        : [
            BalanceSettlementModel(
              id: 'settlement',
              walletId: wallet.id,
              fromMemberId: 'two',
              toMemberId: 'one',
              amount: 184.50,
              createdAt: homeReference,
            ),
          ],
    tasks: !populated
        ? []
        : [
            homeTask('Lavar roupa', scopeId: taskScope, shared: shared),
            homeTask(
              'Estender roupa',
              scopeId: taskScope,
              shared: shared,
              status: HouseholdTaskStatus.completed,
              completedAt: homeReference,
            ),
            homeTask('Guardar roupa', scopeId: taskScope, shared: shared),
          ],
  );
}
