enum SavingsGoalMovementType {
  contribution,
  withdrawal;

  static SavingsGoalMovementType fromValue(String? value) {
    return SavingsGoalMovementType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => SavingsGoalMovementType.contribution,
    );
  }
}

class SavingsGoalMovement {
  final String id;
  final String goalId;
  final String walletId;
  final SavingsGoalMovementType type;
  final double amount;
  final String createdByUserId;
  final DateTime occurredAt;

  const SavingsGoalMovement({
    required this.id,
    required this.goalId,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.createdByUserId,
    required this.occurredAt,
  });

  bool get isContribution {
    return type == SavingsGoalMovementType.contribution;
  }

  bool get isWithdrawal {
    return type == SavingsGoalMovementType.withdrawal;
  }
}
