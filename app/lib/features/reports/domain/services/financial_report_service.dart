import '../../../transactions/data/models/transaction_model.dart';
import '../models/financial_report.dart';

class FinancialReportService {
  const FinancialReportService();

  FinancialReport build({
    required List<TransactionModel> transactions,
    required DateTime startDate,
    required DateTime endDate,
    String? category,
    String? transactionType,
  }) {
    final normalizedStart = _dateOnly(startDate);
    final normalizedEnd = _dateOnly(endDate);

    if (normalizedEnd.isBefore(normalizedStart)) {
      throw ArgumentError(
        'A data final do relatório não pode ser anterior à data inicial.',
      );
    }

    final normalizedCategory = category?.trim();
    final normalizedType = transactionType?.trim();

    if (normalizedType != null &&
        normalizedType.isNotEmpty &&
        normalizedType != 'income' &&
        normalizedType != 'expense') {
      throw ArgumentError.value(
        transactionType,
        'transactionType',
        'O tipo deve ser income ou expense.',
      );
    }

    final eligibleTransactions = transactions.where((transaction) {
      final transactionDate = _dateOnly(transaction.date);

      return !transactionDate.isBefore(normalizedStart) &&
          !transactionDate.isAfter(normalizedEnd) &&
          transaction.isFinanciallySettled &&
          !transaction.isSettlement &&
          transaction.canAffectSharedBalance &&
          (normalizedCategory == null ||
              normalizedCategory.isEmpty ||
              _normalizedCategory(transaction.category) ==
                  normalizedCategory) &&
          (normalizedType == null ||
              normalizedType.isEmpty ||
              transaction.type == normalizedType);
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

  List<MonthlyFinancialPoint> buildMonthlyEvolution({
    required List<TransactionModel> transactions,
    required int endYear,
    required int endMonth,
    int monthCount = 6,
    String? category,
    String? transactionType,
  }) {
    if (endMonth < DateTime.january ||
        endMonth > DateTime.december) {
      throw ArgumentError.value(
        endMonth,
        'endMonth',
        'O mês deve estar entre 1 e 12.',
      );
    }

    if (monthCount < 1 || monthCount > 24) {
      throw ArgumentError.value(
        monthCount,
        'monthCount',
        'A evolução deve possuir entre 1 e 24 meses.',
      );
    }

    final end = DateTime(endYear, endMonth);
    final points = <MonthlyFinancialPoint>[];

    for (var offset = monthCount - 1; offset >= 0; offset--) {
      final month = DateTime(end.year, end.month - offset);
      final report = buildMonthly(
        transactions: transactions,
        year: month.year,
        month: month.month,
        category: category,
        transactionType: transactionType,
      );

      points.add(
        MonthlyFinancialPoint(
          month: month,
          report: report,
        ),
      );
    }

    return List.unmodifiable(points);
  }

  FinancialReportComparison compareMonthly({
    required List<TransactionModel> transactions,
    required int year,
    required int month,
    String? category,
    String? transactionType,
  }) {
    final selectedMonth = DateTime(year, month);
    final previousMonth = DateTime(year, month - 1);

    final current = buildMonthly(
      transactions: transactions,
      year: selectedMonth.year,
      month: selectedMonth.month,
      category: category,
      transactionType: transactionType,
    );
    final previous = buildMonthly(
      transactions: transactions,
      year: previousMonth.year,
      month: previousMonth.month,
      category: category,
      transactionType: transactionType,
    );

    return FinancialReportComparison(
      current: current,
      previous: previous,
      income: FinancialMetricComparison(
        currentValue: current.totalIncome,
        previousValue: previous.totalIncome,
      ),
      expense: FinancialMetricComparison(
        currentValue: current.totalExpense,
        previousValue: previous.totalExpense,
      ),
      balance: FinancialMetricComparison(
        currentValue: current.balance,
        previousValue: previous.balance,
      ),
    );
  }

  FinancialReport buildMonthly({
    required List<TransactionModel> transactions,
    required int year,
    required int month,
    String? category,
    String? transactionType,
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
      category: category,
      transactionType: transactionType,
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
