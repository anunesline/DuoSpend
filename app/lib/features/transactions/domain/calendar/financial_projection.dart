import 'financial_calendar_entry.dart';

class FinancialProjection {
  final double currentBalance;
  final double projectedIncome;
  final double projectedExpense;
  final double projectedBalance;
  final List<FinancialCalendarEntry> entries;

  const FinancialProjection({
    required this.currentBalance,
    required this.projectedIncome,
    required this.projectedExpense,
    required this.projectedBalance,
    required this.entries,
  });

  factory FinancialProjection.empty(double currentBalance) {
    return FinancialProjection(
      currentBalance: currentBalance,
      projectedIncome: 0,
      projectedExpense: 0,
      projectedBalance: currentBalance,
      entries: const [],
    );
  }
}
