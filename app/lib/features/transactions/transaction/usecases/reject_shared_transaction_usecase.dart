import '../../../home/data/models/wallet_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/models/shared_transaction_confirmation_status.dart';

class RejectSharedTransactionUseCase {
  final TransactionRepository _transactionRepository;

  const RejectSharedTransactionUseCase({
    required TransactionRepository transactionRepository,
  }) : _transactionRepository = transactionRepository;

  Future<TransactionModel> call({
    required TransactionModel transaction,
    required WalletModel wallet,
    required String respondingMemberId,
  }) async {
    final normalizedRespondingMemberId =
        respondingMemberId.trim();

    _validate(
      transaction: transaction,
      wallet: wallet,
      respondingMemberId: normalizedRespondingMemberId,
    );

    final rejectedTransaction = transaction.copyWith(
      confirmationStatus:
          SharedTransactionConfirmationStatus.rejected,
      confirmationResolvedAt: DateTime.now(),
      confirmationRespondedByMemberId:
          normalizedRespondingMemberId,
    );

    await _transactionRepository.updateTransaction(
      rejectedTransaction,
      wallet: wallet,
    );

    return rejectedTransaction;
  }

  void _validate({
    required TransactionModel transaction,
    required WalletModel wallet,
    required String respondingMemberId,
  }) {
    if (!wallet.isShared) {
      throw Exception(
        'A confirmação bilateral exige uma carteira compartilhada.',
      );
    }

    if (transaction.walletId.trim() != wallet.id.trim()) {
      throw Exception(
        'A transação não pertence à carteira compartilhada informada.',
      );
    }

    if (respondingMemberId.isEmpty) {
      throw Exception(
        'O membro responsável pela recusa não foi informado.',
      );
    }

    if (!wallet.memberIds.contains(respondingMemberId)) {
      throw Exception(
        'O membro informado não pertence à carteira compartilhada.',
      );
    }

    if (!transaction.isSharedExpense) {
      throw Exception(
        'Somente despesas compartilhadas podem ser recusadas.',
      );
    }

    if (!transaction.confirmationStatus.isPending) {
      throw Exception(
        'A despesa compartilhada não está aguardando confirmação.',
      );
    }

    final payerMemberId = transaction.paidByMemberId?.trim();

    if (payerMemberId == null || payerMemberId.isEmpty) {
      throw Exception(
        'Não foi possível identificar o autor da despesa compartilhada.',
      );
    }

    if (payerMemberId == respondingMemberId) {
      throw Exception(
        'O autor da despesa não pode recusar a própria solicitação.',
      );
    }
  }
}