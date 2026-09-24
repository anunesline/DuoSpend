import '../models/household_task_reminder.dart';
import '../models/household_task.dart';

class HouseholdReminderCooldownException implements Exception {
  final Duration retryAfter;

  const HouseholdReminderCooldownException(this.retryAfter);
}

class HouseholdReminderDeliveryException implements Exception {
  final int statusCode;
  final String message;

  const HouseholdReminderDeliveryException(this.statusCode, this.message);

  @override
  String toString() => message;
}

abstract class HouseholdTaskReminderRepository {
  Future<void> saveReminder(HouseholdTaskReminder reminder);

  Future<HouseholdTaskReminder?> getLatestReminder({
    required String taskId,
    required String senderUserId,
    required String recipientUserId,
  });

  Future<void> scheduleTaskReminder({
    required HouseholdTask task,
    required DateTime remindAt,
  }) async {}

  Future<void> cancelTaskReminder(String taskId) async {}
}
