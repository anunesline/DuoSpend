import '../../data/models/transaction_model.dart';

enum FinancialCalendarEntryKind {
  transaction,
  installment,
  recurring,
  creditCardInvoice,
}

class FinancialCalendarEntry {
  final String id;
  final String title;
  final double value;
  final String type;
  final DateTime date;
  final FinancialCalendarEntryKind kind;
  final bool isProjected;
  final TransactionModel? transaction;
  final String? referenceId;

  const FinancialCalendarEntry({
    required this.id,
    required this.title,
    required this.value,
    required this.type,
    required this.date,
    required this.kind,
    required this.isProjected,
    this.transaction,
    this.referenceId,
  });

  /// Identidade determinística que o Calendário já usa para cada ocorrência.
  /// Também serve como ID da transação materializada ao efetivá-la.
  static String recurringOccurrenceId({
    required String templateId,
    required DateTime occurrenceDate,
  }) => '$templateId-${occurrenceDate.toIso8601String()}';

  bool get isIncome => type == 'income';

  bool get isExpense => type == 'expense';

  double get signedValue => isIncome ? value : -value;

  String get financialStatusLabel => isProjected ? 'Prevista' : 'Efetivada';
}
