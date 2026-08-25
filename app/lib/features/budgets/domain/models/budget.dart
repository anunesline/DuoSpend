enum BudgetStatus { active, paused, archived }

class Budget {
  final String id;
  final String walletId;
  final String category;
  final DateTime month;
  final double limitAmount;
  final String createdByUserId;
  final BudgetStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Budget({
    required this.id,
    required this.walletId,
    required this.category,
    required this.month,
    required this.limitAmount,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.status = BudgetStatus.active,
  });

  bool get isActive => status == BudgetStatus.active;
  bool get isPaused => status == BudgetStatus.paused;
  bool get isArchived => status == BudgetStatus.archived;

  Budget copyWith({
    String? category,
    DateTime? month,
    double? limitAmount,
    BudgetStatus? status,
    DateTime? updatedAt,
  }) => Budget(
    id: id,
    walletId: walletId,
    category: category ?? this.category,
    month: month ?? this.month,
    limitAmount: limitAmount ?? this.limitAmount,
    createdByUserId: createdByUserId,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
