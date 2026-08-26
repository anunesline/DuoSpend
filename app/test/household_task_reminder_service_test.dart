import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/household_routines/domain/models/household_task.dart';
import 'package:app/features/household_routines/domain/models/household_task_reminder.dart';
import 'package:app/features/household_routines/domain/repositories/household_task_reminder_repository.dart';
import 'package:app/features/household_routines/domain/services/household_task_reminder_service.dart';

void main() {
  group('HouseholdTaskReminderService', () {
    test('fila lembrete imediato para outro responsavel em tarefa compartilhada', () async {
      final repository = _FakeReminderRepository();
      final service = HouseholdTaskReminderService(repository: repository);
      final result = await service.remindAssignee(
        task: _task(assigneeId: 'matheus'),
        senderUserId: 'aline',
        now: DateTime(2026, 8, 26, 14),
      );

      expect(result.sent, isTrue);
      expect(result.reminder?.recipientUserId, 'matheus');
      expect(result.reminder?.kind, HouseholdTaskReminderKind.partner);
      expect(result.reminder?.status, HouseholdTaskReminderStatus.pendingDelivery);
      expect(result.reminder?.remindAt, DateTime(2026, 8, 26, 14));
    });

    test('bloqueia novo lembrete ao parceiro dentro do cooldown de duas horas', () async {
      final repository = _FakeReminderRepository();
      final service = HouseholdTaskReminderService(repository: repository);
      final task = _task(assigneeId: 'matheus');

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

    test('tarefa solo agenda lembrete para horario escolhido', () async {
      final repository = _FakeReminderRepository();
      final service = HouseholdTaskReminderService(repository: repository);
      final remindAt = DateTime(2026, 8, 26, 18, 30);
      final result = await service.remindAssignee(
        task: _task(assigneeId: 'aline', scope: HouseholdTaskScope.personal),
        senderUserId: 'aline',
        now: DateTime(2026, 8, 26, 14),
        remindAt: remindAt,
      );

      expect(result.sent, isTrue);
      expect(result.reminder?.recipientUserId, 'aline');
      expect(result.reminder?.kind, HouseholdTaskReminderKind.self);
      expect(result.reminder?.status, HouseholdTaskReminderStatus.scheduled);
      expect(result.reminder?.remindAt, remindAt);
    });

    test('auto lembrete nao usa cooldown anti-spam de parceiro', () async {
      final repository = _FakeReminderRepository();
      final service = HouseholdTaskReminderService(repository: repository);
      final task = _task(assigneeId: 'aline', scope: HouseholdTaskScope.personal);

      final first = await service.remindAssignee(
        task: task,
        senderUserId: 'aline',
        now: DateTime(2026, 8, 26, 14),
        remindAt: DateTime(2026, 8, 26, 16),
      );
      final second = await service.remindAssignee(
        task: task,
        senderUserId: 'aline',
        now: DateTime(2026, 8, 26, 14, 5),
        remindAt: DateTime(2026, 8, 26, 17),
      );

      expect(first.sent, isTrue);
      expect(second.sent, isTrue);
      expect(second.blocked, isFalse);
      expect(repository.reminders, hasLength(2));
    });

    test('repositorio expoe apenas lembretes vencidos e pode marcar entrega', () async {
      final repository = _FakeReminderRepository();
      final service = HouseholdTaskReminderService(repository: repository);
      final task = _task(assigneeId: 'aline', scope: HouseholdTaskScope.personal);
      await service.remindAssignee(
        task: task,
        senderUserId: 'aline',
        now: DateTime(2026, 8, 26, 14),
        remindAt: DateTime(2026, 8, 26, 15),
      );

      expect(
        await repository.getDueReminders(
          recipientUserId: 'aline',
          now: DateTime(2026, 8, 26, 14, 30),
        ),
        isEmpty,
      );
      final due = await repository.getDueReminders(
        recipientUserId: 'aline',
        now: DateTime(2026, 8, 26, 15),
      );
      expect(due, hasLength(1));
      await repository.markDelivered(
        reminderId: due.single.id,
        deliveredAt: DateTime(2026, 8, 26, 15),
      );
      expect(
        await repository.getDueReminders(
          recipientUserId: 'aline',
          now: DateTime(2026, 8, 26, 16),
        ),
        isEmpty,
      );
    });
  });
}

HouseholdTask _task({
  required String assigneeId,
  HouseholdTaskScope scope = HouseholdTaskScope.shared,
}) {
  return HouseholdTask(
    id: 'task-1',
    scopeId: scope == HouseholdTaskScope.personal ? 'user:aline' : 'household:aline|matheus',
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

  @override
  Future<List<HouseholdTaskReminder>> getDueReminders({
    required String recipientUserId,
    required DateTime now,
  }) async {
    return reminders
        .where(
          (reminder) =>
              reminder.recipientUserId == recipientUserId &&
              reminder.isDue &&
              !reminder.remindAt.isAfter(now),
        )
        .toList();
  }

  @override
  Future<void> markDelivered({
    required String reminderId,
    required DateTime deliveredAt,
  }) async {
    final index = reminders.indexWhere((item) => item.id == reminderId);
    if (index == -1) return;
    final current = reminders[index];
    reminders[index] = HouseholdTaskReminder(
      id: current.id,
      taskId: current.taskId,
      scopeId: current.scopeId,
      senderUserId: current.senderUserId,
      recipientUserId: current.recipientUserId,
      kind: current.kind,
      status: HouseholdTaskReminderStatus.delivered,
      remindAt: current.remindAt,
      createdAt: current.createdAt,
      deliveredAt: deliveredAt,
    );
  }
}
