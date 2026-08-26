import 'package:uuid/uuid.dart';

import '../models/household_task.dart';
import '../models/household_task_reminder.dart';
import '../repositories/household_task_reminder_repository.dart';

class HouseholdTaskReminderResult {
  final HouseholdTaskReminder? reminder;
  final Duration? retryAfter;
  final String? errorMessage;

  const HouseholdTaskReminderResult._({
    this.reminder,
    this.retryAfter,
    this.errorMessage,
  });

  bool get sent => reminder != null;
  bool get blocked => retryAfter != null;

  factory HouseholdTaskReminderResult.sent(HouseholdTaskReminder reminder) =>
      HouseholdTaskReminderResult._(reminder: reminder);

  factory HouseholdTaskReminderResult.blocked(Duration retryAfter) =>
      HouseholdTaskReminderResult._(retryAfter: retryAfter);

  factory HouseholdTaskReminderResult.invalid(String message) =>
      HouseholdTaskReminderResult._(errorMessage: message);
}

class HouseholdTaskReminderService {
  static const defaultCooldown = Duration(hours: 2);

  final HouseholdTaskReminderRepository repository;
  final Duration cooldown;
  final Uuid uuid;

  const HouseholdTaskReminderService({
    required this.repository,
    this.cooldown = defaultCooldown,
    this.uuid = const Uuid(),
  });

  Future<HouseholdTaskReminderResult> remindAssignee({
    required HouseholdTask task,
    required String senderUserId,
    required DateTime now,
  }) async {
    if (!task.isPending) {
      return HouseholdTaskReminderResult.invalid(
        'Só tarefas pendentes podem receber lembretes.',
      );
    }
    if (task.scope != HouseholdTaskScope.shared) {
      return HouseholdTaskReminderResult.invalid(
        'Lembretes para parceiro só existem em tarefas compartilhadas.',
      );
    }

    final recipientUserId = task.assigneeId?.trim();
    final sender = senderUserId.trim();
    if (recipientUserId == null || recipientUserId.isEmpty) {
      return HouseholdTaskReminderResult.invalid(
        'Defina um responsável antes de enviar um lembrete.',
      );
    }
    if (sender.isEmpty || sender == recipientUserId) {
      return HouseholdTaskReminderResult.invalid(
        'Você só pode lembrar outro responsável.',
      );
    }

    final latest = await repository.getLatestReminder(
      taskId: task.id,
      senderUserId: sender,
      recipientUserId: recipientUserId,
    );
    if (latest != null) {
      final elapsed = now.difference(latest.createdAt);
      if (elapsed < cooldown) {
        return HouseholdTaskReminderResult.blocked(cooldown - elapsed);
      }
    }

    final reminder = HouseholdTaskReminder(
      id: uuid.v4(),
      taskId: task.id,
      scopeId: task.scopeId,
      senderUserId: sender,
      recipientUserId: recipientUserId,
      createdAt: now,
    );
    await repository.saveReminder(reminder);
    return HouseholdTaskReminderResult.sent(reminder);
  }
}
