import '../../domain/models/savings_goal.dart';

class SavingsGoalModel {
  const SavingsGoalModel._();

  static Map<String, dynamic> toMap(SavingsGoal goal) {
    return {
      'id': goal.id,
      'name': goal.name,
      'targetAmount': goal.targetAmount,
      'savedAmount': goal.savedAmount,
      'deadline': goal.deadline?.toIso8601String(),
      'walletId': goal.walletId,
      'createdByUserId': goal.createdByUserId,
      'memberIds': goal.memberIds,
      'status': goal.status.name,
      'createdAt': goal.createdAt.toIso8601String(),
      'updatedAt': goal.updatedAt.toIso8601String(),
    };
  }

  static SavingsGoal fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final id = map['id']?.toString().trim();

    return SavingsGoal(
      id: id == null || id.isEmpty ? documentId ?? '' : id,
      name: map['name']?.toString() ?? '',
      targetAmount: _parseDouble(map['targetAmount']),
      savedAmount: _parseDouble(map['savedAmount']),
      deadline: _parseDate(map['deadline']),
      walletId: map['walletId']?.toString() ?? '',
      createdByUserId: map['createdByUserId']?.toString() ?? '',
      memberIds: _parseMemberIds(map['memberIds']),
      status: SavingsGoalStatus.fromValue(map['status']?.toString()),
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static List<String> _parseMemberIds(dynamic value) {
    if (value is! Iterable) {
      return const [];
    }

    final memberIds = <String>[];

    for (final rawMemberId in value) {
      final memberId = rawMemberId.toString().trim();

      if (memberId.isNotEmpty && !memberIds.contains(memberId)) {
        memberIds.add(memberId);
      }
    }

    return List.unmodifiable(memberIds);
  }
}
