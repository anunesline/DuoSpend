import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/partner_invite_model.dart';

class PartnerInviteRepository {
  static const String _collection = 'partnerInvites';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PartnerInviteRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  String? get currentUserEmail => _auth.currentUser?.email;

  Future<PartnerInviteModel> createInvite({
    required String walletId,
    required String invitedEmail,
    DateTime? expiresAt,
  }) async {
    final userId = _requireAuthenticatedUserId();

    final normalizedEmail = invitedEmail.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      throw ArgumentError.value(
        invitedEmail,
        'invitedEmail',
        'Informe um e-mail válido.',
      );
    }

    final document = _firestore.collection(_collection).doc();

    final now = DateTime.now();

    final invite = PartnerInviteModel(
      id: document.id,
      walletId: walletId,
      inviterUserId: userId,
      invitedEmail: normalizedEmail,
      expiresAt: expiresAt,
      createdAt: now,
      updatedAt: now,
    );

    await document.set(invite.toMap());

    return invite;
  }

  Future<List<PartnerInviteModel>> getSentInvites() async {
    final userId = _requireAuthenticatedUserId();

    final snapshot = await _firestore
        .collection(_collection)
        .where('inviterUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(_inviteFromDocument)
        .toList(growable: false);
  }

  Future<List<PartnerInviteModel>> getReceivedInvites() async {
    final email = currentUserEmail?.trim().toLowerCase();

    if (email == null || email.isEmpty) {
      return [];
    }

    final snapshot = await _firestore
        .collection(_collection)
        .where('invitedEmail', isEqualTo: email)
        .where(
          'status',
          isEqualTo: PartnerInviteStatus.pending.value,
        )
        .get();

    return snapshot.docs
        .map(_inviteFromDocument)
        .toList(growable: false);
  }

  Future<void> acceptInvite(
    PartnerInviteModel invite,
  ) async {
    final userId = _requireAuthenticatedUserId();

    final acceptedInvite = invite.accept(
      userId: userId,
    );

    await _firestore
        .collection(_collection)
        .doc(invite.id)
        .set(
          acceptedInvite.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> declineInvite(
    PartnerInviteModel invite,
  ) async {
    final declinedInvite = invite.decline();

    await _firestore
        .collection(_collection)
        .doc(invite.id)
        .set(
          declinedInvite.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> cancelInvite(
    PartnerInviteModel invite,
  ) async {
    final cancelledInvite = invite.cancel();

    await _firestore
        .collection(_collection)
        .doc(invite.id)
        .set(
          cancelledInvite.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<PartnerInviteModel?> getInviteById(
    String inviteId,
  ) async {
    final snapshot = await _firestore
        .collection(_collection)
        .doc(inviteId)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return _inviteFromDocument(snapshot);
  }

  PartnerInviteModel _inviteFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = Map<String, dynamic>.from(
      document.data() ?? {},
    );

    data['id'] ??= document.id;

    return PartnerInviteModel.fromMap(data);
  }

  String _requireAuthenticatedUserId() {
    final userId = currentUserId;

    if (userId == null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return userId;
  }
}