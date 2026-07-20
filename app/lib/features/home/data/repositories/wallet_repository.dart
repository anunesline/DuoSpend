import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/wallet_model.dart';

class WalletRepository {
  static const String _usersCollection = 'users';
  static const String _walletsCollection = 'wallets';
  static const String _mainWalletId = 'principal';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  WalletRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId {
    return _auth.currentUser?.uid;
  }

  Future<WalletModel?> getMainWallet() async {
    final userId = currentUserId;

    if (userId == null) {
      return null;
    }

    final modernWallet = await _getModernMainWallet(userId);

    if (modernWallet != null) {
      return modernWallet;
    }

    return _getLegacyMainWallet(userId);
  }

  Future<List<WalletModel>> getUserWallets() async {
    final userId = currentUserId;

    if (userId == null) {
      return [];
    }

    final walletsSnapshot = await _firestore
        .collection(_walletsCollection)
        .where('memberIds', arrayContains: userId)
        .get();

    final wallets = walletsSnapshot.docs
        .map(_walletFromDocument)
        .toList(growable: true);

    final legacyMainWallet = await _getLegacyMainWallet(userId);

    if (legacyMainWallet != null &&
        !wallets.any((wallet) => wallet.id == legacyMainWallet.id)) {
      wallets.insert(0, legacyMainWallet);
    }

    wallets.sort(_compareWallets);

    return List<WalletModel>.unmodifiable(wallets);
  }

  Future<List<WalletModel>> getIndividualWallets() async {
    final wallets = await getUserWallets();

    return List<WalletModel>.unmodifiable(
      wallets.where((wallet) => wallet.isIndividual),
    );
  }

  Future<List<WalletModel>> getSharedWallets() async {
    final wallets = await getUserWallets();

    return List<WalletModel>.unmodifiable(
      wallets.where((wallet) => wallet.isShared),
    );
  }

  Future<WalletModel?> getWalletById(String walletId) async {
    final userId = currentUserId;
    final normalizedWalletId = walletId.trim();

    if (userId == null || normalizedWalletId.isEmpty) {
      return null;
    }

    if (normalizedWalletId == _mainWalletId) {
      final mainWallet = await getMainWallet();

      if (mainWallet != null && mainWallet.hasMember(userId)) {
        return mainWallet;
      }

      return null;
    }

    final walletDocument = await _firestore
        .collection(_walletsCollection)
        .doc(normalizedWalletId)
        .get();

    if (!walletDocument.exists || walletDocument.data() == null) {
      return null;
    }

    final wallet = _walletFromDocument(walletDocument);

    if (!wallet.hasMember(userId)) {
      return null;
    }

    return wallet;
  }

  Future<WalletModel> createWallet({
    required String name,
    required WalletType type,
    double initialBalance = 0,
    List<String> memberIds = const [],
  }) async {
    final userId = _requireAuthenticatedUserId();
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'O nome da carteira não pode ficar vazio.',
      );
    }

    final walletDocument = _firestore.collection(_walletsCollection).doc();

    final normalizedMemberIds = _normalizeMemberIds(
      ownerId: userId,
      memberIds: memberIds,
    );

    final now = DateTime.now();

    final wallet = WalletModel(
      id: walletDocument.id,
      name: normalizedName,
      balance: initialBalance,
      type: type,
      ownerId: userId,
      memberIds: normalizedMemberIds,
      createdAt: now,
      updatedAt: now,
    );

    await walletDocument.set(wallet.toMap());

    return wallet;
  }

  Future<void> saveWallet(WalletModel wallet) async {
    final userId = _requireAuthenticatedUserId();

    if (wallet.id.trim().isEmpty) {
      throw ArgumentError.value(
        wallet.id,
        'wallet.id',
        'A carteira precisa possuir um ID.',
      );
    }

    if (!wallet.hasMember(userId)) {
      throw StateError('O usuário autenticado não participa desta carteira.');
    }

    final normalizedWallet = wallet.copyWith(
      ownerId: wallet.ownerId.isEmpty ? userId : wallet.ownerId,
      memberIds: _normalizeMemberIds(
        ownerId: wallet.ownerId.isEmpty ? userId : wallet.ownerId,
        memberIds: wallet.memberIds,
      ),
      updatedAt: DateTime.now(),
    );

    if (_isLegacyMainWallet(normalizedWallet)) {
      await _legacyMainWalletReference(
        userId,
      ).set(normalizedWallet.toMap(), SetOptions(merge: true));

      return;
    }

    await _firestore
        .collection(_walletsCollection)
        .doc(normalizedWallet.id)
        .set(normalizedWallet.toMap(), SetOptions(merge: true));
  }

  Future<void> updateWallet(WalletModel wallet) async {
    await saveWallet(wallet);
  }

  Future<void> updateBalance(
    double balance, {
    String walletId = _mainWalletId,
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

    final updateData = <String, dynamic>{
      'balance': balance,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (normalizedWalletId == _mainWalletId) {
      final modernWallet = await _getModernMainWallet(userId);

      if (modernWallet != null) {
        await _firestore
            .collection(_walletsCollection)
            .doc(modernWallet.id)
            .update(updateData);

        return;
      }

      await _legacyMainWalletReference(userId).update(updateData);

      return;
    }

    final wallet = await getWalletById(normalizedWalletId);

    if (wallet == null) {
      throw StateError('Carteira não encontrada ou usuário sem acesso.');
    }

    await _firestore
        .collection(_walletsCollection)
        .doc(normalizedWalletId)
        .update(updateData);
  }

  Future<void> addMember({
    required String walletId,
    required String memberId,
  }) async {
    final userId = _requireAuthenticatedUserId();
    final wallet = await getWalletById(walletId);
    final normalizedMemberId = memberId.trim();

    if (wallet == null) {
      throw StateError('Carteira não encontrada.');
    }

    if (!wallet.isShared) {
      throw StateError(
        'Somente carteiras compartilhadas podem receber membros.',
      );
    }

    if (wallet.ownerId != userId) {
      throw StateError(
        'Somente o responsável pela carteira pode adicionar membros.',
      );
    }

    if (normalizedMemberId.isEmpty) {
      throw ArgumentError.value(
        memberId,
        'memberId',
        'O ID do membro não pode ficar vazio.',
      );
    }

    await _firestore.collection(_walletsCollection).doc(wallet.id).update({
      'memberIds': FieldValue.arrayUnion([normalizedMemberId]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeMember({
    required String walletId,
    required String memberId,
  }) async {
    final userId = _requireAuthenticatedUserId();
    final wallet = await getWalletById(walletId);
    final normalizedMemberId = memberId.trim();

    if (wallet == null) {
      throw StateError('Carteira não encontrada.');
    }

    if (!wallet.isShared) {
      throw StateError(
        'Somente carteiras compartilhadas possuem múltiplos membros.',
      );
    }

    if (wallet.ownerId != userId) {
      throw StateError(
        'Somente o responsável pela carteira pode remover membros.',
      );
    }

    if (normalizedMemberId == wallet.ownerId) {
      throw StateError('O responsável pela carteira não pode ser removido.');
    }

    if (normalizedMemberId.isEmpty) {
      throw ArgumentError.value(
        memberId,
        'memberId',
        'O ID do membro não pode ficar vazio.',
      );
    }

    await _firestore.collection(_walletsCollection).doc(wallet.id).update({
      'memberIds': FieldValue.arrayRemove([normalizedMemberId]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<WalletModel?> _getModernMainWallet(String userId) async {
    final snapshot = await _firestore
        .collection(_walletsCollection)
        .where('ownerId', isEqualTo: userId)
        .where('type', isEqualTo: WalletType.individual.value)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return _walletFromDocument(snapshot.docs.first);
  }

  Future<WalletModel?> _getLegacyMainWallet(String userId) async {
    final document = await _legacyMainWalletReference(userId).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    final data = Map<String, dynamic>.from(document.data()!);

    data['id'] = data['id']?.toString().trim().isNotEmpty == true
        ? data['id']
        : _mainWalletId;

    data['type'] = WalletType.individual.value;
    data['ownerId'] = data['ownerId']?.toString().trim().isNotEmpty == true
        ? data['ownerId']
        : userId;

    data['memberIds'] = _normalizeMemberIds(
      ownerId: data['ownerId'].toString(),
      memberIds: _parseMemberIds(data['memberIds']),
    );

    return WalletModel.fromMap(data);
  }

  DocumentReference<Map<String, dynamic>> _legacyMainWalletReference(
    String userId,
  ) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_walletsCollection)
        .doc(_mainWalletId);
  }

  WalletModel _walletFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = Map<String, dynamic>.from(document.data() ?? {});

    if (data['id']?.toString().trim().isEmpty ?? true) {
      data['id'] = document.id;
    }

    return WalletModel.fromMap(data);
  }

  bool _isLegacyMainWallet(WalletModel wallet) {
    return wallet.id == _mainWalletId && wallet.isIndividual;
  }

  String _requireAuthenticatedUserId() {
    final userId = currentUserId;

    if (userId == null) {
      throw StateError(
        'É necessário estar autenticado para acessar carteiras.',
      );
    }

    return userId;
  }

  List<String> _normalizeMemberIds({
    required String ownerId,
    required Iterable<String> memberIds,
  }) {
    final normalizedMemberIds = <String>[];

    void addMemberId(String value) {
      final normalizedValue = value.trim();

      if (normalizedValue.isNotEmpty &&
          !normalizedMemberIds.contains(normalizedValue)) {
        normalizedMemberIds.add(normalizedValue);
      }
    }

    addMemberId(ownerId);

    for (final memberId in memberIds) {
      addMemberId(memberId);
    }

    return List<String>.unmodifiable(normalizedMemberIds);
  }

  List<String> _parseMemberIds(dynamic value) {
    if (value is! Iterable) {
      return [];
    }

    return value.map((memberId) => memberId.toString()).toList(growable: false);
  }

  int _compareWallets(WalletModel first, WalletModel second) {
    if (first.isIndividual != second.isIndividual) {
      return first.isIndividual ? -1 : 1;
    }

    return first.name.toLowerCase().compareTo(second.name.toLowerCase());
  }
}
