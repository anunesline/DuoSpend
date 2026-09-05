import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../home/data/models/credit_card_invoice_model.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../home/data/repositories/wallet_repository.dart';
import '../../data/models/transaction_model.dart';
import '../purchase/services/balance_settlement_synchronizer.dart';

class TransactionMaintenanceService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final WalletRepository _walletRepository;
  final BalanceSettlementSynchronizer _settlementSynchronizer;

  TransactionMaintenanceService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    WalletRepository? walletRepository,
    BalanceSettlementSynchronizer? settlementSynchronizer,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _walletRepository = walletRepository ?? WalletRepository(),
        _settlementSynchronizer =
            settlementSynchronizer ?? BalanceSettlementSynchronizer();

  Future<TransactionModel> updateTransaction({
    required TransactionModel original,
    required String description,
    required double value,
    required DateTime date,
    required String category,
    required String subcategory,
    String? notes,
  }) async {
    final userId = _requireUserId();
    final wallet = await _requireTransactionWallet(original.walletId);
    _validateCanManage(original, wallet, userId);

    final normalizedDescription = description.trim();
    final normalizedCategory = category.trim();
    final normalizedSubcategory = subcategory.trim();
    if (normalizedDescription.isEmpty) {
      throw ArgumentError('A descrição não pode ficar vazia.');
    }
    if (!value.isFinite || value <= 0) {
      throw ArgumentError('O valor precisa ser maior que zero.');
    }

    final valueChanged = !_sameAmount(original.value, value);
    final dateChanged = !_sameMoment(original.date, date);

    if (original.paymentMethod == 'creditCard' &&
        (valueChanged || dateChanged)) {
      throw StateError(
        'Em compras no crédito, valor e data pertencem à fatura. '
        'Você pode editar descrição, categoria e observações.',
      );
    }

    if (original.hasFinancialSplit && valueChanged) {
      throw StateError(
        'Altere a divisão financeira recriando o lançamento. '
        'Descrição, categoria, data e observações continuam editáveis.',
      );
    }

    final updated = original.copyWith(
      description: normalizedDescription,
      value: value,
      date: date,
      category: normalizedCategory.isEmpty ? original.category : normalizedCategory,
      subcategory: normalizedSubcategory.isEmpty
          ? original.subcategory
          : normalizedSubcategory,
      notes: notes?.trim(),
    );

    final transactionReference = _transactionReference(
      userId: userId,
      wallet: wallet,
      transactionId: original.id,
    );

    if (!valueChanged || !original.isFinanciallySettled) {
      await transactionReference.update(updated.toMap());
      return updated;
    }

    final financialWallet = await _resolveFinancialWallet(original);
    final financialReference = _financialWalletReference(
      userId: userId,
      walletId: financialWallet.id,
    );
    final balanceDelta = _balanceEffect(updated) - _balanceEffect(original);

    await _firestore.runTransaction((firestoreTransaction) async {
      final persistedDocument = await firestoreTransaction.get(
        transactionReference,
      );
      if (!persistedDocument.exists || persistedDocument.data() == null) {
        throw StateError('Transação não encontrada.');
      }
      final persisted = TransactionModel.fromMap(persistedDocument.data()!);
      if (!_sameAmount(persisted.value, original.value)) {
        throw StateError('A transação mudou. Atualize a tela e tente novamente.');
      }

      firestoreTransaction.update(transactionReference, updated.toMap());
      if (balanceDelta.abs() >= 0.005) {
        firestoreTransaction.update(financialReference, {
          'balance': FieldValue.increment(balanceDelta),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    });

    return updated;
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    final userId = _requireUserId();
    final wallet = await _requireTransactionWallet(transaction.walletId);
    _validateCanManage(transaction, wallet, userId);

    if (transaction.isSettlement) {
      throw StateError(
        'Acertos financeiros não podem ser excluídos como uma transação comum.',
      );
    }

    if (transaction.paymentMethod == 'creditCard') {
      await _deleteCreditCardPurchase(
        transaction: transaction,
        wallet: wallet,
        userId: userId,
      );
    } else {
      await _deleteRegularTransaction(
        transaction: transaction,
        wallet: wallet,
        userId: userId,
      );
    }

    if (wallet.isShared) {
      await _settlementSynchronizer.synchronize(walletId: wallet.id);
    }
  }

  Future<void> _deleteRegularTransaction({
    required TransactionModel transaction,
    required WalletModel wallet,
    required String userId,
  }) async {
    final transactionReference = _transactionReference(
      userId: userId,
      wallet: wallet,
      transactionId: transaction.id,
    );

    if (!transaction.isFinanciallySettled) {
      await transactionReference.delete();
      return;
    }

    final financialWallet = await _resolveFinancialWallet(transaction);
    final financialReference = _financialWalletReference(
      userId: userId,
      walletId: financialWallet.id,
    );
    final reversal = -_balanceEffect(transaction);

    await _firestore.runTransaction((firestoreTransaction) async {
      final persistedDocument = await firestoreTransaction.get(
        transactionReference,
      );
      if (!persistedDocument.exists || persistedDocument.data() == null) {
        return;
      }
      firestoreTransaction.delete(transactionReference);
      firestoreTransaction.update(financialReference, {
        'balance': FieldValue.increment(reversal),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> _deleteCreditCardPurchase({
    required TransactionModel transaction,
    required WalletModel wallet,
    required String userId,
  }) async {
    final cardId = transaction.paymentSourceId?.trim();
    if (cardId == null || cardId.isEmpty) {
      throw StateError('A compra não possui um cartão de origem válido.');
    }

    final cardReference = _firestore.collection('creditCards').doc(cardId);
    final chargeReference = cardReference
        .collection('charges')
        .doc(transaction.id);
    final transactionReference = _transactionReference(
      userId: userId,
      wallet: wallet,
      transactionId: transaction.id,
    );

    await _firestore.runTransaction((firestoreTransaction) async {
      final cardDocument = await firestoreTransaction.get(cardReference);
      final chargeDocument = await firestoreTransaction.get(chargeReference);
      final transactionDocument = await firestoreTransaction.get(
        transactionReference,
      );

      if (!transactionDocument.exists || transactionDocument.data() == null) {
        return;
      }
      if (!cardDocument.exists || cardDocument.data() == null) {
        throw StateError('Cartão não encontrado.');
      }
      if (!chargeDocument.exists || chargeDocument.data() == null) {
        throw StateError('Cobrança da fatura não encontrada.');
      }

      final invoiceId = chargeDocument.data()!['invoiceId']?.toString().trim();
      if (invoiceId == null || invoiceId.isEmpty) {
        throw StateError('Fatura da compra não encontrada.');
      }
      final invoiceReference = cardReference.collection('invoices').doc(invoiceId);
      final invoiceDocument = await firestoreTransaction.get(invoiceReference);
      if (!invoiceDocument.exists || invoiceDocument.data() == null) {
        throw StateError('Fatura da compra não encontrada.');
      }

      final invoice = CreditCardInvoiceModel.fromMap(invoiceDocument.data()!);
      if (invoice.isPaid) {
        throw StateError(
          'Esta fatura já foi paga. Excluir a compra exigiria um estorno; '
          'registre o estorno em vez de apagar o histórico.',
        );
      }

      final amount = transaction.value;
      final newTotal = (invoice.total - amount).clamp(0, double.infinity).toDouble();
      firestoreTransaction.update(cardReference, {
        'usedLimit': FieldValue.increment(-amount),
      });
      if (newTotal <= 0.004) {
        firestoreTransaction.delete(invoiceReference);
      } else {
        firestoreTransaction.update(invoiceReference, {
          'total': newTotal,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      firestoreTransaction.delete(chargeReference);
      firestoreTransaction.delete(transactionReference);
    });
  }

  Future<WalletModel> _requireTransactionWallet(String walletId) async {
    final wallet = await _walletRepository.getWalletById(walletId);
    if (wallet == null) {
      throw StateError('Carteira da transação não encontrada.');
    }
    return wallet;
  }

  Future<WalletModel> _resolveFinancialWallet(
    TransactionModel transaction,
  ) async {
    final sourceId = transaction.paymentSourceId?.trim();
    if (sourceId != null && sourceId.isNotEmpty) {
      final wallet = await _walletRepository.getWalletById(sourceId);
      if (wallet != null && wallet.isIndividual) return wallet;
    }

    final payerId = transaction.paidByMemberId?.trim();
    if (payerId != null && payerId.isNotEmpty) {
      final wallet = await _walletRepository.getFinancialWalletForMember(payerId);
      if (wallet != null) return wallet;
    }

    throw StateError('Carteira financeira da transação não encontrada.');
  }

  void _validateCanManage(
    TransactionModel transaction,
    WalletModel wallet,
    String userId,
  ) {
    if (!wallet.hasMember(userId)) {
      throw StateError('Você não participa da carteira desta transação.');
    }
    final payer = transaction.paidByMemberId?.trim();
    if (payer != null && payer.isNotEmpty && payer != userId) {
      throw StateError('Somente quem lançou/pagou pode alterar esta transação.');
    }
    if (wallet.isIndividual && !wallet.isOwner(userId)) {
      throw StateError('Você não pode alterar transações desta carteira.');
    }
  }

  double _balanceEffect(TransactionModel transaction) {
    return transaction.type == 'income'
        ? transaction.value
        : -transaction.value;
  }

  bool _sameAmount(double first, double second) {
    return (first * 100).round() == (second * 100).round();
  }

  bool _sameMoment(DateTime first, DateTime second) {
    return first.millisecondsSinceEpoch == second.millisecondsSinceEpoch;
  }

  String _requireUserId() {
    final userId = _auth.currentUser?.uid.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('É necessário estar autenticado.');
    }
    return userId;
  }

  DocumentReference<Map<String, dynamic>> _transactionReference({
    required String userId,
    required WalletModel wallet,
    required String transactionId,
  }) {
    if (wallet.isShared) {
      return _firestore
          .collection('wallets')
          .doc(wallet.id)
          .collection('transactions')
          .doc(transactionId);
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId);
  }

  DocumentReference<Map<String, dynamic>> _financialWalletReference({
    required String userId,
    required String walletId,
  }) {
    if (walletId == 'principal') {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('wallets')
          .doc('principal');
    }
    return _firestore.collection('wallets').doc(walletId);
  }
}
