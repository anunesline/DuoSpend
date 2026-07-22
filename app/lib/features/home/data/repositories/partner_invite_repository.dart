import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../auth/data/repositories/user_repository.dart';
import '../models/partner_invite_model.dart';

class PartnerInviteRepository {
  static const String _collection = 'partnerInvites';
  static const String _walletsCollection = 'wallets';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserRepository _userRepository;

  PartnerInviteRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    UserRepository? userRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _userRepository = userRepository ?? UserRepository();

  String? get currentUserId => _auth.currentUser?.uid;

  String? get currentUserEmail => _auth.currentUser?.email;

  Future<PartnerInviteModel> createInvite({
    required String walletId,
    required String invitedEmail,
    DateTime? expiresAt,
  }) async {
    final userId = _requireAuthenticatedUserId();
    final normalizedWalletId = walletId.trim();
    final normalizedEmail = invitedEmail.trim().toLowerCase();

    if (normalizedWalletId.isEmpty) {
      throw ArgumentError.value(
        walletId,
        'walletId',
        'A carteira do convite não pode ficar vazia.',
      );
    }

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
      walletId: normalizedWalletId,
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

  Future<String> getInviterDisplayName(
    PartnerInviteModel invite,
  ) async {
    final inviterUserId = invite.inviterUserId.trim();

    if (inviterUserId.isEmpty) {
      return 'Usuário do DuoSpend';
    }

    final displayName = await _userRepository.getUserDisplayName(
      inviterUserId,
    );

    if (displayName == null || displayName.trim().isEmpty) {
      return inviterUserId;
    }

    return displayName.trim();
  }

  Future<void> acceptInvite(
    PartnerInviteModel invite,
  ) async {
    final user = _requireAuthenticatedUser();
    final normalizedUserEmail =
        user.email?.trim().toLowerCase() ?? '';
    final normalizedInviteId = invite.id.trim();
    final normalizedWalletId = invite.walletId.trim();

    if (normalizedUserEmail.isEmpty) {
      throw StateError(
        'A conta autenticada não possui um e-mail válido.',
      );
    }

    if (normalizedInviteId.isEmpty) {
      throw ArgumentError.value(
        invite.id,
        'invite.id',
        'O convite precisa possuir um ID.',
      );
    }

    if (normalizedWalletId.isEmpty) {
      throw ArgumentError.value(
        invite.walletId,
        'invite.walletId',
        'O convite não possui uma carteira válida.',
      );
    }

    final inviteReference = _firestore
        .collection(_collection)
        .doc(normalizedInviteId);

    final walletReference = _firestore
        .collection(_walletsCollection)
        .doc(normalizedWalletId);

    await _firestore.runTransaction((transaction) async {
      final inviteDocument = await transaction.get(inviteReference);

      if (!inviteDocument.exists || inviteDocument.data() == null) {
        throw StateError('Convite não encontrado.');
      }

      final storedInvite = _inviteFromDocument(inviteDocument);
      final storedInvitedEmail =
          storedInvite.invitedEmail.trim().toLowerCase();

      if (storedInvite.status != PartnerInviteStatus.pending) {
        throw StateError(
          'Este convite não está mais disponível para aceite.',
        );
      }

      if (storedInvite.isExpired) {
        throw StateError('Este convite expirou.');
      }

      if (storedInvitedEmail != normalizedUserEmail) {
        throw StateError(
          'Este convite foi enviado para outra conta.',
        );
      }

      if (storedInvite.walletId.trim() != normalizedWalletId) {
        throw StateError(
          'O convite não corresponde à carteira informada.',
        );
      }

      final walletDocument = await transaction.get(walletReference);

      if (!walletDocument.exists || walletDocument.data() == null) {
        throw StateError(
          'A carteira compartilhada não foi encontrada.',
        );
      }

      final walletData = walletDocument.data()!;
      final walletType =
          walletData['type']?.toString().trim().toLowerCase() ?? '';
      final ownerId =
          walletData['ownerId']?.toString().trim() ?? '';

      if (walletType != 'shared') {
        throw StateError(
          'O convite não pertence a uma carteira compartilhada.',
        );
      }

      if (ownerId.isEmpty ||
          ownerId != storedInvite.inviterUserId.trim()) {
        throw StateError(
          'O responsável pelo convite não corresponde '
          'ao responsável pela carteira.',
        );
      }

      final acceptedInvite = storedInvite.accept(
        userId: user.uid,
      );

      transaction.update(walletReference, {
        'memberIds': FieldValue.arrayUnion([user.uid]),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      transaction.set(
        inviteReference,
        acceptedInvite.toMap(),
        SetOptions(merge: true),
      );
    });
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
    final normalizedInviteId = inviteId.trim();

    if (normalizedInviteId.isEmpty) {
      return null;
    }

    final snapshot = await _firestore
        .collection(_collection)
        .doc(normalizedInviteId)
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

  User _requireAuthenticatedUser() {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }

    return user;
  }

  String _requireAuthenticatedUserId() {
    return _requireAuthenticatedUser().uid;
  }
}