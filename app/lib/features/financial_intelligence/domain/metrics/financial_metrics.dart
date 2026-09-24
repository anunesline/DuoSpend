import '../../../budgets/domain/models/budget.dart';
import '../../../budgets/domain/services/budget_consumption_service.dart';
import '../../../home/data/models/credit_card_invoice_model.dart';
import '../../../home/data/models/credit_card_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../facts/financial_facts.dart';

enum FinancialMetricAvailability { available, suppressed }

class FinancialMetricValue {
  const FinancialMetricValue.available(this.value)
    : availability = FinancialMetricAvailability.available,
      reason = null;
  const FinancialMetricValue.suppressed([this.reason])
    : value = null,
      availability = FinancialMetricAvailability.suppressed;
  final double? value;
  final FinancialMetricAvailability availability;
  final String? reason;
  bool get isAvailable => availability == FinancialMetricAvailability.available;
}

class FinancialCategoryMetric {
  const FinancialCategoryMetric({
    required this.category,
    required this.amount,
    required this.shareOfExpense,
  });
  final String category;
  final double amount;
  final double shareOfExpense;
}

class FinancialResponsibilityMetric {
  const FinancialResponsibilityMetric({
    required this.memberId,
    required this.amount,
  });
  final String memberId;
  final double amount;
}

class FinancialMetrics {
  const FinancialMetrics({
    required this.realizedIncome,
    required this.realizedExpense,
    required this.economicNet,
    required this.cashInflow,
    required this.cashOutflow,
    required this.cashNet,
    required this.categories,
    required this.commitmentOutflow,
    required this.commitmentInflow,
    required this.commitmentNet,
    required this.commitmentsByKind,
    required this.responsibilities,
    this.budget,
    this.card,
  });
  final FinancialMetricValue realizedIncome;
  final FinancialMetricValue realizedExpense;
  final FinancialMetricValue economicNet;
  final FinancialMetricValue cashInflow;
  final FinancialMetricValue cashOutflow;
  final FinancialMetricValue cashNet;
  final List<FinancialCategoryMetric> categories;
  final FinancialMetricValue commitmentOutflow;
  final FinancialMetricValue commitmentInflow;
  final FinancialMetricValue commitmentNet;
  final Map<FinancialCommitmentKind, double> commitmentsByKind;
  final List<FinancialResponsibilityMetric> responsibilities;
  final FinancialBudgetMetrics? budget;
  final FinancialCardMetrics? card;
}

class FinancialBudgetMetrics {
  const FinancialBudgetMetrics({
    required this.limit,
    required this.consumed,
    required this.available,
    required this.consumedRatio,
  });
  final FinancialMetricValue limit;
  final FinancialMetricValue consumed;
  final FinancialMetricValue available;
  final FinancialMetricValue consumedRatio;
}

class FinancialCardMetrics {
  const FinancialCardMetrics({
    required this.creditLimit,
    required this.usedLimit,
    required this.availableLimit,
    required this.openInvoiceTotal,
  });
  final FinancialMetricValue creditLimit;
  final FinancialMetricValue usedLimit;
  final FinancialMetricValue availableLimit;
  final FinancialMetricValue openInvoiceTotal;
}

class FinancialInvoiceTransactionLink {
  const FinancialInvoiceTransactionLink({
    required this.transactionId,
    required this.invoiceId,
  });
  final String transactionId;
  final String invoiceId;
}

class FinancialMetricsCalculator {
  const FinancialMetricsCalculator({
    this.budgetConsumptionService = const BudgetConsumptionService(),
  });
  final BudgetConsumptionService budgetConsumptionService;

  FinancialMetrics calculate({
    required FinancialFactNormalizationResult facts,
    required DateTime periodStart,
    required DateTime periodEnd,
    DateTime? commitmentRangeEnd,
    List<FinancialInvoiceTransactionLink> invoiceLinks = const [],
    Budget? budget,
    Iterable<TransactionModel> budgetTransactions = const [],
    bool walletIsShared = false,
    CreditCardModel? card,
    Iterable<CreditCardInvoiceModel> invoices = const [],
  }) {
    final start = _dateOnly(periodStart);
    final end = _dateOnly(periodEnd);
    if (end.isBefore(start))
      throw ArgumentError('periodEnd cannot precede periodStart');
    final commitmentEnd = _dateOnly(commitmentRangeEnd ?? periodEnd);
    if (commitmentEnd.isBefore(start))
      throw ArgumentError('commitmentRangeEnd cannot precede periodStart');
    final economic = facts.economicFacts
        .where((f) => _inRange(f.occurredAt, start, end))
        .toList();
    final cash = facts.cashFacts
        .where((f) => _inRange(f.occurredAt, start, end))
        .toList();
    final income = economic
        .where((f) => f.nature == FinancialEconomicNature.income)
        .fold<double>(0, (s, f) => s + f.amount);
    final expense = economic
        .where((f) => f.nature == FinancialEconomicNature.expense)
        .fold<double>(0, (s, f) => s + f.amount);
    final inflow = cash
        .where(
          (f) =>
              f.nature == FinancialCashNature.inflow ||
              f.nature == FinancialCashNature.internalTransferIn ||
              f.nature == FinancialCashNature.settlementIn,
        )
        .fold<double>(0, (s, f) => s + f.amount);
    final outflow = cash
        .where(
          (f) =>
              f.nature == FinancialCashNature.outflow ||
              f.nature == FinancialCashNature.internalTransferOut ||
              f.nature == FinancialCashNature.invoicePaymentOut ||
              f.nature == FinancialCashNature.settlementOut,
        )
        .fold<double>(0, (s, f) => s + f.amount);
    final categories = <String, double>{};
    for (final bundle in facts.facts) {
      final fact = bundle.economic;
      final category = bundle.source.category;
      if (fact != null &&
          fact.nature == FinancialEconomicNature.expense &&
          _inRange(fact.occurredAt, start, end) &&
          category != null)
        categories[category] = (categories[category] ?? 0) + fact.amount;
    }
    final commitments = <FinancialCommitmentKind, double>{};
    var commitmentOutflow = 0.0;
    var commitmentInflow = 0.0;
    final eligibleInvoiceIds = invoices
        .where(
          (invoice) =>
              !invoice.isPaid &&
              _inRange(invoice.dueDate, start, commitmentEnd),
        )
        .map((invoice) => invoice.id)
        .toSet();
    final linked = invoiceLinks
        .where(
          (link) =>
              link.transactionId.trim().isNotEmpty &&
              link.invoiceId.trim().isNotEmpty &&
              eligibleInvoiceIds.contains(link.invoiceId),
        )
        .map((link) => link.transactionId)
        .toSet();
    for (final bundle in facts.facts) {
      final c = bundle.commitment;
      if (c == null || !_inRange(c.dueAt, start, commitmentEnd)) continue;
      if (bundle.source.kind == FinancialFactSourceKind.transaction &&
          linked.contains(bundle.source.id))
        continue;
      commitments[c.kind] = (commitments[c.kind] ?? 0) + c.amount;
      if (c.direction == FinancialCommitmentDirection.inflow) {
        commitmentInflow += c.amount;
      } else {
        commitmentOutflow += c.amount;
      }
    }
    final responsibility = <String, double>{};
    for (final bundle in facts.facts) {
      final fact = bundle.economic;
      if (fact == null || !_inRange(fact.occurredAt, start, end)) continue;
      for (final share in bundle.responsibilities)
        responsibility[share.memberId] =
            (responsibility[share.memberId] ?? 0) + share.amount;
    }
    FinancialBudgetMetrics? budgetMetrics;
    if (budget != null) {
      final consumed = budgetConsumptionService
          .calculate(
            budget: budget,
            transactions: budgetTransactions,
            walletIsShared: walletIsShared,
          )
          .spentAmount;
      budgetMetrics = FinancialBudgetMetrics(
        limit: FinancialMetricValue.available(budget.limitAmount),
        consumed: FinancialMetricValue.available(consumed),
        available: FinancialMetricValue.available(
          budget.limitAmount - consumed,
        ),
        consumedRatio: budget.limitAmount == 0
            ? const FinancialMetricValue.suppressed('zero limit')
            : FinancialMetricValue.available(consumed / budget.limitAmount),
      );
    }
    FinancialCardMetrics? cardMetrics;
    if (card != null) {
      final open = invoices
          .where((i) => !i.isPaid && _inRange(i.dueDate, start, commitmentEnd))
          .fold<double>(0, (s, i) => s + i.total);
      cardMetrics = FinancialCardMetrics(
        creditLimit: FinancialMetricValue.available(card.creditLimit),
        usedLimit: FinancialMetricValue.available(card.usedLimit),
        availableLimit: FinancialMetricValue.available(card.availableLimit),
        openInvoiceTotal: FinancialMetricValue.available(open),
      );
    }
    return FinancialMetrics(
      realizedIncome: FinancialMetricValue.available(income),
      realizedExpense: FinancialMetricValue.available(expense),
      economicNet: FinancialMetricValue.available(income - expense),
      cashInflow: FinancialMetricValue.available(inflow),
      cashOutflow: FinancialMetricValue.available(outflow),
      cashNet: FinancialMetricValue.available(inflow - outflow),
      categories: categories.entries
          .map(
            (e) => FinancialCategoryMetric(
              category: e.key,
              amount: e.value,
              shareOfExpense: expense == 0 ? 0 : e.value / expense,
            ),
          )
          .toList(growable: false),
      commitmentOutflow: FinancialMetricValue.available(commitmentOutflow),
      commitmentInflow: FinancialMetricValue.available(commitmentInflow),
      commitmentNet: FinancialMetricValue.available(
        commitmentInflow - commitmentOutflow,
      ),
      commitmentsByKind: Map.unmodifiable(commitments),
      responsibilities: responsibility.entries
          .map(
            (e) =>
                FinancialResponsibilityMetric(memberId: e.key, amount: e.value),
          )
          .toList(growable: false),
      budget: budgetMetrics,
      card: cardMetrics,
    );
  }

  bool _inRange(DateTime value, DateTime start, DateTime end) {
    final date = _dateOnly(value);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
