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

    if (normalizedTransactionId.isEmpty) {
      throw ArgumentError.value(
        transactionId,
        'transactionId',
        'O ID da transação do acerto não pode ficar vazio.',
      );
    }

    await _validateWalletAccess(
      walletId: settlement.walletId,
      userId: userId,
    );

    final updatedSettlement = settlement.confirmReceipt(
      confirmedByMemberId: userId,
      confirmedAt: confirmedAt ?? DateTime.now(),
      transactionId: normalizedTransactionId,
      receiverWalletId: receiverWalletId,
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