import '../../domain/models/savings_goal_movement.dart';

class SavingsGoalMovementModel {
  const SavingsGoalMovementModel._();

  static SavingsGoalMovement fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final rawId = map['id']?.toString().trim();

    return SavingsGoalMovement(
      id: rawId == null || rawId.isEmpty
          ? documentId ?? ''
          : rawId,
      goalId: map['goalId']?.toString().trim() ?? '',
      walletId: map['walletId']?.toString().trim() ?? '',
      type: SavingsGoalMovementType.fromValue(
        map['type']?.toString(),
      ),
      amount: _parseDouble(map['amount']),
      createdByUserId:
          map['createdByUserId']?.toString().trim() ?? '',
      occurredAt: _parseDate(map['occurredAt']) ?? DateTime.now(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '');
  }
}
