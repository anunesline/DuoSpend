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

  /// Creates a reminder request for a pending task.
  ///
  /// Personal tasks can remind their owner and are not subject to partner
  /// anti-spam cooldown. Shared tasks assigned to another member use the
  /// partner-reminder flow and keep the cooldown protection.
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

    final sender = senderUserId.trim();
    if (sender.isEmpty) {
      return HouseholdTaskReminderResult.invalid(
        'Não foi possível identificar quem receberá o lembrete.',
      );
    }

    if (task.scope == HouseholdTaskScope.personal) {
      final reminder = HouseholdTaskReminder(
        id: uuid.v4(),
        taskId: task.id,
        scopeId: task.scopeId,
        senderUserId: sender,
        recipientUserId: sender,
        createdAt: now,
      );
      await repository.saveReminder(reminder);
      return HouseholdTaskReminderResult.sent(reminder);
    }

    final recipientUserId = task.assigneeId?.trim();
    if (recipientUserId == null || recipientUserId.isEmpty) {
      return HouseholdTaskReminderResult.invalid(
        'Defina um responsável antes de enviar um lembrete.',
      );
    }

    // A shared task assigned to the current user behaves like a self-reminder.
    // Anti-spam exists only when one household member nudges another.
    if (recipientUserId == sender) {
      final reminder = HouseholdTaskReminder(
        id: uuid.v4(),
        taskId: task.id,
        scopeId: task.scopeId,
        senderUserId: sender,
        recipientUserId: sender,
        createdAt: now,
      );
      await repository.saveReminder(reminder);
      return HouseholdTaskReminderResult.sent(reminder);
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
