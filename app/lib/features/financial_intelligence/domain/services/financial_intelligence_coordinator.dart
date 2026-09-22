import '../../../home/data/models/wallet_model.dart';
import '../../../budgets/domain/models/budget.dart';
import '../../../budgets/domain/services/budget_consumption_service.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../comparison/financial_comparison.dart';
import '../facts/financial_facts.dart';
import '../metrics/financial_metrics.dart';
import '../signals/financial_signal_policies.dart';
import '../signals/financial_signals.dart';
import 'financial_fact_normalizer.dart';

/// Runtime composition root for the deterministic financial intelligence
/// layers. It owns orchestration only; all rules remain in FI-A through FI-D.
class FinancialIntelligenceCoordinator {
  const FinancialIntelligenceCoordinator({
    this.normalizer = const FinancialFactNormalizer(),
    this.metricsCalculator = const FinancialMetricsCalculator(),
    this.comparisonCalculator = const FinancialComparisonCalculator(),
    this.detector = const FinancialSignalDetector(),
  });

  final FinancialFactNormalizer normalizer;
  final FinancialMetricsCalculator metricsCalculator;
  final FinancialComparisonCalculator comparisonCalculator;
  final FinancialSignalDetector detector;

  List<FinancialSignal> build({
    required WalletModel wallet,
    required Iterable<TransactionModel> transactions,
    required DateTime referenceAt,
    DateTime? commitmentRangeEnd,
    Iterable<Budget> budgets = const [],
    Iterable<FinancialCardInvoiceSource> invoices = const [],
  }) {
    final reference = DateTime(
      referenceAt.year,
      referenceAt.month,
      referenceAt.day,
    );
    final current = FinancialComparablePeriod(
      start: DateTime(reference.year, reference.month),
      end: reference,
      walletId: wallet.id,
      walletScope: wallet.isShared
          ? FinancialWalletScope.sharedWallet
          : FinancialWalletScope.individualWallet,
      completeness: FinancialPeriodCompleteness.partial,
    );
    final previous = comparisonCalculator.previousEquivalentMonth(current);
    final all = transactions.toList(growable: false);
    final horizon =
        commitmentRangeEnd ?? DateTime(reference.year, reference.month + 1, 0);
    final invoiceSources = invoices.toList(growable: false);
    final currentFacts = normalizer.normalize(
      FinancialFactNormalizationInput(
        wallet: wallet,
        referenceAt: reference,
        commitmentRangeEnd: horizon,
        transactions: all,
        invoices: invoiceSources,
      ),
    );
    final previousFacts = normalizer.normalize(
      FinancialFactNormalizationInput(
        wallet: wallet,
        referenceAt: previous.end,
        commitmentRangeEnd: previous.end,
        transactions: all,
      ),
    );
    final currentMetrics = metricsCalculator.calculate(
      facts: currentFacts,
      periodStart: current.start,
      periodEnd: current.end,
    );
    final previousMetrics = metricsCalculator.calculate(
      facts: previousFacts,
      periodStart: previous.start,
      periodEnd: previous.end,
    );
    final signals = <FinancialSignal>[];
    final hasPreviousData = all.any((transaction) {
      final date = transaction.date;
      return !date.isBefore(previous.start) && !date.isAfter(previous.end);
    });
    void add(
      FinancialSignalType type,
      FinancialSignalMetric metric,
      double? now,
      double? before,
    ) {
      final comparison = comparisonCalculator.compare(
        currentPeriod: current,
        comparisonPeriod: previous,
        current: now,
        comparison: before,
      );
      signals.addAll(
        detector.comparative(
          type: type,
          metric: metric,
          comparison: comparison,
          period: current,
          comparisonPeriod: previous,
          policy: FinancialSignalPolicies.v1,
        ),
      );
    }

    if (hasPreviousData) {
      add(
        FinancialSignalType.spendingChanged,
        FinancialSignalMetric.realizedExpense,
        currentMetrics.realizedExpense.value,
        previousMetrics.realizedExpense.value,
      );
      add(
        FinancialSignalType.incomeChanged,
        FinancialSignalMetric.realizedIncome,
        currentMetrics.realizedIncome.value,
        previousMetrics.realizedIncome.value,
      );
      add(
        FinancialSignalType.cashFlowChanged,
        FinancialSignalMetric.cashNet,
        currentMetrics.cashNet.value,
        previousMetrics.cashNet.value,
      );
    }
    final budgetService = const BudgetConsumptionService();
    for (final budget in budgets) {
      if (!budget.isActive ||
          budget.walletId != wallet.id ||
          budget.month.year != reference.year ||
          budget.month.month != reference.month) {
        continue;
      }
      final consumed = budgetService
          .calculate(
            budget: budget,
            transactions: all,
            walletIsShared: wallet.isShared,
          )
          .spentAmount;
      signals.addAll(
        detector.budget(
          period: current,
          limit: budget.limitAmount,
          consumed: consumed,
          category: budget.category,
        ),
      );
    }
    final commitmentMetrics = metricsCalculator.calculate(
      facts: currentFacts,
      periodStart: current.start,
      periodEnd: current.end,
      commitmentRangeEnd: horizon,
    );
    if (currentFacts.commitments.isNotEmpty) {
      signals.addAll(
        detector.commitments(
          period: current,
          inflow: commitmentMetrics.commitmentInflow.value ?? 0,
          outflow: commitmentMetrics.commitmentOutflow.value ?? 0,
          count: currentFacts.commitments.length,
          commitmentRangeEnd: horizon,
        ),
      );
    }
    for (final source in invoiceSources) {
      if (source.walletId != wallet.id) continue;
      signals.addAll(
        detector.invoice(
          period: current,
          invoiceId: source.invoice.id,
          dueDate: source.invoice.dueDate,
          isPaid: source.invoice.isPaid,
          referenceAt: reference,
        ),
      );
    }
    return List.unmodifiable(signals);
  }
}
