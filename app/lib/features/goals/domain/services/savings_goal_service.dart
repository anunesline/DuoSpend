import '../models/savings_goal.dart';

class SavingsGoalService {
  const SavingsGoalService();

  SavingsGoal create({
    required String id,
    required String name,
    required double targetAmount,
    required String walletId,
    required String createdByUserId,
    double initialAmount = 0,
    DateTime? deadline,
    DateTime? now,
  }) {
    final normalizedId = id.trim();
    final normalizedName = name.trim();
    final normalizedWalletId = walletId.trim();
    final normalizedUserId = createdByUserId.trim();
    final currentTime = now ?? DateTime.now();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'A meta precisa possuir um ID.');
    }

    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'Informe um nome para a meta.',
      );
    }

    if (!targetAmount.isFinite || targetAmount <= 0) {
      throw ArgumentError.value(
        targetAmount,
        'targetAmount',
        'O valor-alvo deve ser maior que zero.',
      );
    }

    if (!initialAmount.isFinite ||
        initialAmount < 0 ||
        initialAmount > targetAmount) {
      throw ArgumentError.value(
        initialAmount,
        'initialAmount',
        'O valor inicial deve ficar entre zero e o valor-alvo.',
      );
    }

    if (normalizedWalletId.isEmpty) {
      throw ArgumentError.value(
        walletId,
        'walletId',
        'A meta precisa pertencer a uma carteira.',
      );
    }

    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(
        createdByUserId,
        'createdByUserId',
        'A meta precisa possuir um responsável.',
      );
    }

    final normalizedDeadline = deadline == null
        ? null
        : DateTime(deadline.year, deadline.month, deadline.day);
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );

    if (normalizedDeadline != null &&
        normalizedDeadline.isBefore(today)) {
      throw ArgumentError.value(
        deadline,
        'deadline',
        'O prazo da meta não pode estar no passado.',
      );
    }

    return SavingsGoal(
      id: normalizedId,
      name: normalizedName,
      targetAmount: targetAmount,
      savedAmount: initialAmount,
      deadline: normalizedDeadline,
      walletId: normalizedWalletId,
      createdByUserId: normalizedUserId,
      status: initialAmount >= targetAmount
          ? SavingsGoalStatus.completed
          : SavingsGoalStatus.active,
      createdAt: currentTime,
      updatedAt: currentTime,
    );
  }

  SavingsGoal contribute({
    required SavingsGoal goal,
    required double amount,
    DateTime? now,
  }) {
    _validateMovement(goal: goal, amount: amount);

    if (!goal.isActive) {
      throw StateError('Somente metas ativas podem receber aportes.');
    }

    final updatedAmount = goal.savedAmount + amount;

    if (updatedAmount > goal.targetAmount) {
      throw StateError(
        'O aporte não pode ultrapassar o valor restante da meta.',
      );
    }

    return goal.copyWith(
      savedAmount: updatedAmount,
      status: updatedAmount >= goal.targetAmount
          ? SavingsGoalStatus.completed
          : SavingsGoalStatus.active,
      updatedAt: now ?? DateTime.now(),
    );
  }

  SavingsGoal withdraw({
    required SavingsGoal goal,
    required double amount,
    DateTime? now,
  }) {
    _validateMovement(goal: goal, amount: amount);

    if (goal.isArchived) {
      throw StateError('Metas arquivadas não podem movimentar valores.');
    }

    if (amount > goal.savedAmount) {
      throw StateError(
        'A retirada não pode ultrapassar o valor reservado.',
      );
    }

    final updatedAmount = goal.savedAmount - amount;

    return goal.copyWith(
      savedAmount: updatedAmount,
      status: SavingsGoalStatus.active,
      updatedAt: now ?? DateTime.now(),
    );
  }

  SavingsGoal archive({
    required SavingsGoal goal,
    DateTime? now,
  }) {
    return goal.copyWith(
      status: SavingsGoalStatus.archived,
      updatedAt: now ?? DateTime.now(),
    );
  }

  void _validateMovement({
    required SavingsGoal goal,
    required double amount,
  }) {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'O valor da movimentação deve ser maior que zero.',
      );
    }

    if (goal.targetAmount <= 0 ||
        goal.savedAmount < 0 ||
        goal.savedAmount > goal.targetAmount) {
      throw StateError('A meta possui valores financeiros inválidos.');
    }
  }
}
