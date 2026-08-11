import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../models/recurring_transaction_frequency.dart';
import '../services/recurring_transaction_service.dart';

class UpdateRecurringTransactionUseCase {
  final TransactionRepository _repository;
  final RecurringTransactionService _recurringService;

  UpdateRecurringTransactionUseCase({
    required TransactionRepository repository,
    required RecurringTransactionService recurringService,
  })  : _repository = repository,
        _recurringService = recurringService;

  Future<TransactionModel> execute(
    TransactionModel transaction,
  ) async {
    if (!transaction.isRecurring) {
      throw Exception(
        'A transação informada não é recorrente.',
      );
    }

    final recurringId = transaction.recurringId?.trim();

    if (recurringId == null || recurringId.isEmpty) {
      throw Exception(
        'A recorrência precisa possuir um recurringId.',
      );
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
        'Informe uma data final ou marque "Nunca expira".',
      );
    }

    if (endDate != null &&
        endDate.isBefore(startDate)) {
      throw Exception(
        'A data final deve ser igual ou posterior à inicial.',
      );
    }

    final normalizedTransaction = transaction.copyWith(
      recurringFrequency: frequency.value,
      recurringStartDate: startDate,
      recurringEndDate:
          transaction.recurringNeverEnds
              ? null
              : endDate,
      recurringNeverEnds:
          transaction.recurringNeverEnds,
      isRecurring: true,
    );

    final nextOccurrence =
        _recurringService.findNextOccurrence(
      transaction: normalizedTransaction,
      referenceDate: startDate,
    );

    if (nextOccurrence == null) {
      throw Exception(
        'A recorrência tornou-se inválida após a atualização.',
      );
    }

    await _repository.updateRecurringTransaction(
      normalizedTransaction,
    );

    return normalizedTransaction;
  }
}