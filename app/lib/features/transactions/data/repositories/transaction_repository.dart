import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../home/data/models/wallet_model.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TransactionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> addTransaction(
    TransactionModel transaction, {
    WalletModel? wallet,
  }) async {
    final user = _requireAuthenticatedUser();

    if (wallet == null || !wallet.isShared) {
      await _individualTransactionsReference(user.uid)
          .doc(transaction.id)
          .set(transaction.toMap());

      return;
    }

    _validateSharedWalletAccess(
      wallet: wallet,
      userId: user.uid,
    );

    if (transaction.walletId.trim() != wallet.id.trim()) {
      throw Exception(
        'A transação não pertence à carteira compartilhada informada.',
      );
    }

    await _sharedTransactionsReference(wallet.id)
        .doc(transaction.id)
        .set(transaction.toMap());
  }

  Future<void> updateTransaction(
    TransactionModel transaction, {
    WalletModel? wallet,
  }) async {
    final user = _requireAuthenticatedUser();

    if (wallet == null || !wallet.isShared) {
      await _individualTransactionsReference(user.uid)
          .doc(transaction.id)
          .update(transaction.toMap());

      return;
    }

    _validateSharedWalletAccess(
      wallet: wallet,
      userId: user.uid,
    );

    if (transaction.walletId.trim() != wallet.id.trim()) {
      throw Exception(
        'A transação não pertence à carteira compartilhada informada.',
      );
    }

    await _sharedTransactionsReference(wallet.id)
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactions() async {
    final user = _auth.currentUser;

    if (user == null) {
      return [];
    }

    return _getTransactionsFromReference(
      _individualTransactionsReference(user.uid),
    );
  }

  Future<List<TransactionModel>> getTransactionsByWallet(
    String walletId, {
    WalletModel? wallet,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return [];
    }

    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      return [];
    }

    if (wallet != null && wallet.isShared) {
      _validateSharedWalletAccess(
        wallet: wallet,
        userId: user.uid,
      );

      if (wallet.id.trim() != normalizedWalletId) {
        throw Exception(
          'A carteira informada não corresponde ao walletId solicitado.',
        );
      }

      return _getTransactionsFromReference(
        _sharedTransactionsReference(normalizedWalletId),
      );
    }

    final transactions = await getTransactions();

    return List<TransactionModel>.unmodifiable(
      transactions.where(
        (transaction) =>
            transaction.walletId.trim() == normalizedWalletId,
      ),
    );
  }

  /// Retorna todas as transações recorrentes do usuário autenticado.
  Future<List<TransactionModel>> getRecurringTransactions() async {
    final transactions = await getTransactions();

    return List<TransactionModel>.unmodifiable(
      transactions.where(
        (transaction) => transaction.isRecurring,
      ),
    );
  }

  /// Retorna as transações recorrentes de uma carteira específica.
  Future<List<TransactionModel>> getRecurringTransactionsByWallet(
    String walletId, {
    WalletModel? wallet,
  }) async {
    final transactions = await getTransactionsByWallet(
      walletId,
      wallet: wallet,
    );

    return List<TransactionModel>.unmodifiable(
      transactions.where(
        (transaction) => transaction.isRecurring,
      ),
    );
  }

  /// Busca todas as transações pertencentes a uma série recorrente.
  Future<List<TransactionModel>> getTransactionsByRecurringId(
    String recurringId, {
    String? walletId,
    WalletModel? wallet,
  }) async {
    final normalizedRecurringId = recurringId.trim();

    if (normalizedRecurringId.isEmpty) {
      throw ArgumentError.value(
        recurringId,
        'recurringId',
        'O ID da recorrência não pode ficar vazio.',
      );
    }

    final transactions = walletId == null
        ? await getTransactions()
        : await getTransactionsByWallet(
            walletId,
            wallet: wallet,
          );

    return List<TransactionModel>.unmodifiable(
      transactions.where(
        (transaction) =>
            transaction.recurringId?.trim() ==
            normalizedRecurringId,
      ),
    );
  }

  /// Atualiza uma transação recorrente existente.
  Future<void> updateRecurringTransaction(
    TransactionModel transaction, {
    WalletModel? wallet,
  }) async {
    if (!transaction.isRecurring) {
      throw ArgumentError(
        'A transação informada não está marcada como recorrente.',
      );
    }

    final recurringId = transaction.recurringId?.trim();

    if (recurringId == null || recurringId.isEmpty) {
      throw ArgumentError(
        'A transação recorrente precisa possuir um recurringId.',
      );
    }

    await updateTransaction(
      transaction,
      wallet: wallet,
    );
  }

  /// Exclui todas as transações pertencentes a uma série recorrente.
  Future<void> deleteRecurringSeries({
    required String recurringId,
    required String walletId,
    WalletModel? wallet,
  }) async {
    final user = _requireAuthenticatedUser();
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

    late CollectionReference<Map<String, dynamic>> reference;

    if (wallet != null && wallet.isShared) {
      _validateSharedWalletAccess(
        wallet: wallet,
        userId: user.uid,
      );

      if (wallet.id.trim() != normalizedWalletId) {
        throw Exception(
          'A carteira informada não corresponde ao walletId solicitado.',
        );
      }

      reference = _sharedTransactionsReference(
        normalizedWalletId,
      );
    } else {
      reference = _individualTransactionsReference(user.uid);
    }

    final snapshot = await reference
        .where(
          'recurringId',
          isEqualTo: normalizedRecurringId,
        )
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }

    await batch.commit();
  }

  /// Procura a transação criada para representar
  /// o pagamento de um acerto financeiro.
  ///
  /// Retorna null quando ainda não existe uma transação
  /// vinculada ao settlement informado.
  Future<TransactionModel?> findSettlementTransaction({
    required String walletId,
    required String settlementId,
    WalletModel? wallet,
  }) async {
    final normalizedWalletId = walletId.trim();
    final normalizedSettlementId = settlementId.trim();

    if (normalizedWalletId.isEmpty) {
      throw ArgumentError.value(
        walletId,
        'walletId',
        'O ID da carteira não pode ficar vazio.',
      );
    }

    if (normalizedSettlementId.isEmpty) {
      throw ArgumentError.value(
        settlementId,
        'settlementId',
        'O ID do acerto não pode ficar vazio.',
      );
    }

    final transactions = await getTransactionsByWallet(
      normalizedWalletId,
      wallet: wallet,
    );

    for (final transaction in transactions) {
      if (!transaction.isSettlement) {
        continue;
      }

      if (transaction.settlementId?.trim() ==
          normalizedSettlementId) {
        return transaction;
      }
    }

    return null;
  }

  /// Informa se o acerto já possui uma transação
  /// registrada no histórico financeiro.
  Future<bool> settlementTransactionExists({
    required String walletId,
    required String settlementId,
    WalletModel? wallet,
  }) async {
    final transaction = await findSettlementTransaction(
      walletId: walletId,
      settlementId: settlementId,
      wallet: wallet,
    );

    return transaction != null;
  }

  Future<List<TransactionModel>> _getTransactionsFromReference(
    CollectionReference<Map<String, dynamic>> reference,
  ) async {
    final snapshot = await reference
        .orderBy(
          'date',
          descending: true,
        )
        .get();

    return List<TransactionModel>.unmodifiable(
      snapshot.docs.map(
        (document) => TransactionModel.fromMap(
          document.data(),
        ),
      ),
    );
  }

  CollectionReference<Map<String, dynamic>>
      _individualTransactionsReference(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');
  }

  CollectionReference<Map<String, dynamic>>
      _sharedTransactionsReference(
    String walletId,
  ) {
    return _firestore
        .collection('wallets')
        .doc(walletId)
        .collection('transactions');
  }

  void _validateSharedWalletAccess({
    required WalletModel wallet,
    required String userId,
  }) {
    if (!wallet.isShared) {
      throw Exception(
        'A carteira informada não é compartilhada.',
      );
    }

    if (!wallet.memberIds.contains(userId)) {
      throw Exception(
        'O usuário não pertence à carteira compartilhada.',
      );
    }
  }

  User _requireAuthenticatedUser() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    return user;
  }
}
