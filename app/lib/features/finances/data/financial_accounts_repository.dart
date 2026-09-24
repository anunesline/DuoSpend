import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../home/data/models/wallet_model.dart';
import '../../home/data/repositories/wallet_repository.dart';
import '../../transactions/data/models/transaction_model.dart';

class AccountTransfer {
  final String id;
  final String fromId;
  final String toId;
  final String fromName;
  final String toName;
  final double amount;
  final DateTime date;
  const AccountTransfer({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.fromName,
    required this.toName,
    required this.amount,
    required this.date,
  });
  factory AccountTransfer.fromMap(String id, Map<String, dynamic> data) =>
      AccountTransfer(
        id: id,
        fromId: data['fromId'] as String,
        toId: data['toId'] as String,
        fromName: data['fromName'] as String,
        toName: data['toName'] as String,
        amount: (data['amount'] as num).toDouble(),
        date: DateTime.parse(data['date'] as String),
      );
}

/// Account metadata extends existing wallets. Transfers have their own journal:
/// moving money between owned accounts is neither income nor spending.
class FinancialAccountsRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  late final WalletRepository wallets = WalletRepository(
    firestore: firestore,
    auth: auth,
  );
  FinancialAccountsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       auth = auth ?? FirebaseAuth.instance;

  String get userId {
    final id = auth.currentUser?.uid;
    if (id == null) throw StateError('Entre na sua conta para continuar.');
    return id;
  }

  DocumentReference<Map<String, dynamic>> _account(String id) =>
      id == 'principal'
      ? firestore.collection('users').doc(userId).collection('wallets').doc(id)
      : firestore.collection('wallets').doc(id);
  DocumentReference<Map<String, dynamic>> get _profile =>
      firestore.collection('users').doc(userId);

  Future<List<WalletModel>> loadAccounts() async =>
      (await wallets.getAllUserWallets())
          .where((w) => w.isIndividual && w.isOwner(userId))
          .toList();
  Future<String?> loadPrimaryId() async =>
      (await _profile.get()).data()?['primaryWalletId']?.toString();

  WalletModel _owned(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    bool active = true,
  }) {
    if (!doc.exists || doc.data() == null)
      throw StateError('Conta não encontrada.');
    final data = Map<String, dynamic>.from(doc.data()!)..['id'] = doc.id;
    if (doc.reference.path == 'users/$userId/wallets/principal') {
      if (data['ownerId'] == null || data['ownerId'] == '')
        data['ownerId'] = userId;
      data['type'] = 'individual';
    }
    data['createdAt'] ??= DateTime.fromMillisecondsSinceEpoch(0)
        .toIso8601String();
    final wallet = WalletModel.fromMap(data);
    if (!wallet.isIndividual || !wallet.isOwner(userId)) {
      throw StateError('Esta conta não pertence ao usuário.');
    }
    if (active && wallet.isArchived)
      throw StateError('Esta conta está arquivada.');
    return wallet;
  }

  Future<WalletModel> save({
    String? id,
    String? creationId,
    required String name,
    required AccountKind kind,
    required String bank,
    required String holder,
    required String pix,
    double initialBalance = 0,
    bool primary = false,
  }) async {
    if (name.trim().isEmpty || holder.trim().isEmpty) {
      throw ArgumentError('Informe o nome da conta e o titular.');
    }
    if (kind == AccountKind.bank && bank.trim().isEmpty)
      throw ArgumentError('Informe o banco.');
    if (!initialBalance.isFinite)
      throw ArgumentError('Informe um saldo válido.');
    final ref = id == null
        ? firestore.collection('wallets').doc(creationId)
        : _account(id);
    return firestore.runTransaction((tx) async {
      final document = await tx.get(ref);
      if (id == null && document.exists) {
        // Retry after an ambiguous network error must not create a second account.
        return _owned(document);
      }
      final previous = id == null ? null : _owned(document);
      final now = DateTime.now();
      final result =
          previous?.copyWith(
            name: name.trim(),
            accountKind: kind,
            bank: kind == AccountKind.bank ? bank.trim() : '',
            holder: holder.trim(),
            pix: pix.trim(),
            updatedAt: now,
          ) ??
          WalletModel(
            id: ref.id,
            name: name.trim(),
            balance: initialBalance,
            ownerId: userId,
            accountKind: kind,
            bank: kind == AccountKind.bank ? bank.trim() : '',
            holder: holder.trim(),
            pix: pix.trim(),
            createdAt: now,
            updatedAt: now,
          );
      // Metadata edits never overwrite a balance read before the transaction.
      tx.set(ref, result.toMap(), SetOptions(merge: true));
      if (primary)
        tx.set(_profile, {
          'primaryWalletId': result.id,
        }, SetOptions(merge: true));
      return result;
    });
  }

  Future<void> setPrimary(String id) async {
    final ref = _account(id);
    await firestore.runTransaction((tx) async {
      _owned(await tx.get(ref));
      tx.set(_profile, {'primaryWalletId': id}, SetOptions(merge: true));
    });
  }

  Future<void> setArchived(String id, bool archived) async {
    final ref = _account(id);
    await firestore.runTransaction((tx) async {
      _owned(await tx.get(ref), active: false);
      final profile = await tx.get(_profile);
      tx.update(ref, {
        'isArchived': archived,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (archived && profile.data()?['primaryWalletId'] == id) {
        tx.set(_profile, {
          'primaryWalletId': FieldValue.delete(),
        }, SetOptions(merge: true));
      }
    });
  }

  String newOperationId() => _profile.collection('accountOperations').doc().id;

  void _validateAmount(double amount) {
    if (!amount.isFinite ||
        amount <= 0 ||
        (amount * 100 - (amount * 100).round()).abs() > .000001) {
      throw ArgumentError(
        'Informe um valor positivo com até duas casas decimais.',
      );
    }
  }

  /// The caller reuses operationId after errors, including an ambiguous timeout.
  Future<void> deposit({
    required String id,
    required double amount,
    required String operationId,
  }) async {
    _validateAmount(amount);
    final account = _account(id);
    final entry = _profile
        .collection('transactions')
        .doc('deposit_$operationId');
    await firestore.runTransaction((tx) async {
      final previous = await tx.get(entry);
      final wallet = _owned(await tx.get(account));
      if (previous.exists) {
        if (previous.data()?['walletId'] != id ||
            previous.data()?['value'] != amount) {
          throw StateError('Operação já utilizada com outros dados.');
        }
        return;
      }
      final now = DateTime.now();
      tx.update(account, {
        'balance': wallet.balance + amount,
        'updatedAt': now.toIso8601String(),
      });
      tx.set(
        entry,
        TransactionModel(
          id: entry.id,
          description: 'Depósito em ${wallet.name}',
          value: amount,
          type: 'income',
          date: now,
          walletId: id,
          paidByMemberId: userId,
          category: 'Outras receitas',
          subcategory: 'Depósito',
          paymentMethod: 'other',
          financialSettledAt: now,
        ).toMap(),
      );
    });
  }

  Future<void> transfer({
    required String fromId,
    required String toId,
    required double amount,
    required String operationId,
  }) async {
    _validateAmount(amount);
    if (fromId == toId) throw ArgumentError('Escolha outra conta de destino.');
    final from = _account(fromId);
    final to = _account(toId);
    final entry = _profile.collection('accountTransfers').doc(operationId);
    await firestore.runTransaction((tx) async {
      final previous = await tx.get(entry);
      final source = _owned(await tx.get(from));
      final destination = _owned(await tx.get(to));
      if (previous.exists) {
        final data = previous.data()!;
        if (data['fromId'] != fromId ||
            data['toId'] != toId ||
            data['amount'] != amount) {
          throw StateError('Operação já utilizada com outros dados.');
        }
        return;
      }
      if ((source.balance * 100).round() < (amount * 100).round())
        throw StateError('Saldo insuficiente.');
      final now = DateTime.now().toIso8601String();
      tx.update(from, {'balance': source.balance - amount, 'updatedAt': now});
      tx.update(to, {
        'balance': destination.balance + amount,
        'updatedAt': now,
      });
      tx.set(entry, {
        'fromId': fromId,
        'toId': toId,
        'fromName': source.name,
        'toName': destination.name,
        'amount': amount,
        'date': now,
      });
    });
  }

  Future<List<AccountTransfer>> loadTransfers(String id) async {
    final snapshot = await _profile.collection('accountTransfers').get();
    return snapshot.docs
        .map((d) => AccountTransfer.fromMap(d.id, d.data()))
        .where((t) => t.fromId == id || t.toId == id)
        .toList();
  }
}
