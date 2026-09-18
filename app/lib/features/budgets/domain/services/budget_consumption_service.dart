import '../../../transactions/data/models/transaction_model.dart';
import '../../../../shared/knowledge/taxonomy/duo_taxonomy.dart';
import '../models/budget.dart';
import '../models/budget_consumption.dart';

class BudgetConsumptionService {
  const BudgetConsumptionService();

  BudgetConsumption calculate({
    required Budget budget,
    required Iterable<TransactionModel> transactions,
    bool walletIsShared = false,
  }) {
    final normalizedCategory = DuoTaxonomy.canonicalCategory(budget.category);
    final seenTransactionIds = <String>{};
    final spent = transactions
        .where((transaction) {
          final transactionId = transaction.id.trim();
          if (transactionId.isNotEmpty &&
              !seenTransactionIds.add(transactionId)) {
            return false;
          }
          return transaction.type == 'expense' &&
              !transaction.isSettlement &&
              transaction.canAffectSharedBalance &&
              (walletIsShared
                  ? transaction.isSharedExpense
                  : !transaction.isSharedExpense) &&
              transaction.walletId.trim() == budget.walletId.trim() &&
              transaction.date.year == budget.month.year &&
              transaction.date.month == budget.month.month &&
              DuoTaxonomy.canonicalCategory(transaction.category) ==
                  normalizedCategory;
        })
        .fold<double>(0, (total, transaction) => total + transaction.value);
    return BudgetConsumption(budget: budget, spentAmount: spent);
  }
}
