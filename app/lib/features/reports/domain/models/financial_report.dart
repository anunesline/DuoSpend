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
