import '../../../transactions/data/models/transaction_model.dart';

class FinancialCategoryTotal {
  final String category;
  final double amount;
  final double percentage;

  const FinancialCategoryTotal({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class FinancialReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final double totalExpense;
  final List<FinancialCategoryTotal> expenseByCategory;
  final List<TransactionModel> transactions;

  const FinancialReport({
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.expenseByCategory,
    required this.transactions,
  });

  double get balance => totalIncome - totalExpense;

  bool get isEmpty => transactions.isEmpty;
}


class FinancialMetricComparison {
  final double currentValue;
  final double previousValue;

  const FinancialMetricComparison({
    required this.currentValue,
    required this.previousValue,
  });

  double get difference => currentValue - previousValue;

  bool get hasPreviousValue => previousValue != 0;

  double? get percentageChange {
    if (!hasPreviousValue) {
      return null;
    }

    return (difference / previousValue.abs()) * 100;
  }

  bool get increased => difference > 0;

  bool get decreased => difference < 0;

  bool get unchanged => difference == 0;
}

class FinancialReportComparison {
  final FinancialReport current;
  final FinancialReport previous;
  final FinancialMetricComparison income;
  final FinancialMetricComparison expense;
  final FinancialMetricComparison balance;

  const FinancialReportComparison({
    required this.current,
    required this.previous,
    required this.income,
    required this.expense,
    required this.balance,
  });
}
