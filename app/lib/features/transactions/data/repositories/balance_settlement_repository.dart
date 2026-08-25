import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/balance_settlement_model.dart';

class BalanceSettlementRepository {
  static const String _walletsCollection = 'wallets';
  static const String _settlementsCollectionName = 'settlements';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BalanceSettlementRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  Future<void> saveSettlement(
    BalanceSettlementModel settlement,
  ) async {
    final userId = _requireAuthenticatedUserId();

    await _validateWalletAccess(
      walletId: settlement.walletId,
      userId: userId,
    );

    await _settlementsCollection(settlement.walletId)
        .doc(settlement.id)
        .set(settlement.toMap());
  }

  Future<List<BalanceSettlementModel>> getSettlements({
    required String walletId,
  }) async {
    final userId = _requireAuthenticatedUserId();
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      throw ArgumentError.value(
        walletId,
        'walletId',
        'O ID da carteira não pode ficar vazio.',
      );
    }

    await _validateWalletAccess(
      walletId: normalizedWalletId,
      userId: userId,
    );

    final snapshot = await _settlementsCollection(
      normalizedWalletId,
    )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .get();

    return snapshot.docs
        .map(
          (document) => BalanceSettlementModel.fromMap(
            document.data(),
          ),
        )
        .toList(growable: false);
  }

  /// Retorna todos os acertos que ainda fazem parte
  /// do fluxo financeiro ativo.
  ///
  /// Inclui:
  /// - pending;
  /// - awaiting_confirmation.
  ///
  /// Acertos aguardando confirmação não podem ser ignorados,
  /// pois ainda não foram definitivamente concluídos.
  Future<List<BalanceSettlementModel>> getPendingSettlements({
    required String walletId,
  }) async {
    final settlements = await getSettlements(
      walletId: walletId,
    );

    return settlements
        .where(
          (settlement) =>
              settlement.isPending ||
              settlement.isAwaitingConfirmation,
        )
        .toList(growable: false);
  }

  Future<List<BalanceSettlementModel>> getCompletedSettlements({
    required String walletId,
  }) async {
    final settlements = await getSettlements(
      walletId: walletId,
    );

    return settlements
        .where((settlement) => settlement.isSettled)
        .toList(growable: false);
  }

  /// Registra que o membro devedor informou ter realizado
  /// o pagamento.
  ///
  /// O usuário autenticado precisa ser o fromMemberId
  /// do acerto.
  Future<BalanceSettlementModel> declarePayment({
    required BalanceSettlementModel settlement,
    required String payerWalletId,
    DateTime? declaredAt,
    String? notes,
  }) async {
    final userId = _requireAuthenticatedUserId();

    await _validateWalletAccess(
      walletId: settlement.walletId,
      userId: userId,
    );

    final updatedSettlement = settlement.declarePayment(
      declaredByMemberId: userId,
      declaredAt: declaredAt ?? DateTime.now(),
      payerWalletId: payerWalletId,
      notes: notes,
    );

    await _settlementsCollection(updatedSettlement.walletId)
        .doc(updatedSettlement.id)
        .set(
          updatedSettlement.toMap(),
          SetOptions(merge: true),
        );

    return updatedSettlement;
  }

  /// Cancela a declaração de pagamento antes que
  /// o credor confirme o recebimento.
  ///
  /// Somente o membro devedor que informou o pagamento
  /// pode cancelar essa declaração.
  Future<BalanceSettlementModel> cancelPaymentDeclaration({
    required BalanceSettlementModel settlement,
  }) async {
    final userId = _requireAuthenticatedUserId();

    await _validateWalletAccess(
      walletId: settlement.walletId,
      userId: userId,
    );

    final updatedSettlement =
        settlement.cancelPaymentDeclaration(
      cancelledByMemberId: userId,
    );

    await _settlementsCollection(updatedSettlement.walletId)
        .doc(updatedSettlement.id)
        .set(
          updatedSettlement.toMap(),
          SetOptions(merge: false),
        );

    return updatedSettlement;
  }

  /// Confirma que o membro credor recebeu o pagamento.
  ///
  /// O usuário autenticado precisa ser o toMemberId
  /// do acerto.
  ///
  /// O transactionId identifica a transação financeira
  /// criada para representar o pagamento no histórico.
  Future<BalanceSettlementModel> confirmReceipt({
    required BalanceSettlementModel settlement,
    required String transactionId,
    required String receiverWalletId,
    DateTime? confirmedAt,
    String? notes,
  }) async {
    final userId = _requireAuthenticatedUserId();
    final normalizedTransactionId = transactionId.trim();
    final normalizedReceiverWalletId = receiverWalletId.trim();

    if (normalizedTransactionId.isEmpty) {
      throw ArgumentError.value(
        transactionId,
        'transactionId',
        'O ID da transação do acerto não pode ficar vazio.',
      );
    }

    if (normalizedReceiverWalletId.isEmpty) {
      throw ArgumentError.value(
        receiverWalletId,
        'receiverWalletId',
        'A carteira que recebeu o pagamento não pode ficar vazia.',
      );
    }

    final settlementReference = _settlementsCollection(
      settlement.walletId,
    ).doc(settlement.id);
    final payerWalletId = settlement.payerWalletId?.trim() ?? '';

    if (payerWalletId.isEmpty) {
      throw StateError(
        'O pagamento não possui uma carteira de origem informada.',
      );
    }

    final payerWalletReference = _firestore
        .collection(_walletsCollection)
        .doc(payerWalletId);
    final receiverWalletReference = _firestore
        .collection(_walletsCollection)
        .doc(normalizedReceiverWalletId);
    final confirmationDate = confirmedAt ?? DateTime.now();

    return _firestore.runTransaction((transaction) async {
      final settlementDocument = await transaction.get(
        settlementReference,
      );

      if (!settlementDocument.exists ||
          settlementDocument.data() == null) {
        throw StateError('Acerto financeiro não encontrado.');
      }

      final currentSettlement =
          BalanceSettlementModel.fromMap(
            settlementDocument.data()!,
          );

      if (currentSettlement.isSettled) {
        return currentSettlement;
      }

      final payerWalletDocument = await transaction.get(
        payerWalletReference,
      );
      final receiverWalletDocument = await transaction.get(
        receiverWalletReference,
      );

      _validateIndividualWalletOwnership(
        document: payerWalletDocument,
        expectedOwnerId: currentSettlement.fromMemberId,
        role: 'origem',
      );
      _validateIndividualWalletOwnership(
        document: receiverWalletDocument,
        expectedOwnerId: currentSettlement.toMemberId,
        role: 'destino',
      );

      final updatedSettlement = currentSettlement.confirmReceipt(
        confirmedByMemberId: userId,
        confirmedAt: confirmationDate,
        transactionId: normalizedTransactionId,
        receiverWalletId: normalizedReceiverWalletId,
        notes: notes,
      );
      final updatedAt = confirmationDate.toIso8601String();

      transaction.update(payerWalletReference, {
        'balance': FieldValue.increment(
          -updatedSettlement.amount,
        ),
        'updatedAt': updatedAt,
      });
      transaction.update(receiverWalletReference, {
        'balance': FieldValue.increment(
          updatedSettlement.amount,
        ),
        'updatedAt': updatedAt,
      });
      transaction.set(
        settlementReference,
        updatedSettlement.toMap(),
        SetOptions(merge: true),
      );

      return updatedSettlement;
    });
  }

  /// Mantido temporariamente para compatibilidade
  /// com o fluxo anterior.
  ///
  /// O novo fluxo deve utilizar declarePayment()
  /// e confirmReceipt().
  Future<void> markAsSettled({
    required BalanceSettlementModel settlement,
    DateTime? settledAt,
    String? notes,
  }) async {
    final userId = _requireAuthenticatedUserId();

    await _validateWalletAccess(
      walletId: settlement.walletId,
      userId: userId,
    );

    final updatedSettlement = settlement.markAsSettled(
      settledAt: settledAt ?? DateTime.now(),
      notes: notes,
    );

    await _settlementsCollection(updatedSettlement.walletId)
        .doc(updatedSettlement.id)
        .set(
          updatedSettlement.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteSettlement({
    required String walletId,
    required String settlementId,
  }) async {
    final userId = _requireAuthenticatedUserId();
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

    await _validateWalletAccess(
      walletId: normalizedWalletId,
      userId: userId,
    );

    await _settlementsCollection(normalizedWalletId)
        .doc(normalizedSettlementId)
        .delete();
  }

  CollectionReference<Map<String, dynamic>>
  _settlementsCollection(
    String walletId,
  ) {
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      throw ArgumentError.value(
        walletId,
        'walletId',
        'O ID da carteira não pode ficar vazio.',
      );
    }

    return _firestore
        .collection(_walletsCollection)
        .doc(normalizedWalletId)
        .collection(_settlementsCollectionName);
  }

  void _validateIndividualWalletOwnership({
    required DocumentSnapshot<Map<String, dynamic>> document,
    required String expectedOwnerId,
    required String role,
  }) {
    if (!document.exists || document.data() == null) {
      throw StateError(
        'Carteira individual de $role não encontrada.',
      );
    }

    final data = document.data()!;
    final ownerId = data['ownerId']?.toString().trim() ?? '';
    final type = data['type']?.toString().trim() ?? '';

    if (type != 'individual') {
      throw StateError(
        'A carteira de $role precisa ser individual.',
      );
    }

    if (ownerId != expectedOwnerId.trim()) {
      throw StateError(
        'A carteira de $role não pertence ao membro esperado.',
      );
    }
  }

  Future<void> _validateWalletAccess({
    required String walletId,
    required String userId,
  }) async {
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      throw ArgumentError.value(
        walletId,
        'walletId',
        'O ID da carteira não pode ficar vazio.',
      );
    }

    final walletDocument = await _firestore
        .collection(_walletsCollection)
        .doc(normalizedWalletId)
        .get();

    if (!walletDocument.exists ||
        walletDocument.data() == null) {
      throw StateError('Carteira não encontrada.');
    }

    final walletData = walletDocument.data()!;
    final memberIds = _parseMemberIds(
      walletData['memberIds'],
    );
    final ownerId =
        walletData['ownerId']?.toString().trim() ?? '';

    final hasAccess =
        ownerId == userId || memberIds.contains(userId);

    if (!hasAccess) {
      throw StateError(
        'O usuário autenticado não participa desta carteira.',
      );
    }
  }

  String _requireAuthenticatedUserId() {
    final userId = _auth.currentUser?.uid.trim();

    if (userId == null || userId.isEmpty) {
      throw StateError(
        'É necessário estar autenticado para acessar os acertos.',
      );
    }

    return userId;
  }

  List<String> _parseMemberIds(dynamic value) {
    if (value is! Iterable) {
      return [];
    }

    return value
        .map((memberId) => memberId.toString().trim())
        .where((memberId) => memberId.isNotEmpty)
        .toList(growable: false);
  }
}