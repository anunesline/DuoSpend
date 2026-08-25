enum FinancialInsightType {
  insufficientData,
  budget,
  projectedBalance,
  goal,
  spendingTrend,
  cardInvoice,
}

enum FinancialInsightSeverity { info, attention, warning }

class FinancialInsight {
  final String id;
  final FinancialInsightType type;
  final FinancialInsightSeverity severity;
  final String title;
  final String message;
  final String source;
  final double? amount;

  const FinancialInsight({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.source,
    this.amount,
  });
}
