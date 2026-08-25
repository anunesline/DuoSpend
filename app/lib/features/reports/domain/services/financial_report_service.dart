import '../../../transactions/data/models/transaction_model.dart';
import '../models/financial_report.dart';

class FinancialReportService {
  const FinancialReportService();

  FinancialReport build({
    required List<TransactionModel> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final normalizedStart = _dateOnly(startDate);
    final normalizedEnd = _dateOnly(endDate);

    if (normalizedEnd.isBefore(normalizedStart)) {
      throw ArgumentError(
        'A data final do relatório não pode ser anterior à data inicial.',
      );
    }

    final eligibleTransactions = transactions.where((transaction) {
      final transactionDate = _dateOnly(transaction.date);

      return !transactionDate.isBefore(normalizedStart) &&
          !transactionDate.isAfter(normalizedEnd) &&
          transaction.isFinanciallySettled &&
          !transaction.isSettlement &&
          transaction.canAffectSharedBalance;
    }).toList()
      ..sort((first, second) => second.date.compareTo(first.date));

    var totalIncome = 0.0;
    var totalExpense = 0.0;
    final expensesByCategory = <String, double>{};

    for (final transaction in eligibleTransactions) {
      if (transaction.type == 'income') {
        totalIncome += transaction.value;
        continue;
      }

      if (transaction.type != 'expense') {
        continue;
      }

      totalExpense += transaction.value;

      final category = _normalizedCategory(transaction.category);
      expensesByCategory.update(
        category,
        (currentValue) => currentValue + transaction.value,
        ifAbsent: () => transaction.value,
      );
    }

    final categoryTotals = expensesByCategory.entries.map((entry) {
      final percentage = totalExpense == 0
          ? 0.0
          : (entry.value / totalExpense) * 100;

      return FinancialCategoryTotal(
        category: entry.key,
        amount: entry.value,
        percentage: percentage,
      );
    }).toList()
      ..sort((first, second) {
        final amountComparison = second.amount.compareTo(first.amount);

        if (amountComparison != 0) {
          return amountComparison;
        }

        return first.category.compareTo(second.category);
      });

    return FinancialReport(
      startDate: normalizedStart,
      endDate: normalizedEnd,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      expenseByCategory: List.unmodifiable(categoryTotals),
      transactions: List.unmodifiable(eligibleTransactions),
    );
  }

  FinancialReport buildMonthly({
    required List<TransactionModel> transactions,
    required int year,
    required int month,
  }) {
    if (month < DateTime.january || month > DateTime.december) {
      throw ArgumentError.value(
        month,
        'month',
        'O mês deve estar entre 1 e 12.',
      );
    }

    final startDate = DateTime(year, month);
    final endDate = DateTime(year, month + 1, 0);

    return build(
      transactions: transactions,
      startDate: startDate,
      endDate: endDate,
    );
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _normalizedCategory(String category) {
    final normalizedCategory = category.trim();

    return normalizedCategory.isEmpty
        ? 'Sem categoria'
        : normalizedCategory;
  }
}
