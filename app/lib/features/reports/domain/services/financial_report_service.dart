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
    DateTime? referenceDate,
  }) {
    final normalizedStart = _dateOnly(startDate);
    final normalizedEnd = _dateOnly(endDate);
    final normalizedReferenceDate = _dateOnly(
      referenceDate ?? DateTime.now(),
    );

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
          _isRecognizedExpenseOrIncome(
            transaction,
            referenceDate: normalizedReferenceDate,
          ) &&
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

  SharedFinancialReport buildSharedResponsibility({
    required FinancialReport report,
    required List<String> memberIds,
  }) {
    final orderedMemberIds = <String>[];
    final paidByMember = <String, double>{};
    final responsibilityByMember = <String, double>{};

    void registerMember(String? memberId) {
      final normalizedMemberId = memberId?.trim();

      if (normalizedMemberId == null || normalizedMemberId.isEmpty) {
        return;
      }

      if (!paidByMember.containsKey(normalizedMemberId)) {
        orderedMemberIds.add(normalizedMemberId);
        paidByMember[normalizedMemberId] = 0;
        responsibilityByMember[normalizedMemberId] = 0;
      }
    }

    for (final memberId in memberIds) {
      registerMember(memberId);
    }

    var totalSharedExpense = 0.0;

    for (final transaction in report.transactions) {
      if (transaction.type != 'expense') {
        continue;
      }

      totalSharedExpense += transaction.value;

      final payerId = transaction.paidByMemberId?.trim();
      registerMember(payerId);

      if (payerId != null && payerId.isNotEmpty) {
        paidByMember[payerId] =
            (paidByMember[payerId] ?? 0) + transaction.value;
      }

      if (transaction.hasFinancialSplit) {
        for (final share in transaction.memberShares.entries) {
          final memberId = share.key.trim();

          if (memberId.isEmpty || share.value <= 0) {
            continue;
          }

          registerMember(memberId);
          responsibilityByMember[memberId] =
              (responsibilityByMember[memberId] ?? 0) + share.value;
        }

        continue;
      }

      if (payerId != null && payerId.isNotEmpty) {
        responsibilityByMember[payerId] =
            (responsibilityByMember[payerId] ?? 0) + transaction.value;
      }
    }

    final members = orderedMemberIds.map((memberId) {
      return MemberFinancialSummary(
        memberId: memberId,
        amountPaid: paidByMember[memberId] ?? 0,
        responsibility: responsibilityByMember[memberId] ?? 0,
      );
    }).toList();

    return SharedFinancialReport(
      totalSharedExpense: totalSharedExpense,
      members: List.unmodifiable(members),
    );
  }

  List<MonthlyFinancialPoint> buildMonthlyEvolution({
    required List<TransactionModel> transactions,
    required int endYear,
    required int endMonth,
    int monthCount = 6,
    String? category,
    String? transactionType,
    DateTime? referenceDate,
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
        referenceDate: referenceDate,
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
    DateTime? referenceDate,
  }) {
    final selectedMonth = DateTime(year, month);
    final previousMonth = DateTime(year, month - 1);

    final current = buildMonthly(
      transactions: transactions,
      year: selectedMonth.year,
      month: selectedMonth.month,
      category: category,
      transactionType: transactionType,
      referenceDate: referenceDate,
    );
    final previous = buildMonthly(
      transactions: transactions,
      year: previousMonth.year,
      month: previousMonth.month,
      category: category,
      transactionType: transactionType,
      referenceDate: referenceDate,
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
    DateTime? referenceDate,
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
      referenceDate: referenceDate,
    );
  }

  bool _isRecognizedExpenseOrIncome(
    TransactionModel transaction, {
    required DateTime referenceDate,
  }) {
    if (transaction.isInstallment &&
        _dateOnly(transaction.date).isAfter(referenceDate)) {
      return false;
    }

    final isCreditCardPurchase =
        transaction.type == 'expense' &&
        transaction.paymentMethod == 'creditCard';

    if (isCreditCardPurchase) {
      return transaction.isSettledByInvoice ||
          transaction.isFinanciallySettled;
    }

    return transaction.isFinanciallySettled;
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
