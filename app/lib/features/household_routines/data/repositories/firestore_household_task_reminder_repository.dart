import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/models/household_task_reminder.dart';
import '../../domain/repositories/household_task_reminder_repository.dart';

class FirestoreHouseholdTaskReminderRepository
    implements HouseholdTaskReminderRepository {
  final FirebaseFunctions functions;

  FirestoreHouseholdTaskReminderRepository({FirebaseFunctions? functions})
      : functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<void> saveReminder(HouseholdTaskReminder reminder) async {
    try {
      await functions.httpsCallable('createHouseholdReminder').call({
        'reminderId': reminder.id,
        'taskId': reminder.taskId,
        'remindAt': reminder.remindAt.toUtc().toIso8601String(),
      });
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'resource-exhausted') {
        final details = error.details;
        final rawSeconds = details is Map ? details['retryAfterSeconds'] : null;
        final seconds = rawSeconds is num
            ? rawSeconds.ceil()
            : int.tryParse(rawSeconds?.toString() ?? '');
        throw HouseholdReminderCooldownException(
          Duration(seconds: seconds != null && seconds > 0 ? seconds : 1),
        );
      }
      rethrow;
    }
  }

  @override
  Future<HouseholdTaskReminder?> getLatestReminder({
    required String taskId,
    required String senderUserId,
    required String recipientUserId,
  }) async {
    final result = await functions.httpsCallable('getLatestHouseholdReminder').call({
      'taskId': taskId,
      'recipientUserId': recipientUserId,
    });
    final data = result.data;
    if (data is! Map) return null;
    final rawReminder = data['reminder'];
    if (rawReminder is! Map) return null;
    return HouseholdTaskReminder.fromMap(
      Map<String, dynamic>.from(rawReminder),
    );
  }
}
