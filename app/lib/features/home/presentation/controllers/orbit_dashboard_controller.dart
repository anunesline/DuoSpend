import 'package:flutter/foundation.dart';

import '../../../auth/data/repositories/user_repository.dart';
import '../../../budgets/data/repositories/budget_repository.dart';
import '../../../budgets/domain/models/budget.dart';
import '../../../budgets/domain/services/budget_consumption_service.dart';
import '../../../goals/data/repositories/savings_goal_repository.dart';
import '../../../goals/domain/models/savings_goal.dart';
import '../../../household_routines/domain/repositories/household_task_repository.dart';
import '../../../household_routines/domain/models/household_task.dart';
import '../../../transactions/data/models/balance_settlement_model.dart';
import '../../data/models/credit_card_invoice_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/repositories/balance_settlement_repository.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/credit_card_repository.dart';
import '../../domain/models/orbit_dashboard_summary.dart';
import '../../domain/models/orbit_home_overview.dart';
import '../../domain/services/orbit_dashboard_summary_builder.dart';
import '../../domain/services/orbit_home_overview_builder.dart';

class OrbitDashboardController extends ChangeNotifier {
  final BudgetRepository _budgetRepository;
  final SavingsGoalRepository _goalRepository;
  final CreditCardRepository _creditCardRepository;
  final BalanceSettlementRepository _settlementRepository;
  final HouseholdTaskRepository? taskRepository;
  final UserRepository _userRepository;
  final BudgetConsumptionService budgetConsumptionService;
  final OrbitDashboardSummaryBuilder summaryBuilder;

  OrbitDashboardSummary summary = OrbitDashboardSummary.empty;
  OrbitHomeOverview? overview;
  bool isLoading = false;
  String? errorMessage;
  int _loadVersion = 0;
  bool _disposed = false;

  OrbitDashboardController({
    BudgetRepository? budgetRepository,
    SavingsGoalRepository? goalRepository,
    CreditCardRepository? creditCardRepository,
    BalanceSettlementRepository? settlementRepository,
    this.taskRepository,
    UserRepository? userRepository,
    this.budgetConsumptionService = const BudgetConsumptionService(),
    this.summaryBuilder = const OrbitDashboardSummaryBuilder(),
  }) : _budgetRepository = budgetRepository ?? BudgetRepository(),
       _goalRepository = goalRepository ?? SavingsGoalRepository(),
       _creditCardRepository = creditCardRepository ?? CreditCardRepository(),
       _settlementRepository =
           settlementRepository ?? BalanceSettlementRepository(),
       _userRepository = userRepository ?? UserRepository();

  /// Invalidates in-flight reads immediately when the selected context changes.
  void clear() {
    if (_disposed) return;
    _loadVersion++;
    overview = null;
    summary = OrbitDashboardSummary.empty;
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> load({
    required WalletModel wallet,
    required List<TransactionModel> transactions,
    String? currentUserId,
    DateTime? now,
  }) async {
    if (_disposed) return;
    final version = ++_loadVersion;
    final reference = now ?? DateTime.now();
    final userId = currentUserId ?? wallet.ownerId;
    final scopedTransactions = transactions
        .where((item) => item.walletId == wallet.id)
        .toList();
    overview = null;
    summary = OrbitDashboardSummary.empty;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final errors = <OrbitHomeSection, String>{};
    Future<T> read<T>(
      OrbitHomeSection section,
      Future<T> Function() action,
      T fallback,
    ) async {
      try {
        return await action();
      } catch (_) {
        errors[section] = 'Não foi possível atualizar este resumo.';
        return fallback;
      }
    }

    try {
      // Independent reads fail independently: an unavailable avatar, for
      // example, must not blank out the financial cards or manufacture zeros.
      final budgetsFuture = read<List<Budget>>(
        OrbitHomeSection.budget,
        () => _budgetRepository.getByWallet(wallet: wallet),
        [],
      );
      final goalsFuture = read<List<SavingsGoal>>(
        OrbitHomeSection.goals,
        () => _goalRepository.getGoalsByWallet(wallet.id),
        [],
      );
      final invoicesFuture = read<List<CreditCardInvoiceModel>>(
        OrbitHomeSection.calendar,
        () async {
          if (wallet.isShared) return [];
          final cards = await _creditCardRepository.getCards();
          final lists = await Future.wait(
            cards
                .where((card) => card.walletId == wallet.id)
                .map(
                  (card) => _creditCardRepository.getInvoices(cardId: card.id),
                ),
          );
          return lists.expand((items) => items).toList();
        },
        [],
      );
      final settlementsFuture = read<List<BalanceSettlementModel>>(
        OrbitHomeSection.settlements,
        () async => wallet.isShared
            ? _settlementRepository.getPendingSettlements(walletId: wallet.id)
            : [],
        [],
      );
      final scopeId = OrbitHomeOverviewBuilder.taskScope(wallet, userId);
      final tasksFuture = read<List<HouseholdTask>>(
        OrbitHomeSection.routines,
        () async => scopeId != null && taskRepository != null
            ? taskRepository!.getTasksByScope(scopeId)
            : [],
        [],
      );
      final profilesFuture = read(
        OrbitHomeSection.profiles,
        () => _userRepository.getUserProfileSummaries({
          userId,
          ...wallet.memberIds,
        }),
        <String, UserProfileSummary>{},
      );

      // Await every started read even if a later load supersedes this one.
      final (budgets, goals, invoices, settlements, tasks, profiles) = await (
        budgetsFuture,
        goalsFuture,
        invoicesFuture,
        settlementsFuture,
        tasksFuture,
        profilesFuture,
      ).wait;
      if (_disposed || version != _loadVersion) return;
      final consumptions = budgets
          .where(
            (budget) =>
                budget.isActive &&
                budget.month.year == reference.year &&
                budget.month.month == reference.month,
          )
          .map(
            (budget) => budgetConsumptionService.calculate(
              budget: budget,
              transactions: scopedTransactions,
              walletIsShared: wallet.isShared,
            ),
          )
          .toList();
      summary = summaryBuilder.build(
        consumptions: consumptions,
        goals: goals,
        invoices: invoices,
        reference: reference,
      );
      overview = const OrbitHomeOverviewBuilder().build(
        wallet: wallet,
        currentUserId: userId,
        reference: reference,
        transactions: scopedTransactions,
        consumptions: consumptions,
        goals: goals,
        invoices: invoices,
        settlements: settlements,
        tasks: tasks,
        profiles: profiles,
        errors: errors,
      );
    } catch (_) {
      if (_disposed || version != _loadVersion) return;
      overview = null;
      summary = OrbitDashboardSummary.empty;
      errorMessage = 'Não foi possível carregar o resumo da Home.';
    } finally {
      if (!_disposed && version == _loadVersion) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _loadVersion++;
    super.dispose();
  }
}
