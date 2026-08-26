import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/household_routines/data/repositories/firestore_household_task_reminder_repository.dart';
import 'package:app/features/household_routines/data/repositories/firestore_household_task_repository.dart';
import 'package:app/features/household_routines/domain/models/household_task.dart';
import 'package:app/features/household_routines/domain/models/household_task_reminder.dart';

void main() {
  test('Firestore persiste recorrencia de tarefa simples', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreHouseholdTaskRepository(firestore: firestore);
    final task = HouseholdTask(
      id: 'trash',
      scopeId: 'user:aline',
      scope: HouseholdTaskScope.personal,
      title: 'Tirar o lixo',
      status: HouseholdTaskStatus.pending,
      dueAt: DateTime(2026, 8, 27, 22),
      repeatEveryDays: 7,
      createdAt: DateTime(2026, 8, 26),
      updatedAt: DateTime(2026, 8, 26),
    );

    await repository.saveTask(task);
    final restored = await repository.getTaskById(task.id);

    expect(restored?.repeatEveryDays, 7);
    expect(restored?.isRecurring, isTrue);
    expect(restored?.dueAt, DateTime(2026, 8, 27, 22));
  });

  test('Firestore entrega somente lembrete vencido e marca como entregue', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreHouseholdTaskReminderRepository(
      firestore: firestore,
    );
    final reminder = HouseholdTaskReminder(
      id: 'reminder-1',
      taskId: 'trash',
      scopeId: 'user:aline',
      senderUserId: 'aline',
      recipientUserId: 'aline',
      kind: HouseholdTaskReminderKind.self,
      status: HouseholdTaskReminderStatus.scheduled,
      remindAt: DateTime(2026, 8, 26, 18),
      createdAt: DateTime(2026, 8, 26, 14),
    );
    await repository.saveReminder(reminder);

    expect(
      await repository.getDueReminders(
        recipientUserId: 'aline',
        now: DateTime(2026, 8, 26, 17, 59),
      ),
      isEmpty,
    );
    final due = await repository.getDueReminders(
      recipientUserId: 'aline',
      now: DateTime(2026, 8, 26, 18),
    );
    expect(due, hasLength(1));

    await repository.markDelivered(
      reminderId: reminder.id,
      deliveredAt: DateTime(2026, 8, 26, 18),
    );
    expect(
      await repository.getDueReminders(
        recipientUserId: 'aline',
        now: DateTime(2026, 8, 26, 19),
      ),
      isEmpty,
    );
  });
}
