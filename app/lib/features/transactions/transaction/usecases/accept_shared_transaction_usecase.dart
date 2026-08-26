import '../../../home/data/models/wallet_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/models/shared_transaction_confirmation_status.dart';
import '../../domain/purchase/services/balance_settlement_synchronizer.dart';

class AcceptSharedTransactionUseCase {
  final TransactionRepository _transactionRepository;
  final BalanceSettlementSynchronizer _settlementSynchronizer;

  const AcceptSharedTransactionUseCase({
    required TransactionRepository transactionRepository,
    required BalanceSettlementSynchronizer settlementSynchronizer,
  })  : _transactionRepository = transactionRepository,
        _settlementSynchronizer = settlementSynchronizer;

  Future<TransactionModel> call({
    required TransactionModel transaction,
    required WalletModel wallet,
    required String respondingMemberId,
  }) async {
    final normalizedRespondingMemberId =
        respondingMemberId.trim();

    final persistedTransaction = await _getPersistedTransaction(
      transaction: transaction,
      wallet: wallet,
    );

    _validate(
      transaction: persistedTransaction,
      wallet: wallet,
      respondingMemberId: normalizedRespondingMemberId,
    );

    if (persistedTransaction.confirmationStatus.isAccepted) {
      return persistedTransaction;
    }

    if (persistedTransaction.confirmationStatus.isRejected) {
      throw StateError(
        'A despesa compartilhada já foi recusada e não pode ser aceita.',
      );
    }

    final acceptedTransaction = persistedTransaction.copyWith(
      confirmationStatus:
          SharedTransactionConfirmationStatus.accepted,
      confirmationResolvedAt: DateTime.now(),
      confirmationRespondedByMemberId:
          normalizedRespondingMemberId,
    );

    await _transactionRepository.updateTransaction(
      acceptedTransaction,
      wallet: wallet,
    );

    await _settlementSynchronizer.synchronize(
      walletId: wallet.id,
    );

    return acceptedTransaction;
  }


  Future<TransactionModel> _getPersistedTransaction({
    required TransactionModel transaction,
    required WalletModel wallet,
  }) async {
    final transactions = await _transactionRepository
        .getTransactionsByWallet(wallet.id, wallet: wallet);

    for (final persistedTransaction in transactions) {
      if (persistedTransaction.id == transaction.id) {
        return persistedTransaction;
      }
    }

    throw StateError('A transação compartilhada não foi encontrada.');
  }

  void _validate({
    required TransactionModel transaction,
    required WalletModel wallet,
    required String respondingMemberId,
  }) {
    if (!wallet.isShared) {
      throw StateError(
        'A confirmação bilateral exige uma carteira compartilhada.',
      );
    }

    if (transaction.walletId.trim() != wallet.id.trim()) {
      throw StateError(
        'A transação não pertence à carteira compartilhada informada.',
      );
    }

    if (respondingMemberId.isEmpty) {
      throw StateError(
        'O membro responsável pela confirmação não foi informado.',
      );
    }

    if (!wallet.memberIds.contains(respondingMemberId)) {
      throw StateError(
        'O membro informado não pertence à carteira compartilhada.',
      );
    }

    if (!transaction.isSharedExpense) {
      throw StateError(
        'Somente despesas compartilhadas podem ser confirmadas.',
      );
    }

    final payerMemberId = transaction.paidByMemberId?.trim();

    if (payerMemberId == null || payerMemberId.isEmpty) {
      throw StateError(
        'Não foi possível identificar o autor da despesa compartilhada.',
      );
    }

    if (payerMemberId == respondingMemberId) {
      throw StateError(
        'O autor da despesa não pode confirmar a própria solicitação.',
      );
    }
  }
}