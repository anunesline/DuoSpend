import '../models/household_task_reminder.dart';

abstract class HouseholdTaskReminderRepository {
  Future<void> saveReminder(HouseholdTaskReminder reminder);

  Future<HouseholdTaskReminder?> getLatestReminder({
    required String taskId,
    required String senderUserId,
    required String recipientUserId,
  });
}
