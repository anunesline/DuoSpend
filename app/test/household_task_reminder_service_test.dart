import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/household_routines/domain/models/household_task.dart';
import 'package:app/features/household_routines/domain/models/household_task_reminder.dart';
import 'package:app/features/household_routines/domain/repositories/household_task_reminder_repository.dart';
import 'package:app/features/household_routines/domain/services/household_task_reminder_service.dart';

void main() {
  group('HouseholdTaskReminderService', () {
    test('envia lembrete para outro responsavel em tarefa compartilhada', () async {
      final repository = _FakeReminderRepository();
      final service = HouseholdTaskReminderService(repository: repository);
      final task = _sharedTask(assigneeId: 'matheus');

      final result = await service.remindAssignee(
        task: task,
        senderUserId: 'aline',
        now: DateTime(2026, 8, 26, 14),
      );

      expect(result.sent, isTrue);
      expect(result.reminder?.recipientUserId, 'matheus');
      expect(repository.reminders, hasLength(1));
    });

    test('bloqueia novo lembrete dentro do cooldown de duas horas', () async {
      final repository = _FakeReminderRepository();
      final service = HouseholdTaskReminderService(repository: repository);
      final task = _sharedTask(assigneeId: 'matheus');

      await service.remindAssignee(
        task: task,
        senderUserId: 'aline',
        now: DateTime(2026, 8, 26, 14),
      );
      final second = await service.remindAssignee(
        task: task,
        senderUserId: 'aline',
        now: DateTime(2026, 8, 26, 15),
      );

      expect(second.blocked, isTrue);
      expect(second.retryAfter, const Duration(hours: 1));
      expect(repository.reminders, hasLength(1));
    });

    test('nao permite lembrar a si mesmo ou tarefa solo', () async {
      final repository = _FakeReminderRepository();
      final service = HouseholdTaskReminderService(repository: repository);

      final selfResult = await service.remindAssignee(
        task: _sharedTask(assigneeId: 'aline'),
        senderUserId: 'aline',
        now: DateTime(2026, 8, 26, 14),
      );
      final soloResult = await service.remindAssignee(
        task: _sharedTask(
          assigneeId: 'matheus',
          scope: HouseholdTaskScope.personal,
        ),
        senderUserId: 'aline',
        now: DateTime(2026, 8, 26, 14),
      );

      expect(selfResult.sent, isFalse);
      expect(soloResult.sent, isFalse);
      expect(repository.reminders, isEmpty);
    });
  });
}

HouseholdTask _sharedTask({
  required String assigneeId,
  HouseholdTaskScope scope = HouseholdTaskScope.shared,
}) {
  return HouseholdTask(
    id: 'task-1',
    scopeId: 'household:casa',
    scope: scope,
    title: 'Tirar o lixo',
    assigneeId: assigneeId,
    status: HouseholdTaskStatus.pending,
    createdAt: DateTime(2026, 8, 26, 12),
    updatedAt: DateTime(2026, 8, 26, 12),
  );
}

class _FakeReminderRepository implements HouseholdTaskReminderRepository {
  final List<HouseholdTaskReminder> reminders = [];

  @override
  Future<void> saveReminder(HouseholdTaskReminder reminder) async {
    reminders.add(reminder);
  }

  @override
  Future<HouseholdTaskReminder?> getLatestReminder({
    required String taskId,
    required String senderUserId,
    required String recipientUserId,
  }) async {
    final matches = reminders
        .where(
          (reminder) =>
              reminder.taskId == taskId &&
              reminder.senderUserId == senderUserId &&
              reminder.recipientUserId == recipientUserId,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches.isEmpty ? null : matches.first;
  }
}
