import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrbitResetRequest {
  final String id;
  final String walletId;
  final List<String> confirmedBy;
  final String status;

  const OrbitResetRequest({
    required this.id,
    required this.walletId,
    required this.confirmedBy,
    required this.status,
  });

  bool hasConfirmed(String userId) => confirmedBy.contains(userId);

  factory OrbitResetRequest.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return OrbitResetRequest(
      id: document.id,
      walletId: data['walletId']?.toString() ?? '',
      confirmedBy: List<String>.from(data['confirmedBy'] as List? ?? const []),
      status: data['status']?.toString() ?? 'pending',
    );
  }
}

class OrbitResetService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  OrbitResetService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : firestore = firestore ?? FirebaseFirestore.instance,
      auth = auth ?? FirebaseAuth.instance;

  String get _userId {
    final id = auth.currentUser?.uid.trim();
    if (id == null || id.isEmpty) throw StateError('Usuário não autenticado.');
    return id;
  }

  Future<void> resetMyData() async {
    final userId = _userId;
    final user = firestore.collection('users').doc(userId);

    for (final name in const [
      'transactions',
      'budgets',
      'purchases',
      'products',
      'merchant_memory',
    ]) {
      await _deleteCollection(user.collection(name));
    }

    // Legacy/main individual wallet: keep the document, reset its balance.
    final principal = user.collection('wallets').doc('principal');
    if ((await principal.get()).exists) {
      await principal.set({
        'balance': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }

    // Individual wallets stored at the top level.
    final ownedWallets = await firestore
        .collection('wallets')
        .where('ownerId', isEqualTo: userId)
        .get();
    for (final wallet in ownedWallets.docs) {
      if (wallet.data()['type']?.toString() != 'individual') continue;
      await _deleteCollection(wallet.reference.collection('transactions'));
      await _deleteCollection(wallet.reference.collection('budgets'));
      await _deleteCollection(wallet.reference.collection('settlements'));
      await wallet.reference.delete();
    }

    // Cards are individual by owner.
    final cards = await firestore
        .collection('creditCards')
        .where('ownerMemberId', isEqualTo: userId)
        .get();
    for (final card in cards.docs) {
      await _deleteCollection(card.reference.collection('invoices'));
      await _deleteCollection(card.reference.collection('charges'));
      await card.reference.delete();
    }

    // Only individual goals. Shared goals are intentionally preserved.
    final goals = await firestore
        .collection('savingsGoals')
        .where('createdByUserId', isEqualTo: userId)
        .get();
    for (final goal in goals.docs) {
      final members = List<String>.from(
        goal.data()['memberIds'] as List? ?? const [],
      );
      if (members.length > 1) continue;
      await _deleteCollection(goal.reference.collection('movements'));
      await goal.reference.delete();
    }

    // Individual routines/tasks use the user's UID as their scope.
    await _deleteWhere('household_routines', 'scopeId', userId);
    await _deleteWhere('household_tasks', 'scopeId', userId);
  }

  Future<void> resetSharedDataForTesting(String walletId) async {
    final userId = _userId;
    final wallet = await firestore.collection('wallets').doc(walletId).get();
    final members = List<String>.from(
      wallet.data()?['memberIds'] as List? ?? const [],
    );

    if (!wallet.exists || !members.contains(userId)) {
      throw StateError('Usuário não participa deste Orbit a Dois.');
    }

    await _resetSharedData(walletId);
  }

  Future<OrbitResetRequest?> getPendingSharedReset(String walletId) async {
    await _sharedMemberIds(walletId);
    final snapshot = await firestore
        .collection('wallets')
        .doc(walletId)
        .collection('resetRequests')
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return OrbitResetRequest.fromDocument(snapshot.docs.first);
  }

  Future<void> requestSharedReset({
    required String walletId,
    required List<String> memberIds,
  }) async {
    final userId = _userId;
    final authorizedMembers = await _sharedMemberIds(walletId);
    if (!_sameMembers(memberIds, authorizedMembers)) {
      throw StateError('Os membros do Orbit a Dois não conferem.');
    }
    final existing = await getPendingSharedReset(walletId);
    if (existing != null) {
      if (!existing.hasConfirmed(userId)) {
        await confirmSharedReset(
          walletId: walletId,
          requestId: existing.id,
          memberIds: authorizedMembers,
        );
      }
      return;
    }
    final reference = firestore
        .collection('wallets')
        .doc(walletId)
        .collection('resetRequests')
        .doc();
    await reference.set({
      'walletId': walletId,
      'requestedBy': userId,
      'memberIds': authorizedMembers,
      'confirmedBy': [userId],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> confirmSharedReset({
    required String walletId,
    required String requestId,
    required List<String> memberIds,
  }) async {
    final userId = _userId;
    final authorizedMembers = await _sharedMemberIds(walletId);
    if (!_sameMembers(memberIds, authorizedMembers)) {
      throw StateError('Os membros do Orbit a Dois não conferem.');
    }

    final request = firestore
        .collection('wallets')
        .doc(walletId)
        .collection('resetRequests')
        .doc(requestId);

    final shouldReset = await firestore.runTransaction<bool>((
      transaction,
    ) async {
      final snapshot = await transaction.get(request);
      if (!snapshot.exists || snapshot.data()?['status'] != 'pending') {
        return false;
      }
      final confirmed = List<String>.from(
        snapshot.data()?['confirmedBy'] as List? ?? const [],
      );
      if (!confirmed.contains(userId)) confirmed.add(userId);
      final allConfirmed = authorizedMembers.every(confirmed.contains);
      transaction.update(request, {
        'confirmedBy': confirmed,
        'status': allConfirmed ? 'approved' : 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return allConfirmed;
    });

    if (shouldReset) {
      await _resetSharedData(walletId);
      await request.update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    }
    return shouldReset;
  }

  Future<void> cancelSharedReset({
    required String walletId,
    required String requestId,
  }) async {
    await _sharedMemberIds(walletId);
    await firestore
        .collection('wallets')
        .doc(walletId)
        .collection('resetRequests')
        .doc(requestId)
        .update({
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<List<String>> _sharedMemberIds(String walletId) async {
    final userId = _userId;
    final wallet = await firestore.collection('wallets').doc(walletId).get();
    final members =
        List<String>.from(wallet.data()?['memberIds'] as List? ?? const [])
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList(growable: false);
    if (!wallet.exists || members.length < 2 || !members.contains(userId)) {
      throw StateError('Usuário não participa deste Orbit a Dois.');
    }
    return members;
  }

  bool _sameMembers(List<String> first, List<String> second) =>
      first
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .containsAll(second) &&
      second.toSet().containsAll(
        first.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet(),
      );

  Future<void> _resetSharedData(String walletId) async {
    final wallet = firestore.collection('wallets').doc(walletId);
    await _deleteCollection(wallet.collection('transactions'));
    await _deleteCollection(wallet.collection('budgets'));
    await _deleteCollection(wallet.collection('settlements'));
    await _deleteWhere('household_routines', 'scopeId', walletId);
    await _deleteWhere('household_tasks', 'scopeId', walletId);

    final goals = await firestore
        .collection('savingsGoals')
        .where('walletId', isEqualTo: walletId)
        .get();
    for (final goal in goals.docs) {
      await _deleteCollection(goal.reference.collection('movements'));
      await goal.reference.delete();
    }

    // Preserve the couple connection itself; only shared product data is reset.
    await wallet.set({
      'balance': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteWhere(
    String collection,
    String field,
    String value,
  ) async {
    final snapshot = await firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .get();
    await _deleteDocuments(snapshot.docs);
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(400).get();
      if (snapshot.docs.isEmpty) return;
      await _deleteDocuments(snapshot.docs);
      if (snapshot.docs.length < 400) return;
    }
  }

  Future<void> _deleteDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) async {
    if (documents.isEmpty) return;
    final batch = firestore.batch();
    for (final document in documents) {
      batch.delete(document.reference);
    }
    await batch.commit();
  }
}
