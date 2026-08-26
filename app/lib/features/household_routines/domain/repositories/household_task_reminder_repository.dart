import '../models/household_task_reminder.dart';

abstract class HouseholdTaskReminderRepository {
  Future<void> saveReminder(HouseholdTaskReminder reminder);

  Future<HouseholdTaskReminder?> getLatestReminder({
    required String taskId,
    required String senderUserId,
    required String recipientUserId,
  });

  Future<List<HouseholdTaskReminder>> getDueReminders({
    required String recipientUserId,
    required DateTime now,
  });

  Future<void> markDelivered({
    required String reminderId,
    required DateTime deliveredAt,
  });
}
