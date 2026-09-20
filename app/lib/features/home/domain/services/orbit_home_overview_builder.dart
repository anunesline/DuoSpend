import '../../../auth/data/repositories/user_repository.dart';
import '../../../budgets/domain/models/budget_consumption.dart';
import '../../../financial_intelligence/domain/models/financial_intelligence_input.dart';
import '../../../financial_intelligence/domain/services/financial_intelligence_service.dart';
import '../../../goals/domain/models/savings_goal.dart';
import '../../../household_routines/domain/models/household_task.dart';
import '../../../household_routines/domain/services/household_scope_id.dart';
import '../../../reports/domain/services/financial_report_service.dart';
import '../../../transactions/data/models/balance_settlement_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/domain/calendar/financial_calendar_service.dart';
import '../../data/models/credit_card_invoice_model.dart';
import '../../data/models/wallet_model.dart';
import '../models/orbit_home_overview.dart';
import 'orbit_dashboard_summary_builder.dart';

class OrbitHomeOverviewBuilder {
  const OrbitHomeOverviewBuilder();

  /// Same scope identifiers as the routines hub; a shared wallet alone does
  /// not create a household or expose personal tasks in the shared view.
  static String? taskScope(WalletModel wallet, String currentUserId) {
    if (!wallet.isShared) return HouseholdScopeId.personal(currentUserId);
    if (wallet.memberIds.length < 2 || !wallet.hasMember(currentUserId)) {
      return null;
    }
    return HouseholdScopeId.shared(wallet.memberIds);
  }

  OrbitHomeOverview build({
    required WalletModel wallet,
    required String currentUserId,
    required DateTime reference,
    required List<TransactionModel> transactions,
    List<BudgetConsumption> consumptions = const [],
    List<SavingsGoal> goals = const [],
    List<CreditCardInvoiceModel> invoices = const [],
    List<BalanceSettlementModel> settlements = const [],
    List<HouseholdTask> tasks = const [],
    Map<String, UserProfileSummary> profiles = const {},
    Map<OrbitHomeSection, String> errors = const {},
  }) {
    const reports = FinancialReportService();
    const calendar = FinancialCalendarService();
    final today = DateTime(reference.year, reference.month, reference.day);
    final monthEnd = DateTime(reference.year, reference.month + 1, 0);
    final scoped = transactions
        .where(
          (item) =>
              item.walletId == wallet.id &&
              (!wallet.isShared || item.canAffectSharedBalance),
        )
        .toList();
    final monthReport = reports.buildMonthly(
      transactions: scoped,
      year: today.year,
      month: today.month,
      referenceDate: today,
    );
    final previousMonth = DateTime(today.year, today.month - 1);
    final previousReport = reports.buildMonthly(
      transactions: scoped,
      year: previousMonth.year,
      month: previousMonth.month,
      referenceDate: today,
    );
    // Personal credit cards are never counted as a joint account/invoice.
    final scopeInvoices = wallet.isIndividual
        ? invoices
        : <CreditCardInvoiceModel>[];
    final projection = errors.containsKey(OrbitHomeSection.calendar)
        ? null
        : calendar.buildProjection(
            currentBalance: wallet.balance,
            transactions: scoped,
            invoices: scopeInvoices,
            rangeStart: today,
            rangeEnd: monthEnd,
            now: today,
          );
    final upcoming = projection == null
        ? null
        : calendar.buildProjection(
            currentBalance: wallet.balance,
            transactions: scoped,
            invoices: scopeInvoices,
            rangeStart: today,
            rangeEnd: today.add(const Duration(days: 30)),
            now: today,
          );
    final activeGoals =
        goals
            .where((goal) => goal.walletId == wallet.id && goal.isActive)
            .toList()
          ..sort((a, b) {
            if (a.deadline == null && b.deadline == null) {
              return b.progress.compareTo(a.progress);
            }
            if (a.deadline == null) return 1;
            if (b.deadline == null) return -1;
            return a.deadline!.compareTo(b.deadline!);
          });
    final scopeId = taskScope(wallet, currentUserId);
    final scopedTasks = tasks.where(
      (task) =>
          task.scopeId == scopeId &&
          task.scope ==
              (wallet.isShared
                  ? HouseholdTaskScope.shared
                  : HouseholdTaskScope.personal),
    );
    bool isToday(DateTime? value) =>
        value != null &&
        value.year == today.year &&
        value.month == today.month &&
        value.day == today.day;
    final todayTasks =
        scopedTasks
            .where(
              (task) =>
                  (task.isPending &&
                      !task.isManuallyMarkedOverdue &&
                      isToday(task.dueAt)) ||
                  (task.isCompleted && isToday(task.completedAt)),
            )
            .toList()
          ..sort(
            (a, b) => (a.dueAt ?? a.completedAt ?? a.createdAt).compareTo(
              b.dueAt ?? b.completedAt ?? b.createdAt,
            ),
          );
    final summary = const OrbitDashboardSummaryBuilder().build(
      consumptions: consumptions,
      goals: activeGoals,
      invoices: scopeInvoices,
      reference: reference,
    );
    return OrbitHomeOverview(
      wallet: wallet,
      currentUserId: currentUserId,
      reference: reference,
      summary: summary,
      monthReport: monthReport,
      contribution: reports.buildSharedResponsibility(
        report: monthReport,
        memberIds: wallet.memberIds,
      ),
      projection: projection,
      commitments: List.unmodifiable(
        upcoming?.entries.where(
              (entry) => entry.isExpense && entry.isProjected,
            ) ??
            [],
      ),
      goals: List.unmodifiable(activeGoals),
      settlements: List.unmodifiable(
        settlements.where(
          (item) =>
              wallet.isShared &&
              item.walletId == wallet.id &&
              (item.isPending || item.isAwaitingConfirmation),
        ),
      ),
      todayTasks: List.unmodifiable(todayTasks),
      overdueTaskCount: scopedTasks
          .where(
            (task) =>
                task.isPending &&
                (task.isManuallyMarkedOverdue ||
                    (task.dueAt != null && task.dueAt!.isBefore(today))),
          )
          .length,
      pendingConfirmationCount: wallet.isShared
          ? transactions
                .where(
                  (item) =>
                      item.walletId == wallet.id &&
                      item.isAwaitingConfirmation &&
                      item.paidByMemberId?.trim().isNotEmpty == true &&
                      item.paidByMemberId != currentUserId,
                )
                .length
          : 0,
      profiles: Map.unmodifiable(profiles),
      // Reuse the current rules engine. No LLM/API or invented observations.
      insights: projection == null
          ? const []
          : const FinancialIntelligenceService().build(
              FinancialIntelligenceInput(
                currentMonth: monthReport,
                previousMonth: previousReport.transactions.isEmpty
                    ? null
                    : previousReport,
                historicalMonths: reports
                    .buildMonthlyEvolution(
                      transactions: scoped,
                      endYear: previousMonth.year,
                      endMonth: previousMonth.month,
                      monthCount: 3,
                      referenceDate: today,
                    )
                    .map((point) => point.report)
                    .toList(),
                projection: projection,
                budgets: consumptions,
                goals: goals
                    .where((goal) => goal.walletId == wallet.id)
                    .toList(),
                currentInvoices: scopeInvoices
                    .where(
                      (invoice) =>
                          invoice.referenceYear == today.year &&
                          invoice.referenceMonth == today.month,
                    )
                    .toList(),
                previousInvoices: scopeInvoices
                    .where(
                      (invoice) =>
                          invoice.referenceYear == previousMonth.year &&
                          invoice.referenceMonth == previousMonth.month,
                    )
                    .toList(),
                now: reference,
              ),
            ),
      errors: Map.unmodifiable(errors),
    );
  }
}
