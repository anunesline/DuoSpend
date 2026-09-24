import '../../../auth/data/repositories/user_repository.dart';
import '../../../financial_intelligence/domain/models/financial_insight.dart';
import '../../../goals/domain/models/savings_goal.dart';
import '../../../household_routines/domain/models/household_task.dart';
import '../../../reports/domain/models/financial_report.dart';
import '../../../transactions/data/models/balance_settlement_model.dart';
import '../../../transactions/domain/calendar/financial_calendar_entry.dart';
import '../../../transactions/domain/calendar/financial_projection.dart';
import '../../data/models/wallet_model.dart';
import 'orbit_dashboard_summary.dart';

enum OrbitHomeSection {
  budget,
  goals,
  calendar,
  settlements,
  routines,
  profiles,
}

/// A read-only view of one existing wallet/household, never a second scope.
class OrbitHomeOverview {
  final WalletModel wallet;
  final String currentUserId;
  final DateTime reference;
  final OrbitDashboardSummary summary;
  final FinancialReport monthReport;
  final SharedFinancialReport contribution;
  final FinancialProjection? projection;
  final List<FinancialCalendarEntry> commitments;
  final List<SavingsGoal> goals;
  final List<BalanceSettlementModel> settlements;
  final List<HouseholdTask> todayTasks;
  final int overdueTaskCount;
  final int pendingConfirmationCount;
  final Map<String, UserProfileSummary> profiles;
  final List<FinancialInsight> insights;
  final Map<OrbitHomeSection, String> errors;

  const OrbitHomeOverview({
    required this.wallet,
    required this.currentUserId,
    required this.reference,
    required this.summary,
    required this.monthReport,
    required this.contribution,
    required this.projection,
    this.commitments = const [],
    this.goals = const [],
    this.settlements = const [],
    this.todayTasks = const [],
    this.overdueTaskCount = 0,
    this.pendingConfirmationCount = 0,
    this.profiles = const {},
    this.insights = const [],
    this.errors = const {},
  });

  double get committedAmount =>
      commitments.fold(0, (sum, entry) => sum + entry.value);

  String memberName(String id) {
    final name = profiles[id]?.displayName.trim();
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    return id == currentUserId ? 'Você' : 'Outro membro';
  }

  bool get hasPendingItems =>
      pendingConfirmationCount > 0 ||
      settlements.any(
        (item) =>
            item.isAwaitingConfirmation && item.toMemberId == currentUserId,
      ) ||
      overdueTaskCount > 0;
}
