import '../../data/repositories/transaction_repository.dart';
import '../../../home/data/models/wallet_model.dart';

class DeleteRecurringSeriesUseCase {
  final TransactionRepository _repository;

  DeleteRecurringSeriesUseCase({
    required TransactionRepository repository,
  }) : _repository = repository;

  Future<void> execute({
    required String recurringId,
    required String walletId,
    WalletModel? wallet,
  }) async {
    final normalizedRecurringId = recurringId.trim();
    final normalizedWalletId = walletId.trim();

    if (normalizedRecurringId.isEmpty) {
      throw ArgumentError.value(
        recurringId,
        'recurringId',
        'O ID da recorrência não pode ficar vazio.',
      );
    }

    if (normalizedWalletId.isEmpty) {
      throw ArgumentError.value(
        walletId,
        'walletId',
        'O ID da carteira não pode ficar vazio.',
      );
    }

    await _repository.deleteRecurringSeries(
      recurringId: normalizedRecurringId,
      walletId: normalizedWalletId,
      wallet: wallet,
    );
  }
}