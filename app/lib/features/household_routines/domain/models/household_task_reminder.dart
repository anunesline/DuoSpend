class HouseholdTaskReminder {
  final String id;
  final String taskId;
  final String scopeId;
  final String senderUserId;
  final String recipientUserId;
  final DateTime createdAt;

  const HouseholdTaskReminder({
    required this.id,
    required this.taskId,
    required this.scopeId,
    required this.senderUserId,
    required this.recipientUserId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'taskId': taskId,
        'scopeId': scopeId,
        'senderUserId': senderUserId,
        'recipientUserId': recipientUserId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HouseholdTaskReminder.fromMap(Map<String, dynamic> map) {
    return HouseholdTaskReminder(
      id: map['id']?.toString() ?? '',
      taskId: map['taskId']?.toString() ?? '',
      scopeId: map['scopeId']?.toString() ?? '',
      senderUserId: map['senderUserId']?.toString() ?? '',
      recipientUserId: map['recipientUserId']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
