import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/credit_card_invoice_model.dart';
import '../models/credit_card_model.dart';
import '../models/wallet_model.dart';
import '../../../transactions/data/models/transaction_model.dart';

class CreditCardRepository {
  static const String _cardsCollection = 'creditCards';
  static const String _invoicesCollection = 'invoices';
  static const String _chargesCollection = 'charges';
  static const String _walletsCollection = 'wallets';
  static const String _usersCollection = 'users';
  static const String _legacyMainWalletId = 'principal';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CreditCardRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<List<CreditCardModel>> getCards() async {
    final userId = _requireUserId();
    final snapshot = await _firestore
        .collection(_cardsCollection)
        .where('ownerMemberId', isEqualTo: userId)
        .get();

    final cards =
        snapshot.docs
            .map((document) {
              final data = Map<String, dynamic>.from(document.data());
              data['id'] = document.id;
              return CreditCardModel.fromMap(data);
            })
            .toList(growable: true)
          ..sort(
            (first, second) =>
                first.name.toLowerCase().compareTo(second.name.toLowerCase()),
          );

    return List<CreditCardModel>.unmodifiable(cards);
  }

  Future<List<CreditCardModel>> getActiveCards() async {
    final cards = await getCards();
    return List<CreditCardModel>.unmodifiable(
      cards.where((card) => card.isActive),
    );
  }

  Future<CreditCardModel?> getCardById(String cardId) async {
    final userId = _requireUserId();
    final normalizedCardId = cardId.trim();

    if (normalizedCardId.isEmpty) {
      return null;
    }

    final document = await _cardReference(normalizedCardId).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    final data = Map<String, dynamic>.from(document.data()!);
    data['id'] = document.id;
    final card = CreditCardModel.fromMap(data);

    if (card.ownerMemberId != userId) {
      return null;
    }

    return card;
  }

  Future<CreditCardModel> createCard({
    required String name,
    String? walletId,
    required double creditLimit,
    required int closingDay,
    required int dueDay,
    String? lastFourDigits,
  }) async {
    final userId = _requireUserId();
    final normalizedName = name.trim();
    final normalizedWalletId = walletId?.trim();
    final normalizedDigits = lastFourDigits?.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'O nome do cartão não pode ficar vazio.',
      );
    }

    if (!creditLimit.isFinite || creditLimit <= 0) {
      throw ArgumentError.value(
        creditLimit,
        'creditLimit',
        'O limite precisa ser maior que zero.',
      );
    }

    _validateBillingDay(closingDay, 'closingDay');
    _validateBillingDay(dueDay, 'dueDay');

    if (normalizedDigits != null &&
        normalizedDigits.isNotEmpty &&
        !RegExp(r'^\d{4}$').hasMatch(normalizedDigits)) {
      throw ArgumentError.value(
        lastFourDigits,
        'lastFourDigits',
        'Informe exatamente os quatro últimos dígitos.',
      );
    }

    if (normalizedWalletId != null && normalizedWalletId.isNotEmpty) {
      final walletReference = _walletReference(
        userId: userId,
        walletId: normalizedWalletId,
      );
      final walletDocument = await walletReference.get();

      _validateIndividualWallet(
        document: walletDocument,
        ownerMemberId: userId,
      );
    }

    final cardDocument = _firestore.collection(_cardsCollection).doc();
    final card = CreditCardModel(
      id: cardDocument.id,
      ownerMemberId: userId,
      walletId: normalizedWalletId?.isEmpty == true ? null : normalizedWalletId,
      name: normalizedName,
      lastFourDigits: normalizedDigits == null || normalizedDigits.isEmpty
          ? null
          : normalizedDigits,
      creditLimit: creditLimit,
      closingDay: closingDay,
      dueDay: dueDay,
    );

    await cardDocument.set(card.toMap());

    return card;
  }

  void _validateCardInput({
    required String name,
    required double creditLimit,
    required int closingDay,
    required int dueDay,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('O nome do cartão não pode ficar vazio.');
    }
    if (!creditLimit.isFinite || creditLimit <= 0) {
      throw ArgumentError('O limite precisa ser maior que zero.');
    }
    _validateBillingDay(closingDay, 'closingDay');
    _validateBillingDay(dueDay, 'dueDay');
  }

  Future<List<CreditCardInvoiceModel>> getInvoices({
    required String cardId,
  }) async {
    final card = await getCardById(cardId);

    if (card == null) {
      throw StateError('Cartão não encontrado.');
    }

    final snapshot = await _cardReference(
      card.id,
    ).collection(_invoicesCollection).get();
    final invoices =
        snapshot.docs
            .map((document) => CreditCardInvoiceModel.fromMap(document.data()))
            .toList(growable: true)
          ..sort((first, second) {
            final yearComparison = second.referenceYear.compareTo(
              first.referenceYear,
            );

            if (yearComparison != 0) {
              return yearComparison;
            }

            return second.referenceMonth.compareTo(first.referenceMonth);
          });

    return List<CreditCardInvoiceModel>.unmodifiable(invoices);
  }

  Future<List<TransactionModel>> getCardPurchases({
    required String cardId,
  }) async {
    final card = await getCardById(cardId);
    if (card == null) return const [];
    final charges = await _cardReference(
      card.id,
    ).collection(_chargesCollection).get();
    final ids = charges.docs.map((doc) => doc.id).toSet();
    if (ids.isEmpty) return const [];
    final transactions = await _firestore
        .collectionGroup('transactions')
        .where('paymentSourceId', isEqualTo: card.id)
        .get();
    final result =
        transactions.docs
            .where((doc) => ids.contains(doc.id))
            .map(
              (doc) => TransactionModel.fromMap({...doc.data(), 'id': doc.id}),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return List<TransactionModel>.unmodifiable(result);
  }

  Future<List<TransactionModel>> getInvoicePurchases({
    required String cardId,
    required String invoiceId,
  }) async {
    final card = await getCardById(cardId);
    if (card == null) return const [];
    final chargeDocs = await _cardReference(card.id)
        .collection(_chargesCollection)
        .where('invoiceId', isEqualTo: invoiceId)
        .get();
    final ids = chargeDocs.docs.map((doc) => doc.id).toSet();
    if (ids.isEmpty) return const [];
    final transactionDocs = await _firestore
        .collectionGroup('transactions')
        .where('paymentSourceId', isEqualTo: card.id)
        .get();
    final result =
        transactionDocs.docs
            .where((doc) => ids.contains(doc.id))
            .map(
              (doc) => TransactionModel.fromMap({...doc.data(), 'id': doc.id}),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return List<TransactionModel>.unmodifiable(result);
  }

  Future<CreditCardModel> updateCard({required CreditCardModel card}) async {
    final userId = _requireUserId();
    if (card.ownerMemberId != userId) {
      throw StateError('Você não pode editar este cartão.');
    }
    _validateCardInput(
      name: card.name,
      creditLimit: card.creditLimit,
      closingDay: card.closingDay,
      dueDay: card.dueDay,
    );
    if (card.walletId != null && card.walletId!.isNotEmpty) {
      final document = await _walletReference(
        userId: userId,
        walletId: card.walletId!,
      ).get();
      _validateIndividualWallet(document: document, ownerMemberId: userId);
    }
    await _cardReference(card.id).set(card.toMap(), SetOptions(merge: true));
    return card;
  }

  Future<void> setCardActive({
    required String cardId,
    required bool isActive,
  }) async {
    final card = await getCardById(cardId);
    if (card == null) throw StateError('Cartão não encontrado.');
    await _cardReference(card.id).update({'isActive': isActive});
  }

  Future<bool> cardHasFinancialHistory(String cardId) async {
    final reference = _cardReference(cardId);
    final invoices = await reference
        .collection(_invoicesCollection)
        .limit(1)
        .get();
    if (invoices.docs.isNotEmpty) return true;
    final charges = await reference
        .collection(_chargesCollection)
        .limit(1)
        .get();
    if (charges.docs.isNotEmpty) return true;
    final userId = _requireUserId();
    final transactions = await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection('transactions')
        .where('paymentSourceId', isEqualTo: cardId)
        .limit(1)
        .get();
    if (transactions.docs.isNotEmpty) return true;
    final sharedTransactions = await _firestore
        .collectionGroup('transactions')
        .where('paymentSourceId', isEqualTo: cardId)
        .limit(1)
        .get();
    return sharedTransactions.docs.isNotEmpty;
  }

  Future<void> deleteCard({required String cardId}) async {
    final card = await getCardById(cardId);
    if (card == null) throw StateError('Cartão não encontrado.');
    if (await cardHasFinancialHistory(cardId)) {
      throw StateError(
        'Este cartão possui histórico financeiro e deve ser arquivado.',
      );
    }
    await _cardReference(card.id).delete();
  }

  Future<CreditCardInvoiceModel> registerPurchase({
    required String cardId,
    required TransactionModel transactionModel,
    required WalletModel transactionWallet,
  }) async {
    final userId = _requireUserId();
    final normalizedCardId = cardId.trim();
    final normalizedTransactionId = transactionModel.id.trim();
    final paidByMemberId = transactionModel.paidByMemberId?.trim() ?? '';
    final amount = transactionModel.value;
    final purchaseDate = transactionModel.date;

    if (normalizedCardId.isEmpty || normalizedTransactionId.isEmpty) {
      throw ArgumentError('O cartão e a transação precisam ser identificados.');
    }

    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'O valor da compra precisa ser maior que zero.',
      );
    }

    if (paidByMemberId != userId) {
      throw StateError(
        'Somente o titular pode registrar uma compra neste cartão.',
      );
    }

    if (transactionModel.type != 'expense') {
      throw StateError(
        'Somente despesas podem ser lançadas no cartão de crédito.',
      );
    }

    if (transactionModel.paymentMethod != 'creditCard' ||
        transactionModel.paymentSourceId?.trim() != normalizedCardId ||
        !transactionModel.isSettledByInvoice) {
      throw StateError(
        'A transação não está vinculada a uma fatura do cartão informado.',
      );
    }

    _validateTransactionWallet(
      wallet: transactionWallet,
      userId: userId,
      transactionModel: transactionModel,
    );

    final cardReference = _cardReference(normalizedCardId);
    final chargeReference = cardReference
        .collection(_chargesCollection)
        .doc(normalizedTransactionId);
    final transactionReference = _transactionReference(
      userId: userId,
      wallet: transactionWallet,
      transactionId: normalizedTransactionId,
    );

    return _firestore.runTransaction((firestoreTransaction) async {
      final cardDocument = await firestoreTransaction.get(cardReference);
      final chargeDocument = await firestoreTransaction.get(chargeReference);
      final savedTransactionDocument = await firestoreTransaction.get(
        transactionReference,
      );

      if (!cardDocument.exists || cardDocument.data() == null) {
        throw StateError('Cartão não encontrado.');
      }

      final cardData = Map<String, dynamic>.from(cardDocument.data()!);
      cardData['id'] = cardDocument.id;
      final card = CreditCardModel.fromMap(cardData);

      if (card.ownerMemberId != userId || !card.isActive) {
        throw StateError('Cartão indisponível para esta compra.');
      }

      if (chargeDocument.exists && chargeDocument.data() != null) {
        final chargeData = chargeDocument.data()!;
        final invoiceId = chargeData['invoiceId']?.toString().trim() ?? '';
        final persistedTransactionId =
            chargeData['transactionId']?.toString().trim() ?? '';
        final persistedAmount = _parseDouble(chargeData['amount']);

        if (invoiceId.isEmpty ||
            persistedTransactionId != normalizedTransactionId ||
            !_amountsMatch(persistedAmount, amount)) {
          throw StateError('O transactionId já pertence a outra cobrança.');
        }

        final invoiceDocument = await firestoreTransaction.get(
          cardReference.collection(_invoicesCollection).doc(invoiceId),
        );

        if (!invoiceDocument.exists || invoiceDocument.data() == null) {
          throw StateError(
            'A cobrança existe, mas sua fatura não foi encontrada.',
          );
        }

        if (savedTransactionDocument.exists &&
            savedTransactionDocument.data() != null) {
          _validatePersistedCreditPurchase(
            persisted: TransactionModel.fromMap(
              savedTransactionDocument.data()!,
            ),
            requested: transactionModel,
            cardId: normalizedCardId,
          );
        } else {
          firestoreTransaction.set(
            transactionReference,
            transactionModel.toMap(),
          );
        }

        return CreditCardInvoiceModel.fromMap(invoiceDocument.data()!);
      }

      if (savedTransactionDocument.exists &&
          savedTransactionDocument.data() != null) {
        _validatePersistedCreditPurchase(
          persisted: TransactionModel.fromMap(savedTransactionDocument.data()!),
          requested: transactionModel,
          cardId: normalizedCardId,
        );
      }

      if (!card.canPurchase(amount)) {
        throw StateError('Limite insuficiente no cartão.');
      }

      final invoice = _buildInvoice(card: card, purchaseDate: purchaseDate);
      final invoiceReference = cardReference
          .collection(_invoicesCollection)
          .doc(invoice.id);
      final invoiceDocument = await firestoreTransaction.get(invoiceReference);

      CreditCardInvoiceModel updatedInvoice;

      if (invoiceDocument.exists && invoiceDocument.data() != null) {
        final currentInvoice = CreditCardInvoiceModel.fromMap(
          invoiceDocument.data()!,
        );

        if (currentInvoice.isPaid) {
          throw StateError(
            'Esta fatura já foi paga e não pode receber novas compras.',
          );
        }

        updatedInvoice = _invoiceWithTotal(
          currentInvoice,
          currentInvoice.total + amount,
          purchaseDate,
        );

        firestoreTransaction.update(invoiceReference, {
          'total': FieldValue.increment(amount),
          'updatedAt': purchaseDate.toIso8601String(),
        });
      } else {
        updatedInvoice = _invoiceWithTotal(invoice, amount, purchaseDate);
        firestoreTransaction.set(invoiceReference, updatedInvoice.toMap());
      }

      firestoreTransaction.update(cardReference, {
        'usedLimit': FieldValue.increment(amount),
      });
      firestoreTransaction.set(chargeReference, {
        'transactionId': normalizedTransactionId,
        'invoiceId': invoice.id,
        'amount': amount,
        'purchaseDate': purchaseDate.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      firestoreTransaction.set(transactionReference, transactionModel.toMap());

      return updatedInvoice;
    });
  }

  Future<CreditCardInvoiceModel> initializeCurrentInvoice({
    required String cardId,
    required double amount,
    DateTime? referenceDate,
  }) async {
    final userId = _requireUserId();
    if (!amount.isFinite || amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'Informe um valor válido.');
    }
    final cardReference = _cardReference(cardId.trim());
    final date = referenceDate ?? DateTime.now();
    return _firestore.runTransaction((transaction) async {
      final cardDocument = await transaction.get(cardReference);
      if (!cardDocument.exists || cardDocument.data() == null) {
        throw StateError('Cartão não encontrado.');
      }
      final cardData = Map<String, dynamic>.from(cardDocument.data()!)
        ..['id'] = cardDocument.id;
      final card = CreditCardModel.fromMap(cardData);
      if (card.ownerMemberId != userId || !card.isActive) {
        throw StateError('Cartão indisponível.');
      }
      final invoice = _buildInvoice(card: card, purchaseDate: date);
      final invoiceReference = cardReference
          .collection(_invoicesCollection)
          .doc(invoice.id);
      final existingDocument = await transaction.get(invoiceReference);
      final existing =
          existingDocument.exists && existingDocument.data() != null
          ? CreditCardInvoiceModel.fromMap(existingDocument.data()!)
          : invoice;
      if (existing.isPaid) throw StateError('A fatura já foi paga.');
      final delta = amount - existing.initialBalance;
      final updated = _invoiceWithTotal(
        existing,
        existing.total + delta,
        date,
        initialBalance: amount,
      );
      transaction.set(
        invoiceReference,
        updated.toMap(),
        SetOptions(merge: true),
      );
      if (delta != 0)
        transaction.update(cardReference, {
          'usedLimit': FieldValue.increment(delta),
        });
      return updated;
    });
  }

  Future<CreditCardInvoiceModel> payInvoice({
    required String cardId,
    required String invoiceId,
    String? walletId,
    DateTime? paidAt,
  }) async {
    final userId = _requireUserId();
    final normalizedCardId = cardId.trim();
    final normalizedInvoiceId = invoiceId.trim();

    if (normalizedCardId.isEmpty || normalizedInvoiceId.isEmpty) {
      throw ArgumentError('O cartão e a fatura precisam ser identificados.');
    }

    final cardReference = _cardReference(normalizedCardId);
    final invoiceReference = cardReference
        .collection(_invoicesCollection)
        .doc(normalizedInvoiceId);
    final paymentDate = paidAt ?? DateTime.now();

    return _firestore.runTransaction((transaction) async {
      final cardDocument = await transaction.get(cardReference);
      final invoiceDocument = await transaction.get(invoiceReference);

      if (!cardDocument.exists || cardDocument.data() == null) {
        throw StateError('Cartão não encontrado.');
      }

      if (!invoiceDocument.exists || invoiceDocument.data() == null) {
        throw StateError('Fatura não encontrada.');
      }

      final cardData = Map<String, dynamic>.from(cardDocument.data()!);
      cardData['id'] = cardDocument.id;
      final card = CreditCardModel.fromMap(cardData);
      final invoice = CreditCardInvoiceModel.fromMap(invoiceDocument.data()!);

      if (card.ownerMemberId != userId || invoice.ownerMemberId != userId) {
        throw StateError('Usuário sem acesso a esta fatura.');
      }

      if (invoice.isPaid) {
        return invoice;
      }

      final selectedWalletId = walletId?.trim().isNotEmpty == true
          ? walletId!.trim()
          : card.walletId;
      if (selectedWalletId == null || selectedWalletId.isEmpty) {
        throw StateError('Selecione uma carteira para pagar esta fatura.');
      }
      final walletReference = _walletReference(
        userId: userId,
        walletId: selectedWalletId,
      );
      final walletDocument = await transaction.get(walletReference);

      _validateIndividualWallet(
        document: walletDocument,
        ownerMemberId: userId,
      );

      final walletBalance = _parseDouble(walletDocument.data()?['balance']);

      if (!_hasSufficientBalance(walletBalance, invoice.total)) {
        throw StateError('Saldo insuficiente para pagar esta fatura.');
      }

      final paidInvoice = _paidInvoice(
        invoice,
        paymentDate: paymentDate,
        paymentWalletId: selectedWalletId,
      );

      transaction.update(walletReference, {
        'balance': FieldValue.increment(-invoice.total),
        'updatedAt': paymentDate.toIso8601String(),
      });
      transaction.update(cardReference, {
        'usedLimit': FieldValue.increment(-invoice.total),
      });
      transaction.set(
        invoiceReference,
        paidInvoice.toMap(),
        SetOptions(merge: true),
      );

      return paidInvoice;
    });
  }

  DocumentReference<Map<String, dynamic>> _transactionReference({
    required String userId,
    required WalletModel wallet,
    required String transactionId,
  }) {
    if (wallet.isShared) {
      return _firestore
          .collection(_walletsCollection)
          .doc(wallet.id)
          .collection('transactions')
          .doc(transactionId);
    }

    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection('transactions')
        .doc(transactionId);
  }

  void _validateTransactionWallet({
    required WalletModel wallet,
    required String userId,
    required TransactionModel transactionModel,
  }) {
    if (wallet.id.trim() != transactionModel.walletId.trim()) {
      throw StateError('A transação não pertence à carteira informada.');
    }

    if (wallet.isShared && !wallet.hasMember(userId)) {
      throw StateError('O usuário não participa da carteira compartilhada.');
    }

    if (wallet.isIndividual && !wallet.isOwner(userId)) {
      throw StateError('O usuário não é titular da carteira individual.');
    }
  }

  DocumentReference<Map<String, dynamic>> _cardReference(String cardId) {
    return _firestore.collection(_cardsCollection).doc(cardId);
  }

  DocumentReference<Map<String, dynamic>> _walletReference({
    required String userId,
    required String walletId,
  }) {
    if (walletId == _legacyMainWalletId) {
      return _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_walletsCollection)
          .doc(_legacyMainWalletId);
    }

    return _firestore.collection(_walletsCollection).doc(walletId);
  }

  void _validateIndividualWallet({
    required DocumentSnapshot<Map<String, dynamic>> document,
    required String ownerMemberId,
  }) {
    if (!document.exists || document.data() == null) {
      throw StateError('Carteira vinculada não encontrada.');
    }

    final data = document.data()!;
    final isLegacyMainWallet =
        document.reference.path ==
        '$_usersCollection/$ownerMemberId/'
            '$_walletsCollection/$_legacyMainWalletId';
    final rawOwnerId = data['ownerId']?.toString().trim() ?? '';
    final rawType = data['type']?.toString().trim() ?? '';
    final ownerId = rawOwnerId.isEmpty && isLegacyMainWallet
        ? ownerMemberId
        : rawOwnerId;
    final type = rawType.isEmpty && isLegacyMainWallet ? 'individual' : rawType;

    if (ownerId != ownerMemberId || type != 'individual') {
      throw StateError(
        'O cartão precisa estar vinculado a uma carteira individual do titular.',
      );
    }
  }

  void _validatePersistedCreditPurchase({
    required TransactionModel persisted,
    required TransactionModel requested,
    required String cardId,
  }) {
    if (persisted.id.trim() != requested.id.trim() ||
        persisted.type != 'expense' ||
        persisted.paymentMethod != 'creditCard' ||
        persisted.paymentSourceId?.trim() != cardId ||
        persisted.walletId.trim() != requested.walletId.trim() ||
        persisted.paidByMemberId?.trim() != requested.paidByMemberId?.trim() ||
        !_amountsMatch(persisted.value, requested.value)) {
      throw StateError('O transactionId já pertence a outra compra.');
    }
  }

  bool _amountsMatch(double first, double second) {
    return (first * 100).round() == (second * 100).round();
  }

  bool _hasSufficientBalance(double balance, double amount) {
    return (balance * 100).round() >= (amount * 100).round();
  }

  double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  CreditCardInvoiceModel _buildInvoice({
    required CreditCardModel card,
    required DateTime purchaseDate,
  }) {
    var referenceYear = purchaseDate.year;
    var referenceMonth = purchaseDate.month;

    if (purchaseDate.day > card.closingDay) {
      final nextMonth = DateTime(referenceYear, referenceMonth + 1);
      referenceYear = nextMonth.year;
      referenceMonth = nextMonth.month;
    }

    final closingDate = _dateWithClampedDay(
      referenceYear,
      referenceMonth,
      card.closingDay,
    );
    final dueMonth = card.dueDay > card.closingDay
        ? DateTime(referenceYear, referenceMonth)
        : DateTime(referenceYear, referenceMonth + 1);
    final dueDate = _dateWithClampedDay(
      dueMonth.year,
      dueMonth.month,
      card.dueDay,
    );
    final now = DateTime.now();
    final invoiceId =
        '${referenceYear.toString().padLeft(4, '0')}-'
        '${referenceMonth.toString().padLeft(2, '0')}';

    return CreditCardInvoiceModel(
      id: invoiceId,
      cardId: card.id,
      ownerMemberId: card.ownerMemberId,
      referenceYear: referenceYear,
      referenceMonth: referenceMonth,
      closingDate: closingDate,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
    );
  }

  CreditCardInvoiceModel _invoiceWithTotal(
    CreditCardInvoiceModel invoice,
    double total,
    DateTime updatedAt, {
    double? initialBalance,
  }) {
    return CreditCardInvoiceModel(
      id: invoice.id,
      cardId: invoice.cardId,
      ownerMemberId: invoice.ownerMemberId,
      referenceYear: invoice.referenceYear,
      referenceMonth: invoice.referenceMonth,
      closingDate: invoice.closingDate,
      dueDate: invoice.dueDate,
      total: total,
      initialBalance: initialBalance ?? invoice.initialBalance,
      status: invoice.status,
      paidAt: invoice.paidAt,
      paymentWalletId: invoice.paymentWalletId,
      createdAt: invoice.createdAt,
      updatedAt: updatedAt,
    );
  }

  CreditCardInvoiceModel _paidInvoice(
    CreditCardInvoiceModel invoice, {
    required DateTime paymentDate,
    required String paymentWalletId,
  }) {
    return CreditCardInvoiceModel(
      id: invoice.id,
      cardId: invoice.cardId,
      ownerMemberId: invoice.ownerMemberId,
      referenceYear: invoice.referenceYear,
      referenceMonth: invoice.referenceMonth,
      closingDate: invoice.closingDate,
      dueDate: invoice.dueDate,
      total: invoice.total,
      initialBalance: invoice.initialBalance,
      status: CreditCardInvoiceModel.paidStatus,
      paidAt: paymentDate,
      paymentWalletId: paymentWalletId,
      createdAt: invoice.createdAt,
      updatedAt: paymentDate,
    );
  }

  DateTime _dateWithClampedDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final safeDay = day > lastDay ? lastDay : day;
    return DateTime(year, month, safeDay);
  }

  void _validateBillingDay(int day, String argumentName) {
    if (day < 1 || day > 31) {
      throw ArgumentError.value(
        day,
        argumentName,
        'O dia precisa estar entre 1 e 31.',
      );
    }
  }

  String _requireUserId() {
    final userId = _auth.currentUser?.uid.trim();

    if (userId == null || userId.isEmpty) {
      throw StateError('É necessário estar autenticado.');
    }

    return userId;
  }
}
