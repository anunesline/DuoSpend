import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/credit_card_invoice_model.dart';
import '../models/credit_card_model.dart';

class CreditCardRepository {
  static const String _cardsCollection = 'creditCards';
  static const String _invoicesCollection = 'invoices';
  static const String _chargesCollection = 'charges';
  static const String _walletsCollection = 'wallets';
  static const String _usersCollection = 'users';
  static const String _legacyMainWalletId = 'principal';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CreditCardRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  Future<List<CreditCardModel>> getCards() async {
    final userId = _requireUserId();
    final snapshot = await _firestore
        .collection(_cardsCollection)
        .where('ownerMemberId', isEqualTo: userId)
        .get();

    final cards = snapshot.docs
        .map((document) {
          final data = Map<String, dynamic>.from(document.data());
          data['id'] = document.id;
          return CreditCardModel.fromMap(data);
        })
        .toList(growable: true)
      ..sort((first, second) => first.name
          .toLowerCase()
          .compareTo(second.name.toLowerCase()));

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
    required String walletId,
    required double creditLimit,
    required int closingDay,
    required int dueDay,
    String? lastFourDigits,
  }) async {
    final userId = _requireUserId();
    final normalizedName = name.trim();
    final normalizedWalletId = walletId.trim();
    final normalizedDigits = lastFourDigits?.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'O nome do cartão não pode ficar vazio.',
      );
    }

    if (normalizedWalletId.isEmpty) {
      throw ArgumentError.value(
        walletId,
        'walletId',
        'Selecione a carteira vinculada ao cartão.',
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

    final walletReference = _walletReference(
      userId: userId,
      walletId: normalizedWalletId,
    );
    final walletDocument = await walletReference.get();

    _validateIndividualWallet(
      document: walletDocument,
      ownerMemberId: userId,
    );

    final cardDocument =
        _firestore.collection(_cardsCollection).doc();
    final card = CreditCardModel(
      id: cardDocument.id,
      ownerMemberId: userId,
      walletId: normalizedWalletId,
      name: normalizedName,
      lastFourDigits:
          normalizedDigits == null || normalizedDigits.isEmpty
              ? null
              : normalizedDigits,
      creditLimit: creditLimit,
      closingDay: closingDay,
      dueDay: dueDay,
    );

    await cardDocument.set(card.toMap());

    return card;
  }

  Future<List<CreditCardInvoiceModel>> getInvoices({
    required String cardId,
  }) async {
    final card = await getCardById(cardId);

    if (card == null) {
      throw StateError('Cartão não encontrado.');
    }

    final snapshot = await _cardReference(card.id)
        .collection(_invoicesCollection)
        .orderBy('referenceYear', descending: true)
        .orderBy('referenceMonth', descending: true)
        .get();

    return List<CreditCardInvoiceModel>.unmodifiable(
      snapshot.docs.map(
        (document) => CreditCardInvoiceModel.fromMap(
          document.data(),
        ),
      ),
    );
  }

  Future<CreditCardInvoiceModel> registerPurchase({
    required String cardId,
    required String transactionId,
    required double amount,
    required DateTime purchaseDate,
    required String paidByMemberId,
  }) async {
    final userId = _requireUserId();
    final normalizedCardId = cardId.trim();
    final normalizedTransactionId = transactionId.trim();

    if (normalizedCardId.isEmpty ||
        normalizedTransactionId.isEmpty) {
      throw ArgumentError(
        'O cartão e a transação precisam ser identificados.',
      );
    }

    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'O valor da compra precisa ser maior que zero.',
      );
    }

    if (paidByMemberId.trim() != userId) {
      throw StateError(
        'Somente o titular pode registrar uma compra neste cartão.',
      );
    }

    final cardReference = _cardReference(normalizedCardId);
    final chargeReference = cardReference
        .collection(_chargesCollection)
        .doc(normalizedTransactionId);

    return _firestore.runTransaction((transaction) async {
      final cardDocument = await transaction.get(cardReference);

      if (!cardDocument.exists || cardDocument.data() == null) {
        throw StateError('Cartão não encontrado.');
      }

      final cardData =
          Map<String, dynamic>.from(cardDocument.data()!);
      cardData['id'] = cardDocument.id;
      final card = CreditCardModel.fromMap(cardData);

      if (card.ownerMemberId != userId || !card.isActive) {
        throw StateError('Cartão indisponível para esta compra.');
      }

      final chargeDocument = await transaction.get(
        chargeReference,
      );

      if (chargeDocument.exists &&
          chargeDocument.data() != null) {
        final invoiceId =
            chargeDocument.data()!['invoiceId']?.toString() ?? '';
        final invoiceDocument = await transaction.get(
          cardReference
              .collection(_invoicesCollection)
              .doc(invoiceId),
        );

        if (!invoiceDocument.exists ||
            invoiceDocument.data() == null) {
          throw StateError(
            'A cobrança existe, mas sua fatura não foi encontrada.',
          );
        }

        return CreditCardInvoiceModel.fromMap(
          invoiceDocument.data()!,
        );
      }

      if (!card.canPurchase(amount)) {
        throw StateError('Limite insuficiente no cartão.');
      }

      final invoice = _buildInvoice(
        card: card,
        purchaseDate: purchaseDate,
      );
      final invoiceReference = cardReference
          .collection(_invoicesCollection)
          .doc(invoice.id);
      final invoiceDocument = await transaction.get(
        invoiceReference,
      );

      CreditCardInvoiceModel updatedInvoice;

      if (invoiceDocument.exists &&
          invoiceDocument.data() != null) {
        final currentInvoice =
            CreditCardInvoiceModel.fromMap(
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

        transaction.update(invoiceReference, {
          'total': FieldValue.increment(amount),
          'updatedAt': purchaseDate.toIso8601String(),
        });
      } else {
        updatedInvoice = _invoiceWithTotal(
          invoice,
          amount,
          purchaseDate,
        );
        transaction.set(
          invoiceReference,
          updatedInvoice.toMap(),
        );
      }

      transaction.update(cardReference, {
        'usedLimit': FieldValue.increment(amount),
      });
      transaction.set(chargeReference, {
        'transactionId': normalizedTransactionId,
        'invoiceId': invoice.id,
        'amount': amount,
        'purchaseDate': purchaseDate.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      return updatedInvoice;
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

    if (normalizedCardId.isEmpty ||
        normalizedInvoiceId.isEmpty) {
      throw ArgumentError(
        'O cartão e a fatura precisam ser identificados.',
      );
    }

    final cardReference = _cardReference(normalizedCardId);
    final invoiceReference = cardReference
        .collection(_invoicesCollection)
        .doc(normalizedInvoiceId);
    final paymentDate = paidAt ?? DateTime.now();

    return _firestore.runTransaction((transaction) async {
      final cardDocument = await transaction.get(cardReference);
      final invoiceDocument = await transaction.get(
        invoiceReference,
      );

      if (!cardDocument.exists ||
          cardDocument.data() == null) {
        throw StateError('Cartão não encontrado.');
      }

      if (!invoiceDocument.exists ||
          invoiceDocument.data() == null) {
        throw StateError('Fatura não encontrada.');
      }

      final cardData =
          Map<String, dynamic>.from(cardDocument.data()!);
      cardData['id'] = cardDocument.id;
      final card = CreditCardModel.fromMap(cardData);
      final invoice = CreditCardInvoiceModel.fromMap(
        invoiceDocument.data()!,
      );

      if (card.ownerMemberId != userId ||
          invoice.ownerMemberId != userId) {
        throw StateError('Usuário sem acesso a esta fatura.');
      }

      if (invoice.isPaid) {
        return invoice;
      }

      final selectedWalletId =
          walletId?.trim().isNotEmpty == true
              ? walletId!.trim()
              : card.walletId;
      final walletReference = _walletReference(
        userId: userId,
        walletId: selectedWalletId,
      );
      final walletDocument = await transaction.get(
        walletReference,
      );

      _validateIndividualWallet(
        document: walletDocument,
        ownerMemberId: userId,
      );

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

  DocumentReference<Map<String, dynamic>> _cardReference(
    String cardId,
  ) {
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
    final ownerId = data['ownerId']?.toString().trim() ?? '';
    final type = data['type']?.toString().trim() ?? '';

    if (ownerId != ownerMemberId || type != 'individual') {
      throw StateError(
        'O cartão precisa estar vinculado a uma carteira individual do titular.',
      );
    }
  }

  CreditCardInvoiceModel _buildInvoice({
    required CreditCardModel card,
    required DateTime purchaseDate,
  }) {
    var referenceYear = purchaseDate.year;
    var referenceMonth = purchaseDate.month;

    if (purchaseDate.day > card.closingDay) {
      final nextMonth = DateTime(
        referenceYear,
        referenceMonth + 1,
      );
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
    DateTime updatedAt,
  ) {
    return CreditCardInvoiceModel(
      id: invoice.id,
      cardId: invoice.cardId,
      ownerMemberId: invoice.ownerMemberId,
      referenceYear: invoice.referenceYear,
      referenceMonth: invoice.referenceMonth,
      closingDate: invoice.closingDate,
      dueDate: invoice.dueDate,
      total: total,
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
      status: CreditCardInvoiceModel.paidStatus,
      paidAt: paymentDate,
      paymentWalletId: paymentWalletId,
      createdAt: invoice.createdAt,
      updatedAt: paymentDate,
    );
  }

  DateTime _dateWithClampedDay(
    int year,
    int month,
    int day,
  ) {
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
