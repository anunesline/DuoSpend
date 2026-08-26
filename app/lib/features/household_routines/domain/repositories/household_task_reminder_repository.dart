import '../models/household_task_reminder.dart';

class HouseholdReminderCooldownException implements Exception {
  final Duration retryAfter;

  const HouseholdReminderCooldownException(this.retryAfter);
}

abstract class HouseholdTaskReminderRepository {
  Future<void> saveReminder(HouseholdTaskReminder reminder);

  Future<HouseholdTaskReminder?> getLatestReminder({
    required String taskId,
    required String senderUserId,
    required String recipientUserId,
  });
}
