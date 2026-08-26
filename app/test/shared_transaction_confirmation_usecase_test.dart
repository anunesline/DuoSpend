import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/transactions/data/repositories/balance_settlement_repository.dart';
import 'package:app/features/transactions/data/repositories/transaction_repository.dart';
import 'package:app/features/transactions/domain/models/shared_transaction_confirmation_status.dart';
import 'package:app/features/transactions/domain/purchase/services/balance_settlement_synchronizer.dart';
import 'package:app/features/transactions/transaction/usecases/accept_shared_transaction_usecase.dart';
import 'package:app/features/transactions/transaction/usecases/reject_shared_transaction_usecase.dart';

void main() {
  MockFirebaseAuth auth(String userId) => MockFirebaseAuth(
        mockUser: MockUser(uid: userId),
        signedIn: true,
      );

  final wallet = WalletModel(
    id: 'shared-wallet',
    name: 'Casa',
    balance: 0,
    type: WalletType.shared,
    ownerId: 'aline',
    memberIds: const ['aline', 'matheus'],
  );

  TransactionModel pendingTransaction() => TransactionModel(
        id: 'transaction-1',
        description: 'Mercado',
        value: 100,
        type: 'expense',
        date: DateTime(2026, 8, 25),
        walletId: wallet.id,
        paidByMemberId: 'aline',
        purchaseFor: 'both',
        splitType: 'equal',
        memberShares: const {'aline': 50, 'matheus': 50},
        confirmationStatus: SharedTransactionConfirmationStatus.pending,
        category: 'Mercado',
        subcategory: 'Geral',
      );

  Future<void> savePending(
    TransactionRepository repository,
    TransactionModel transaction,
  ) {
    return repository.addTransaction(transaction, wallet: wallet);
  }

  test('aceite persiste resposta e bloqueia confirmação duplicada', () async {
    final firestore = FakeFirebaseFirestore();
    final payerRepository = TransactionRepository(
      firestore: firestore,
      auth: auth('aline'),
    );
    final original = pendingTransaction();
    await savePending(payerRepository, original);

    final responderRepository = TransactionRepository(
      firestore: firestore,
      auth: auth('matheus'),
    );
    final accept = AcceptSharedTransactionUseCase(
      transactionRepository: responderRepository,
      settlementSynchronizer: BalanceSettlementSynchronizer(
        transactionRepository: responderRepository,
        settlementRepository: BalanceSettlementRepository(
          firestore: firestore,
          auth: auth('matheus'),
        ),
      ),
    );

    final accepted = await accept(
      transaction: original,
      wallet: wallet,
      respondingMemberId: 'matheus',
    );

    expect(
      accepted.confirmationStatus,
      SharedTransactionConfirmationStatus.accepted,
    );
    expect(accepted.confirmationRespondedByMemberId, 'matheus');
    await expectLater(
      accept(
        transaction: original,
        wallet: wallet,
        respondingMemberId: 'matheus',
      ),
      throwsStateError,
    );
  });

  test('recusa só aceita resposta do outro membro', () async {
    final firestore = FakeFirebaseFirestore();
    final payerRepository = TransactionRepository(
      firestore: firestore,
      auth: auth('aline'),
    );
    final original = pendingTransaction();
    await savePending(payerRepository, original);
    final responderRepository = TransactionRepository(
      firestore: firestore,
      auth: auth('matheus'),
    );
    final reject = RejectSharedTransactionUseCase(
      transactionRepository: responderRepository,
    );

    final rejected = await reject(
      transaction: original,
      wallet: wallet,
      respondingMemberId: 'matheus',
    );

    expect(
      rejected.confirmationStatus,
      SharedTransactionConfirmationStatus.rejected,
    );
    await expectLater(
      reject(
        transaction: original,
        wallet: wallet,
        respondingMemberId: 'matheus',
      ),
      throwsStateError,
    );
  });
}
