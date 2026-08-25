import 'package:flutter/foundation.dart';

import '../../../home/data/models/wallet_model.dart';
import '../../data/repositories/savings_goal_repository.dart';
import '../../domain/models/savings_goal.dart';
import '../../domain/models/savings_goal_movement.dart';
import '../../domain/services/savings_goal_service.dart';

class SavingsGoalsController extends ChangeNotifier {
  final SavingsGoalRepository _repository;
  final SavingsGoalService _service;
  final WalletModel contextWallet;
  final String currentUserId;

  List<SavingsGoal> goals = const [];
  List<WalletModel> financialWallets;
  Map<String, List<SavingsGoalMovement>> movementsByGoal = const {};
  final Set<String> _loadingHistoryGoalIds = {};

  bool isLoading = false;
  bool isProcessing = false;
  String? processingGoalId;
  String? errorMessage;

  SavingsGoalsController({
    required this.contextWallet,
    required List<WalletModel> financialWallets,
    required this.currentUserId,
    SavingsGoalRepository? repository,
    SavingsGoalService? service,
  })  : financialWallets = List.from(financialWallets),
        _repository = repository ?? SavingsGoalRepository(),
        _service = service ?? const SavingsGoalService();

  double get totalSaved {
    return goals
        .where((goal) => !goal.isArchived)
        .fold<double>(0, (total, goal) => total + goal.savedAmount);
  }

  double get totalTarget {
    return goals
        .where((goal) => !goal.isArchived)
        .fold<double>(0, (total, goal) => total + goal.targetAmount);
  }

  int get activeGoalCount {
    return goals.where((goal) => goal.isActive).length;
  }

  Future<void> loadGoals() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      goals = await _repository.getGoalsByWallet(contextWallet.id);
    } catch (error, stackTrace) {
      debugPrint('Erro ao carregar metas: $error');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage = 'Não foi possível carregar suas metas.';
      goals = const [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool isLoadingHistoryFor(String goalId) {
    return _loadingHistoryGoalIds.contains(goalId);
  }

  Future<List<SavingsGoalMovement>?> loadMovements(
    SavingsGoal goal,
  ) async {
    if (_loadingHistoryGoalIds.contains(goal.id)) {
      return movementsByGoal[goal.id];
    }

    _loadingHistoryGoalIds.add(goal.id);
    errorMessage = null;
    notifyListeners();

    try {
      final movements = await _repository.getMovements(
        goalId: goal.id,
      );
      movementsByGoal = Map.unmodifiable({
        ...movementsByGoal,
        goal.id: movements,
      });

      return movements;
    } catch (error, stackTrace) {
      debugPrint('Erro ao carregar histórico da meta: $error');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage = _friendlyError(
        error,
        fallback: 'Não foi possível carregar o histórico da meta.',
      );

      return null;
    } finally {
      _loadingHistoryGoalIds.remove(goal.id);
      notifyListeners();
    }
  }

  Future<SavingsGoal?> createGoal({
    required String name,
    required double targetAmount,
    DateTime? deadline,
  }) async {
    if (isProcessing) {
      return null;
    }

    isProcessing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final goal = _service.create(
        id: _repository.createGoalId(),
        name: name,
        targetAmount: targetAmount,
        walletId: contextWallet.id,
        createdByUserId: currentUserId,
        memberIds: contextWallet.memberIds,
        deadline: deadline,
      );

      await _repository.createGoal(
        goal: goal,
        contextWallet: contextWallet,
      );

      goals = List.unmodifiable([goal, ...goals]);

      return goal;
    } catch (error, stackTrace) {
      debugPrint('Erro ao criar meta: $error');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage = _friendlyError(
        error,
        fallback: 'Não foi possível criar a meta.',
      );

      return null;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  Future<SavingsGoal?> contribute({
    required SavingsGoal goal,
    required WalletModel sourceWallet,
    required double amount,
  }) {
    return _move(
      goal: goal,
      financialWallet: sourceWallet,
      amount: amount,
      isContribution: true,
    );
  }

  Future<SavingsGoal?> withdraw({
    required SavingsGoal goal,
    required WalletModel destinationWallet,
    required double amount,
  }) {
    return _move(
      goal: goal,
      financialWallet: destinationWallet,
      amount: amount,
      isContribution: false,
    );
  }

  Future<SavingsGoal?> updateGoal({
    required SavingsGoal goal,
    required String name,
    required double targetAmount,
    DateTime? deadline,
  }) async {
    if (isProcessing) {
      return null;
    }

    isProcessing = true;
    processingGoalId = goal.id;
    errorMessage = null;
    notifyListeners();

    try {
      _service.update(
        goal: goal,
        name: name,
        targetAmount: targetAmount,
        deadline: deadline,
      );

      final updatedGoal = await _repository.update(
        goalId: goal.id,
        name: name,
        targetAmount: targetAmount,
        deadline: deadline,
      );
      final updatedGoals = goals.map(
        (currentGoal) => currentGoal.id == updatedGoal.id
            ? updatedGoal
            : currentGoal,
      ).toList()
        ..sort((first, second) {
          if (first.isArchived != second.isArchived) {
            return first.isArchived ? 1 : -1;
          }

          return second.updatedAt.compareTo(first.updatedAt);
        });

      goals = List.unmodifiable(updatedGoals);

      return updatedGoal;
    } catch (error, stackTrace) {
      debugPrint('Erro ao editar meta: $error');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage = _friendlyError(
        error,
        fallback: 'Não foi possível editar a meta.',
      );

      return null;
    } finally {
      isProcessing = false;
      processingGoalId = null;
      notifyListeners();
    }
  }

  Future<SavingsGoal?> archiveGoal(SavingsGoal goal) async {
    if (isProcessing) {
      return null;
    }

    isProcessing = true;
    processingGoalId = goal.id;
    errorMessage = null;
    notifyListeners();

    try {
      final archivedGoal = await _repository.archive(
        goalId: goal.id,
      );
      final updatedGoals = goals.map(
        (currentGoal) => currentGoal.id == archivedGoal.id
            ? archivedGoal
            : currentGoal,
      ).toList()
        ..sort((first, second) {
          if (first.isArchived != second.isArchived) {
            return first.isArchived ? 1 : -1;
          }

          return second.updatedAt.compareTo(first.updatedAt);
        });

      goals = List.unmodifiable(updatedGoals);

      return archivedGoal;
    } catch (error, stackTrace) {
      debugPrint('Erro ao arquivar meta: $error');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage = _friendlyError(
        error,
        fallback: 'Não foi possível arquivar a meta.',
      );

      return null;
    } finally {
      isProcessing = false;
      processingGoalId = null;
      notifyListeners();
    }
  }

  Future<SavingsGoal?> _move({
    required SavingsGoal goal,
    required WalletModel financialWallet,
    required double amount,
    required bool isContribution,
  }) async {
    if (isProcessing) {
      return null;
    }

    isProcessing = true;
    processingGoalId = goal.id;
    errorMessage = null;
    notifyListeners();

    try {
      final operationId = _repository.createMovementId(goal.id);
      final updatedGoal = isContribution
          ? await _repository.contribute(
              goalId: goal.id,
              sourceWallet: financialWallet,
              amount: amount,
              operationId: operationId,
            )
          : await _repository.withdraw(
              goalId: goal.id,
              destinationWallet: financialWallet,
              amount: amount,
              operationId: operationId,
            );

      goals = List.unmodifiable(
        goals.map(
          (currentGoal) =>
              currentGoal.id == updatedGoal.id
                  ? updatedGoal
                  : currentGoal,
        ),
      );

      final persistedWallet = await _repository.getFinancialWallet(
        walletId: financialWallet.id,
      );
      financialWallets = financialWallets.map((wallet) {
        return wallet.id == persistedWallet.id ? persistedWallet : wallet;
      }).toList();

      return updatedGoal;
    } catch (error, stackTrace) {
      debugPrint('Erro ao movimentar meta: $error');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage = _friendlyError(
        error,
        fallback: 'Não foi possível movimentar a meta.',
      );

      return null;
    } finally {
      isProcessing = false;
      processingGoalId = null;
      notifyListeners();
    }
  }

  String _friendlyError(
    Object error, {
    required String fallback,
  }) {
    final message = error.toString();

    if (message.contains('Saldo insuficiente')) {
      return 'Saldo insuficiente na carteira escolhida.';
    }

    if (message.contains('ultrapassa o valor restante')) {
      return 'O valor ultrapassa o que falta para concluir a meta.';
    }

    if (message.contains('ultrapassa o valor reservado')) {
      return 'O valor ultrapassa o total reservado na meta.';
    }

    if (message.contains('Retire o valor reservado')) {
      return 'Retire todo o valor reservado antes de arquivar.';
    }

    if (message.contains('menor que o valor reservado')) {
      return 'O valor-alvo não pode ser menor que o total reservado.';
    }

    if (error is ArgumentError || error is StateError) {
      return message
          .replaceFirst('Invalid argument(s): ', '')
          .replaceFirst('Bad state: ', '');
    }

    return fallback;
  }
}
