import '../../../transactions/data/models/transaction_model.dart';
import '../models/budget.dart';
import '../models/budget_consumption.dart';

class BudgetConsumptionService {
  const BudgetConsumptionService();

  BudgetConsumption calculate({required Budget budget, required Iterable<TransactionModel> transactions}) {
    final normalizedCategory = _normalizeCategory(budget.category);
    final spent = transactions.where((transaction) {
      return transaction.type == 'expense' &&
          !transaction.isSettlement &&
          transaction.canAffectSharedBalance &&
          transaction.walletId.trim() == budget.walletId.trim() &&
          transaction.date.year == budget.month.year &&
          transaction.date.month == budget.month.month &&
          _normalizeCategory(transaction.category) == normalizedCategory;
    }).fold<double>(0, (total, transaction) => total + transaction.value);
    return BudgetConsumption(budget: budget, spentAmount: spent);
  }

  String _normalizeCategory(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? 'Sem categoria' : normalized;
  }
}
