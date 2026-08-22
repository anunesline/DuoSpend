import '../../data/models/transaction_model.dart';
import '../models/recurring_transaction_frequency.dart';
import '../services/recurring_transaction_service.dart';

class CreateRecurringTransactionUseCase {
  final RecurringTransactionService _recurringService;

  CreateRecurringTransactionUseCase({
    required RecurringTransactionService recurringService,
  }) : _recurringService = recurringService;

  TransactionModel execute(
    TransactionModel transaction,
  ) {
    if (!transaction.isRecurring) {
      return transaction;
    }

    final frequencyValue = transaction.recurringFrequency;

    if (frequencyValue == null ||
        frequencyValue.trim().isEmpty) {
      throw Exception(
        'A frequência da recorrência é obrigatória.',
      );
    }

    final frequency =
        RecurringTransactionFrequency.fromValue(
      frequencyValue,
    );

    final startDate =
        transaction.recurringStartDate ?? transaction.date;

    final endDate = transaction.recurringEndDate;

    if (!transaction.recurringNeverEnds &&
        endDate == null) {
      throw Exception(
        'Informe a data final ou marque "Nunca expira".',
      );
    }

    if (endDate != null &&
        endDate.isBefore(startDate)) {
      throw Exception(
        'A data final deve ser igual ou posterior à data inicial.',
      );
    }

    final normalizedTransaction = transaction.copyWith(
      recurringId: transaction.recurringId ?? transaction.id,
      recurringFrequency: frequency.value,
      recurringStartDate: startDate,
      recurringEndDate: transaction.recurringNeverEnds
          ? null
          : endDate,
      clearRecurringEndDate: transaction.recurringNeverEnds,
      recurringNeverEnds: transaction.recurringNeverEnds,
      isRecurring: true,
    );

    final firstOccurrence =
        _recurringService.findNextOccurrence(
      transaction: normalizedTransaction,
      referenceDate: startDate,
    );

    if (firstOccurrence == null) {
      throw Exception(
        'Não foi possível gerar a primeira ocorrência.',
      );
    }

    return normalizedTransaction;
  }
}
