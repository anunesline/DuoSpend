import '../../../home/data/models/credit_card_invoice_model.dart';
import '../../data/models/transaction_model.dart';
import '../services/recurring_transaction_service.dart';
import 'financial_calendar_entry.dart';
import 'financial_projection.dart';

class FinancialCalendarService {
  final RecurringTransactionService _recurringService;

  const FinancialCalendarService({
    RecurringTransactionService recurringService =
        const RecurringTransactionService(),
  }) : _recurringService = recurringService;

  FinancialProjection buildProjection({
    required double currentBalance,
    required List<TransactionModel> transactions,
    required List<CreditCardInvoiceModel> invoices,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    DateTime? now,
  }) {
    if (rangeEnd.isBefore(rangeStart)) {
      throw ArgumentError('O período financeiro informado é inválido.');
    }

    final referenceDate = _dateOnly(now ?? DateTime.now());
    final entries = <FinancialCalendarEntry>[];

    for (final transaction in transactions) {
      if (transaction.isRecurring) {
        _addRecurringEntries(
          entries: entries,
          transaction: transaction,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          referenceDate: referenceDate,
        );
        continue;
      }

      if (_isInRange(transaction.date, rangeStart, rangeEnd)) {
        entries.add(
          _entryFromTransaction(transaction),
        );
      }
    }

    for (final invoice in invoices) {
      if (invoice.isPaid ||
          !_isInRange(invoice.dueDate, rangeStart, rangeEnd)) {
        continue;
      }

      entries.add(
        FinancialCalendarEntry(
          id: 'invoice-${invoice.cardId}-${invoice.id}',
          title: 'Fatura do cartão',
          value: invoice.total,
          type: 'expense',
          date: invoice.dueDate,
          kind: FinancialCalendarEntryKind.creditCardInvoice,
          isProjected: true,
          referenceId: invoice.cardId,
        ),
      );
    }

    entries.sort((first, second) {
      final dateComparison = first.date.compareTo(second.date);
      if (dateComparison != 0) {
        return dateComparison;
      }
      return first.title.compareTo(second.title);
    });

    var projectedIncome = 0.0;
    var projectedExpense = 0.0;

    for (final entry in entries.where((entry) => entry.isProjected)) {
      if (entry.isIncome) {
        projectedIncome += entry.value;
      } else if (entry.isExpense) {
        projectedExpense += entry.value;
      }
    }

    return FinancialProjection(
      currentBalance: currentBalance,
      projectedIncome: projectedIncome,
      projectedExpense: projectedExpense,
      projectedBalance:
          currentBalance + projectedIncome - projectedExpense,
      entries: List<FinancialCalendarEntry>.unmodifiable(entries),
    );
  }

  void _addRecurringEntries({
    required List<FinancialCalendarEntry> entries,
    required TransactionModel transaction,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required DateTime referenceDate,
  }) {
    final occurrences = _recurringService.generateOccurrences(
      transaction: transaction,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );

    for (final occurrence in occurrences) {
      final normalizedOccurrence = _dateOnly(occurrence);
      final firstOccurrenceDate =
          transaction.recurringStartDate ?? transaction.date;
      final isOriginalOccurrence = normalizedOccurrence
          .isAtSameMomentAs(_dateOnly(firstOccurrenceDate));
      final isProjected = normalizedOccurrence.isAfter(referenceDate) ||
          (isOriginalOccurrence &&
              transaction.isFinanciallyPending);

      entries.add(
        FinancialCalendarEntry(
          id: '${transaction.id}-${occurrence.toIso8601String()}',
          title: transaction.description,
          value: transaction.value,
          type: transaction.type,
          date: occurrence,
          kind: FinancialCalendarEntryKind.recurring,
          isProjected: isProjected,
          transaction: isOriginalOccurrence ? transaction : null,
          referenceId: transaction.recurringId ?? transaction.id,
        ),
      );
    }
  }

  FinancialCalendarEntry _entryFromTransaction(
    TransactionModel transaction,
  ) {
    final isCreditCard = transaction.paymentMethod == 'creditCard';
    final isProjected = !isCreditCard &&
        transaction.isFinanciallyPending;

    return FinancialCalendarEntry(
      id: transaction.id,
      title: transaction.description,
      value: transaction.value,
      type: transaction.type,
      date: transaction.date,
      kind: transaction.isInstallment
          ? FinancialCalendarEntryKind.installment
          : FinancialCalendarEntryKind.transaction,
      isProjected: isProjected,
      transaction: transaction,
      referenceId: transaction.installmentGroupId,
    );
  }

  bool _isInRange(
    DateTime date,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final normalizedDate = _dateOnly(date);
    return !normalizedDate.isBefore(_dateOnly(rangeStart)) &&
        !normalizedDate.isAfter(_dateOnly(rangeEnd));
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
