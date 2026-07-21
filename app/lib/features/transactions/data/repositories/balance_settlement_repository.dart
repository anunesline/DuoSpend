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

    final snapshot = await _settlementsCollection(normalizedWalletId)
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

  Future<List<BalanceSettlementModel>> getPendingSettlements({
    required String walletId,
  }) async {
    final settlements = await getSettlements(
      walletId: walletId,
    );

    return settlements
        .where((settlement) => settlement.isPending)
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
    final normalizedSettlementId = settlementId.trim();

    if (normalizedSettlementId.isEmpty) {
      throw ArgumentError.value(
        settlementId,
        'settlementId',
        'O ID do acerto não pode ficar vazio.',
      );
    }

    await _validateWalletAccess(
      walletId: walletId,
      userId: userId,
    );

    await _settlementsCollection(walletId)
        .doc(normalizedSettlementId)
        .delete();
  }

  CollectionReference<Map<String, dynamic>> _settlementsCollection(
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

    if (!walletDocument.exists || walletDocument.data() == null) {
      throw StateError('Carteira não encontrada.');
    }

    final walletData = walletDocument.data()!;
    final memberIds = _parseMemberIds(walletData['memberIds']);
    final ownerId = walletData['ownerId']?.toString().trim() ?? '';

    final hasAccess =
        ownerId == userId || memberIds.contains(userId);

    if (!hasAccess) {
      throw StateError(
        'O usuário autenticado não participa desta carteira.',
      );
    }
  }

  String _requireAuthenticatedUserId() {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
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