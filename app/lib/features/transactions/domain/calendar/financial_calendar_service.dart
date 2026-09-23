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
    final materializedOccurrences = _materializedRecurringOccurrences(
      transactions,
    );

    for (final transaction in transactions) {
      if (transaction.isRecurring) {
        _addRecurringEntries(
          entries: entries,
          transaction: transaction,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          referenceDate: referenceDate,
          materializedOccurrences: materializedOccurrences,
        );
        continue;
      }

      if (_isInRange(transaction.date, rangeStart, rangeEnd) ||
          _isOverduePendingOutsideRange(
            isPending: transaction.isFinanciallyPending,
            date: transaction.date,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            referenceDate: referenceDate,
          )) {
        entries.add(_entryFromTransaction(transaction, referenceDate));
      }
    }

    for (final invoice in invoices) {
      if (invoice.isPaid ||
          (!_isInRange(invoice.dueDate, rangeStart, rangeEnd) &&
              !_isOverduePendingOutsideRange(
                isPending: true,
                date: invoice.dueDate,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd,
                referenceDate: referenceDate,
              ))) {
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
          status: _statusFor(
            date: invoice.dueDate,
            isProjected: true,
            referenceDate: referenceDate,
          ),
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
      projectedBalance: currentBalance + projectedIncome - projectedExpense,
      entries: List<FinancialCalendarEntry>.unmodifiable(entries),
    );
  }

  void _addRecurringEntries({
    required List<FinancialCalendarEntry> entries,
    required TransactionModel transaction,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required DateTime referenceDate,
    required Set<String> materializedOccurrences,
  }) {
    final occurrences = _recurringService.generateOccurrences(
      transaction: transaction,
      // Keep every unresolved occurrence available until materialization. The
      // recurrence generator already caps the result, so an old open series
      // cannot loop without bound.
      rangeStart: transaction.recurringStartDate ?? transaction.date,
      rangeEnd: rangeEnd,
    );

    for (final occurrence in occurrences) {
      final occurrenceId = FinancialCalendarEntry.recurringOccurrenceId(
        templateId: transaction.id,
        occurrenceDate: occurrence,
      );
      if (materializedOccurrences.contains(occurrenceId)) {
        continue;
      }
      final normalizedOccurrence = _dateOnly(occurrence);
      final firstOccurrenceDate =
          transaction.recurringStartDate ?? transaction.date;
      final isOriginalOccurrence = normalizedOccurrence.isAtSameMomentAs(
        _dateOnly(firstOccurrenceDate),
      );
      // A materialized occurrence is the only proof that a generated
      // recurrence has already affected the real balance. A missed occurrence
      // remains pending and becomes overdue; time alone cannot remove it.
      final isProjected = isOriginalOccurrence
          ? transaction.isFinanciallyPending
          : true;

      entries.add(
        FinancialCalendarEntry(
          id: occurrenceId,
          title: transaction.description,
          value: transaction.value,
          type: transaction.type,
          date: occurrence,
          kind: FinancialCalendarEntryKind.recurring,
          isProjected: isProjected,
          status: _statusFor(
            date: occurrence,
            isProjected: isProjected,
            referenceDate: referenceDate,
          ),
          transaction: transaction,
          referenceId: transaction.recurringId ?? transaction.id,
        ),
      );
    }
  }

  Set<String> _materializedRecurringOccurrences(
    List<TransactionModel> transactions,
  ) {
    final result = <String>{};
    for (final transaction in transactions) {
      if (transaction.isRecurring) {
        continue;
      }
      final recurringId = transaction.recurringId?.trim();
      if (recurringId == null || recurringId.isEmpty) {
        continue;
      }
      result.add(transaction.id);
    }
    return result;
  }

  FinancialCalendarEntry _entryFromTransaction(
    TransactionModel transaction,
    DateTime referenceDate,
  ) {
    final isCreditCard = transaction.paymentMethod == 'creditCard';
    final isProjected = !isCreditCard && transaction.isFinanciallyPending;

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
      status: _statusFor(
        date: transaction.date,
        isProjected: isProjected,
        referenceDate: referenceDate,
      ),
      transaction: transaction,
      referenceId: transaction.installmentGroupId,
    );
  }

  bool _isInRange(DateTime date, DateTime rangeStart, DateTime rangeEnd) {
    final normalizedDate = _dateOnly(date);
    return !normalizedDate.isBefore(_dateOnly(rangeStart)) &&
        !normalizedDate.isAfter(_dateOnly(rangeEnd));
  }

  bool _isOverduePendingOutsideRange({
    required bool isPending,
    required DateTime date,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required DateTime referenceDate,
  }) {
    final normalizedDate = _dateOnly(date);
    return isPending &&
        !rangeEnd.isBefore(referenceDate) &&
        normalizedDate.isBefore(_dateOnly(rangeStart)) &&
        normalizedDate.isBefore(referenceDate);
  }

  FinancialCalendarEntryStatus _statusFor({
    required DateTime date,
    required bool isProjected,
    required DateTime referenceDate,
  }) {
    if (!isProjected) return FinancialCalendarEntryStatus.settled;
    return _dateOnly(date).isBefore(referenceDate)
        ? FinancialCalendarEntryStatus.overdue
        : FinancialCalendarEntryStatus.forecast;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
