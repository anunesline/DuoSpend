import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../home/data/models/wallet_model.dart';
import '../../domain/models/savings_goal.dart';
import '../models/savings_goal_model.dart';

class SavingsGoalRepository {
  static const _goalsCollection = 'savingsGoals';
  static const _movementsCollection = 'movements';
  static const _principalWalletId = 'principal';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SavingsGoalRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String createGoalId() {
    return _firestore.collection(_goalsCollection).doc().id;
  }

  String createMovementId(String goalId) {
    final normalizedGoalId = goalId.trim();

    if (normalizedGoalId.isEmpty) {
      throw ArgumentError.value(goalId, 'goalId', 'Informe a meta.');
    }

    return _goalReference(normalizedGoalId)
        .collection(_movementsCollection)
        .doc()
        .id;
  }

  Future<void> createGoal({
    required SavingsGoal goal,
    required WalletModel contextWallet,
  }) async {
    final userId = _requireUserId();

    if (goal.id.trim().isEmpty) {
      throw ArgumentError.value(goal.id, 'goal.id', 'A meta precisa de ID.');
    }

    if (goal.walletId.trim() != contextWallet.id.trim()) {
      throw StateError('A meta não pertence à carteira informada.');
    }

    if (!contextWallet.hasMember(userId)) {
      throw StateError('Usuário sem acesso à carteira da meta.');
    }

    if (goal.createdByUserId != userId) {
      throw StateError('O responsável da meta deve ser o usuário atual.');
    }

    if (goal.savedAmount != 0) {
      throw StateError(
        'A meta deve ser criada vazia e receber o valor por aporte.',
      );
    }

    final normalizedGoal = goal.copyWith(
      memberIds: contextWallet.memberIds,
      updatedAt: DateTime.now(),
    );

    await _goalReference(normalizedGoal.id).set(
      SavingsGoalModel.toMap(normalizedGoal),
    );
  }

  Future<List<SavingsGoal>> getGoalsByWallet(String walletId) async {
    final userId = _requireUserId();
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      return const [];
    }

    final snapshot = await _firestore
        .collection(_goalsCollection)
        .where('memberIds', arrayContains: userId)
        .get();

    final goals = snapshot.docs
        .map(
          (document) => SavingsGoalModel.fromMap(
            document.data(),
            documentId: document.id,
          ),
        )
        .where((goal) => goal.walletId == normalizedWalletId)
        .toList()
      ..sort((first, second) {
        if (first.isArchived != second.isArchived) {
          return first.isArchived ? 1 : -1;
        }

        return second.updatedAt.compareTo(first.updatedAt);
      });

    return List.unmodifiable(goals);
  }

  Future<SavingsGoal?> getGoalById(String goalId) async {
    final userId = _requireUserId();
    final normalizedGoalId = goalId.trim();

    if (normalizedGoalId.isEmpty) {
      return null;
    }

    final document = await _goalReference(normalizedGoalId).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    final goal = SavingsGoalModel.fromMap(
      document.data()!,
      documentId: document.id,
    );

    if (!goal.hasMember(userId)) {
      throw StateError('Usuário sem acesso à meta.');
    }

    return goal;
  }

  Future<SavingsGoal> contribute({
    required String goalId,
    required WalletModel sourceWallet,
    required double amount,
    required String operationId,
    DateTime? occurredAt,
  }) {
    return _moveMoney(
      goalId: goalId,
      financialWallet: sourceWallet,
      amount: amount,
      operationId: operationId,
      movementType: 'contribution',
      occurredAt: occurredAt,
    );
  }

  Future<SavingsGoal> withdraw({
    required String goalId,
    required WalletModel destinationWallet,
    required double amount,
    required String operationId,
    DateTime? occurredAt,
  }) {
    return _moveMoney(
      goalId: goalId,
      financialWallet: destinationWallet,
      amount: amount,
      operationId: operationId,
      movementType: 'withdrawal',
      occurredAt: occurredAt,
    );
  }

  Future<SavingsGoal> _moveMoney({
    required String goalId,
    required WalletModel financialWallet,
    required double amount,
    required String operationId,
    required String movementType,
    DateTime? occurredAt,
  }) async {
    final userId = _requireUserId();
    final normalizedGoalId = goalId.trim();
    final normalizedOperationId = operationId.trim();

    if (normalizedGoalId.isEmpty) {
      throw ArgumentError.value(goalId, 'goalId', 'Informe a meta.');
    }

    if (normalizedOperationId.isEmpty) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'A movimentação precisa de uma chave idempotente.',
      );
    }

    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'O valor deve ser maior que zero.',
      );
    }

    if (!financialWallet.isIndividual ||
        !financialWallet.isOwner(userId)) {
      throw StateError(
        'A movimentação deve usar uma carteira individual do usuário.',
      );
    }

    final goalReference = _goalReference(normalizedGoalId);
    final walletReference = _financialWalletReference(
      userId: userId,
      walletId: financialWallet.id,
    );
    final movementReference = goalReference
        .collection(_movementsCollection)
        .doc(normalizedOperationId);
    final movementDate = occurredAt ?? DateTime.now();

    return _firestore.runTransaction((transaction) async {
      final goalDocument = await transaction.get(goalReference);
      final walletDocument = await transaction.get(walletReference);
      final movementDocument = await transaction.get(movementReference);

      if (!goalDocument.exists || goalDocument.data() == null) {
        throw StateError('Meta não encontrada.');
      }

      if (!walletDocument.exists || walletDocument.data() == null) {
        throw StateError('Carteira financeira não encontrada.');
      }

      final goal = SavingsGoalModel.fromMap(
        goalDocument.data()!,
        documentId: goalDocument.id,
      );

      if (!goal.hasMember(userId)) {
        throw StateError('Usuário sem acesso à meta.');
      }

      if (movementDocument.exists) {
        final persistedType =
            movementDocument.data()?['type']?.toString();

        if (persistedType != movementType) {
          throw StateError(
            'A chave idempotente já foi usada em outra operação.',
          );
        }

        return goal;
      }

      _validateFinancialWalletDocument(
        data: walletDocument.data()!,
        userId: userId,
        walletId: financialWallet.id,
      );

      final currentBalance = _parseDouble(
        walletDocument.data()!['balance'],
      );

      late SavingsGoal updatedGoal;
      late double updatedWalletBalance;

      if (movementType == 'contribution') {
        if (!goal.isActive) {
          throw StateError('Somente metas ativas recebem aportes.');
        }

        if (amount > goal.remainingAmount) {
          throw StateError(
            'O aporte ultrapassa o valor restante da meta.',
          );
        }

        if (amount > currentBalance) {
          throw StateError('Saldo insuficiente para realizar o aporte.');
        }

        final updatedSavedAmount = goal.savedAmount + amount;

        updatedGoal = goal.copyWith(
          savedAmount: updatedSavedAmount,
          status: updatedSavedAmount >= goal.targetAmount
              ? SavingsGoalStatus.completed
              : SavingsGoalStatus.active,
          updatedAt: movementDate,
        );
        updatedWalletBalance = currentBalance - amount;
      } else if (movementType == 'withdrawal') {
        if (goal.isArchived) {
          throw StateError('Metas arquivadas não permitem retiradas.');
        }

        if (amount > goal.savedAmount) {
          throw StateError(
            'A retirada ultrapassa o valor reservado na meta.',
          );
        }

        updatedGoal = goal.copyWith(
          savedAmount: goal.savedAmount - amount,
          status: SavingsGoalStatus.active,
          updatedAt: movementDate,
        );
        updatedWalletBalance = currentBalance + amount;
      } else {
        throw StateError('Tipo de movimentação de meta inválido.');
      }

      transaction.update(walletReference, {
        'balance': updatedWalletBalance,
        'updatedAt': movementDate.toIso8601String(),
      });
      transaction.set(
        goalReference,
        SavingsGoalModel.toMap(updatedGoal),
        SetOptions(merge: true),
      );
      transaction.set(movementReference, {
        'id': normalizedOperationId,
        'goalId': normalizedGoalId,
        'walletId': financialWallet.id,
        'type': movementType,
        'amount': amount,
        'createdByUserId': userId,
        'occurredAt': movementDate.toIso8601String(),
      });

      return updatedGoal;
    });
  }

  DocumentReference<Map<String, dynamic>> _goalReference(String goalId) {
    return _firestore.collection(_goalsCollection).doc(goalId);
  }

  DocumentReference<Map<String, dynamic>> _financialWalletReference({
    required String userId,
    required String walletId,
  }) {
    if (walletId == _principalWalletId) {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('wallets')
          .doc(_principalWalletId);
    }

    return _firestore.collection('wallets').doc(walletId);
  }

  void _validateFinancialWalletDocument({
    required Map<String, dynamic> data,
    required String userId,
    required String walletId,
  }) {
    if (walletId == _principalWalletId) {
      return;
    }

    final ownerId = data['ownerId']?.toString().trim();
    final walletType = data['type']?.toString();

    if (ownerId != userId ||
        walletType != WalletType.individual.value) {
      throw StateError(
        'A carteira financeira não pertence ao usuário.',
      );
    }
  }

  String _requireUserId() {
    final userId = _auth.currentUser?.uid.trim();

    if (userId == null || userId.isEmpty) {
      throw StateError('Usuário não autenticado.');
    }

    return userId;
  }

  double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
