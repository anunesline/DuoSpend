import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../home/data/models/wallet_model.dart';
import '../../domain/models/budget.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  static const _collection = 'budgets';
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BudgetRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String createId() => _firestore.collection(_collection).doc().id;

  Future<void> create({required Budget budget, required WalletModel wallet}) async {
    final userId = _requireUserId();
    _validateWalletAccess(wallet, userId, requiresOwner: wallet.isShared);
    if (budget.walletId.trim() != wallet.id.trim() || budget.createdByUserId.trim() != userId) {
      throw StateError('Dados do orçamento não pertencem ao contexto atual.');
    }
    await _referenceFor(wallet, userId).doc(budget.id).set(BudgetModel.toMap(budget));
  }

  Future<List<Budget>> getByWallet({required WalletModel wallet}) async {
    final userId = _requireUserId();
    _validateWalletAccess(wallet, userId);
    final snapshot = await _referenceFor(wallet, userId).get();
    final budgets = snapshot.docs.map((document) => BudgetModel.fromMap(document.data(), documentId: document.id)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(budgets);
  }

  Future<Budget> update({required Budget budget, required WalletModel wallet}) async {
    final userId = _requireUserId();
    _validateWalletAccess(wallet, userId, requiresOwner: wallet.isShared);
    final reference = _referenceFor(wallet, userId).doc(budget.id);
    return _firestore.runTransaction((transaction) async {
      final document = await transaction.get(reference);
      if (!document.exists || document.data() == null) throw StateError('Orçamento não encontrado.');
      final persisted = BudgetModel.fromMap(document.data()!, documentId: document.id);
      if (persisted.createdByUserId != userId) throw StateError('Somente o responsável pelo orçamento pode alterá-lo.');
      if (persisted.walletId != wallet.id) throw StateError('O orçamento não pertence à carteira.');
      transaction.set(reference, BudgetModel.toMap(budget), SetOptions(merge: true));
      return budget;
    });
  }

  Future<Budget> changeStatus({required Budget budget, required BudgetStatus status, required WalletModel wallet}) {
    return update(budget: budget.copyWith(status: status, updatedAt: DateTime.now()), wallet: wallet);
  }

  CollectionReference<Map<String, dynamic>> _referenceFor(WalletModel wallet, String userId) {
    if (wallet.isShared) return _firestore.collection('wallets').doc(wallet.id).collection(_collection);
    return _firestore.collection('users').doc(userId).collection(_collection);
  }

  void _validateWalletAccess(WalletModel wallet, String userId, {bool requiresOwner = false}) {
    if (!wallet.hasMember(userId)) throw StateError('Usuário sem acesso à carteira do orçamento.');
    if (requiresOwner && !wallet.isOwner(userId)) throw StateError('Somente o proprietário da carteira compartilhada pode alterar orçamentos.');
  }

  String _requireUserId() {
    final userId = _auth.currentUser?.uid.trim();
    if (userId == null || userId.isEmpty) throw StateError('Usuário não autenticado.');
    return userId;
  }
}
