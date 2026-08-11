import '../../data/models/transaction_model.dart';
import '../models/recurring_transaction_frequency.dart';

class RecurringTransactionService {
  const RecurringTransactionService();

  /// Retorna a próxima data da recorrência após [currentDate].
  DateTime calculateNextOccurrence({
    required DateTime currentDate,
    required RecurringTransactionFrequency frequency,
  }) {
    switch (frequency) {
      case RecurringTransactionFrequency.daily:
        return DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day + 1,
          currentDate.hour,
          currentDate.minute,
          currentDate.second,
          currentDate.millisecond,
          currentDate.microsecond,
        );

      case RecurringTransactionFrequency.weekly:
        return DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day + 7,
          currentDate.hour,
          currentDate.minute,
          currentDate.second,
          currentDate.millisecond,
          currentDate.microsecond,
        );

      case RecurringTransactionFrequency.monthly:
        return _addOneMonth(currentDate);

      case RecurringTransactionFrequency.yearly:
        return _addOneYear(currentDate);
    }
  }

  /// Retorna verdadeiro quando a recorrência está ativa em [referenceDate].
  bool isActiveOn({
    required TransactionModel transaction,
    required DateTime referenceDate,
  }) {
    if (!transaction.isRecurring) {
      return false;
    }

    final startDate = transaction.recurringStartDate ?? transaction.date;
    final normalizedReferenceDate = _dateOnly(referenceDate);
    final normalizedStartDate = _dateOnly(startDate);

    if (normalizedReferenceDate.isBefore(normalizedStartDate)) {
      return false;
    }

    if (transaction.recurringNeverEnds) {
      return true;
    }

    final endDate = transaction.recurringEndDate;

    if (endDate == null) {
      return false;
    }

    return !normalizedReferenceDate.isAfter(_dateOnly(endDate));
  }

  /// Retorna verdadeiro quando [occurrenceDate] é uma ocorrência válida
  /// para a recorrência informada.
  bool isOccurrenceDate({
    required TransactionModel transaction,
    required DateTime occurrenceDate,
  }) {
    if (!isActiveOn(
      transaction: transaction,
      referenceDate: occurrenceDate,
    )) {
      return false;
    }

    final frequencyValue = transaction.recurringFrequency;

    if (frequencyValue == null || frequencyValue.trim().isEmpty) {
      return false;
    }

    final frequency =
        RecurringTransactionFrequency.fromValue(frequencyValue);
    final startDate = transaction.recurringStartDate ?? transaction.date;

    return _matchesFrequency(
      startDate: startDate,
      targetDate: occurrenceDate,
      frequency: frequency,
    );
  }

  /// Retorna a primeira ocorrência igual ou posterior a [referenceDate].
  ///
  /// Retorna nulo quando a recorrência não está configurada corretamente
  /// ou quando já terminou.
  DateTime? findNextOccurrence({
    required TransactionModel transaction,
    required DateTime referenceDate,
  }) {
    if (!transaction.isRecurring) {
      return null;
    }

    final frequencyValue = transaction.recurringFrequency;

    if (frequencyValue == null || frequencyValue.trim().isEmpty) {
      return null;
    }

    final frequency =
        RecurringTransactionFrequency.fromValue(frequencyValue);
    final startDate = transaction.recurringStartDate ?? transaction.date;
    final normalizedReferenceDate = _dateOnly(referenceDate);
    var occurrence = startDate;

    while (_dateOnly(occurrence).isBefore(normalizedReferenceDate)) {
      occurrence = calculateNextOccurrence(
        currentDate: occurrence,
        frequency: frequency,
      );
    }

    if (!isActiveOn(
      transaction: transaction,
      referenceDate: occurrence,
    )) {
      return null;
    }

    return occurrence;
  }

  /// Gera as datas de ocorrência dentro do intervalo informado.
  ///
  /// O limite evita loops excessivos em recorrências muito antigas
  /// ou sem data de término.
  List<DateTime> generateOccurrences({
    required TransactionModel transaction,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    int limit = 500,
  }) {
    if (limit <= 0 || rangeEnd.isBefore(rangeStart)) {
      return const [];
    }

    final firstOccurrence = findNextOccurrence(
      transaction: transaction,
      referenceDate: rangeStart,
    );

    if (firstOccurrence == null) {
      return const [];
    }

    final frequencyValue = transaction.recurringFrequency;

    if (frequencyValue == null || frequencyValue.trim().isEmpty) {
      return const [];
    }

    final frequency =
        RecurringTransactionFrequency.fromValue(frequencyValue);
    final occurrences = <DateTime>[];
    var currentOccurrence = firstOccurrence;

    while (!currentOccurrence.isAfter(rangeEnd) &&
        occurrences.length < limit) {
      if (!isActiveOn(
        transaction: transaction,
        referenceDate: currentOccurrence,
      )) {
        break;
      }

      occurrences.add(currentOccurrence);

      currentOccurrence = calculateNextOccurrence(
        currentDate: currentOccurrence,
        frequency: frequency,
      );
    }

    return occurrences;
  }

  bool _matchesFrequency({
    required DateTime startDate,
    required DateTime targetDate,
    required RecurringTransactionFrequency frequency,
  }) {
    final normalizedStartDate = _dateOnly(startDate);
    final normalizedTargetDate = _dateOnly(targetDate);

    if (normalizedTargetDate.isBefore(normalizedStartDate)) {
      return false;
    }

    switch (frequency) {
      case RecurringTransactionFrequency.daily:
        return true;

      case RecurringTransactionFrequency.weekly:
        final difference =
            normalizedTargetDate.difference(normalizedStartDate).inDays;

        return difference % 7 == 0;

      case RecurringTransactionFrequency.monthly:
        return normalizedTargetDate.day ==
                _validDayForMonth(
                  year: normalizedTargetDate.year,
                  month: normalizedTargetDate.month,
                  preferredDay: normalizedStartDate.day,
                ) &&
            _monthsBetween(
                  normalizedStartDate,
                  normalizedTargetDate,
                ) >=
                0;

      case RecurringTransactionFrequency.yearly:
        final expectedDay = _validDayForMonth(
          year: normalizedTargetDate.year,
          month: normalizedStartDate.month,
          preferredDay: normalizedStartDate.day,
        );

        return normalizedTargetDate.month ==
                normalizedStartDate.month &&
            normalizedTargetDate.day == expectedDay;
    }
  }

  DateTime _addOneMonth(DateTime date) {
    var nextYear = date.year;
    var nextMonth = date.month + 1;

    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }

    final nextDay = _validDayForMonth(
      year: nextYear,
      month: nextMonth,
      preferredDay: date.day,
    );

    return DateTime(
      nextYear,
      nextMonth,
      nextDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  DateTime _addOneYear(DateTime date) {
    final nextYear = date.year + 1;
    final nextDay = _validDayForMonth(
      year: nextYear,
      month: date.month,
      preferredDay: date.day,
    );

    return DateTime(
      nextYear,
      date.month,
      nextDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  int _validDayForMonth({
    required int year,
    required int month,
    required int preferredDay,
  }) {
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;

    if (preferredDay > lastDayOfMonth) {
      return lastDayOfMonth;
    }

    return preferredDay;
  }

  int _monthsBetween(
    DateTime startDate,
    DateTime endDate,
  ) {
    return (endDate.year - startDate.year) * 12 +
        endDate.month -
        startDate.month;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
