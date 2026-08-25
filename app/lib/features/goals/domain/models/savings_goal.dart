enum SavingsGoalStatus {
  active,
  completed,
  archived;

  static SavingsGoalStatus fromValue(String? value) {
    return SavingsGoalStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SavingsGoalStatus.active,
    );
  }
}

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final String walletId;
  final String createdByUserId;
  final SavingsGoalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
    required this.walletId,
    required this.createdByUserId,
    this.status = SavingsGoalStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainingAmount {
    final remaining = targetAmount - savedAmount;

    return remaining > 0 ? remaining : 0;
  }

  double get progress {
    if (targetAmount <= 0) {
      return 0;
    }

    return (savedAmount / targetAmount).clamp(0.0, 1.0);
  }

  double get progressPercentage => progress * 100;

  bool get isCompleted {
    return status == SavingsGoalStatus.completed ||
        savedAmount >= targetAmount;
  }

  bool get isActive => status == SavingsGoalStatus.active && !isCompleted;

  bool get isArchived => status == SavingsGoalStatus.archived;

  bool get hasDeadline => deadline != null;

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    bool clearDeadline = false,
    String? walletId,
    String? createdByUserId,
    SavingsGoalStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: clearDeadline ? null : deadline ?? this.deadline,
      walletId: walletId ?? this.walletId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
