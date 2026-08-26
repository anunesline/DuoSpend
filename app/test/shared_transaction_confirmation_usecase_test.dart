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

  Future<TransactionRepository> pendingRepository(
    FakeFirebaseFirestore firestore,
  ) async {
    final payerRepository = TransactionRepository(
      firestore: firestore,
      auth: auth('aline'),
    );
    await payerRepository.addTransaction(
      pendingTransaction(),
      wallet: wallet,
    );
    return TransactionRepository(
      firestore: firestore,
      auth: auth('matheus'),
    );
  }

  AcceptSharedTransactionUseCase acceptUseCase(
    FakeFirebaseFirestore firestore,
    TransactionRepository repository,
  ) {
    return AcceptSharedTransactionUseCase(
      transactionRepository: repository,
      settlementSynchronizer: BalanceSettlementSynchronizer(
        transactionRepository: repository,
        settlementRepository: BalanceSettlementRepository(
          firestore: firestore,
          auth: auth('matheus'),
        ),
      ),
    );
  }

  test('repetir aceite preserva a decisão persistida', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = await pendingRepository(firestore);
    final accept = acceptUseCase(firestore, repository);
    final original = pendingTransaction();

    final accepted = await accept(
      transaction: original,
      wallet: wallet,
      respondingMemberId: 'matheus',
    );
    final repeated = await accept(
      transaction: original,
      wallet: wallet,
      respondingMemberId: 'matheus',
    );

    expect(repeated.confirmationStatus, accepted.confirmationStatus);
    expect(
      repeated.confirmationResolvedAt,
      accepted.confirmationResolvedAt,
    );
    expect(
      repeated.confirmationRespondedByMemberId,
      accepted.confirmationRespondedByMemberId,
    );
  });

  test('decisão oposta após aceite é bloqueada', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = await pendingRepository(firestore);
    final original = pendingTransaction();
    final accept = acceptUseCase(firestore, repository);
    final reject = RejectSharedTransactionUseCase(
      transactionRepository: repository,
    );

    await accept(
      transaction: original,
      wallet: wallet,
      respondingMemberId: 'matheus',
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

  test('membro inválido não pode responder à confirmação', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = await pendingRepository(firestore);
    final reject = RejectSharedTransactionUseCase(
      transactionRepository: repository,
    );

    await expectLater(
      reject(
        transaction: pendingTransaction(),
        wallet: wallet,
        respondingMemberId: 'externo',
      ),
      throwsStateError,
    );
  });
}
