enum HouseholdTaskReminderKind { self, partner }

enum HouseholdTaskReminderStatus { scheduled, pendingDelivery, delivered, cancelled }

class HouseholdTaskReminder {
  final String id;
  final String taskId;
  final String scopeId;
  final String senderUserId;
  final String recipientUserId;
  final HouseholdTaskReminderKind kind;
  final HouseholdTaskReminderStatus status;
  final DateTime remindAt;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  const HouseholdTaskReminder({
    required this.id,
    required this.taskId,
    required this.scopeId,
    required this.senderUserId,
    required this.recipientUserId,
    required this.kind,
    required this.status,
    required this.remindAt,
    required this.createdAt,
    this.deliveredAt,
  });

  bool get isDue =>
      status == HouseholdTaskReminderStatus.scheduled ||
      status == HouseholdTaskReminderStatus.pendingDelivery;

  Map<String, dynamic> toMap() => {
        'id': id,
        'taskId': taskId,
        'scopeId': scopeId,
        'senderUserId': senderUserId,
        'recipientUserId': recipientUserId,
        'kind': kind.name,
        'status': status.name,
        'remindAt': remindAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
      };

  factory HouseholdTaskReminder.fromMap(Map<String, dynamic> map) {
    final createdAt =
        DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now();
    return HouseholdTaskReminder(
      id: map['id']?.toString() ?? '',
      taskId: map['taskId']?.toString() ?? '',
      scopeId: map['scopeId']?.toString() ?? '',
      senderUserId: map['senderUserId']?.toString() ?? '',
      recipientUserId: map['recipientUserId']?.toString() ?? '',
      kind: HouseholdTaskReminderKind.values.firstWhere(
        (value) => value.name == map['kind']?.toString(),
        orElse: () => HouseholdTaskReminderKind.self,
      ),
      status: HouseholdTaskReminderStatus.values.firstWhere(
        (value) => value.name == map['status']?.toString(),
        orElse: () => HouseholdTaskReminderStatus.scheduled,
      ),
      remindAt: DateTime.tryParse(map['remindAt']?.toString() ?? '') ?? createdAt,
      createdAt: createdAt,
      deliveredAt: DateTime.tryParse(map['deliveredAt']?.toString() ?? ''),
    );
  }
}
