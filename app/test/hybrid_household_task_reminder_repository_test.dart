import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app/features/household_routines/data/repositories/hybrid_household_task_reminder_repository.dart';
import 'package:app/features/household_routines/domain/models/household_task.dart';
import 'package:app/features/household_routines/domain/models/household_task_reminder.dart';
import 'package:app/features/household_routines/domain/repositories/household_task_repository.dart';
import 'package:app/features/household_routines/domain/repositories/household_task_reminder_repository.dart';
import 'package:app/features/household_routines/domain/services/household_task_reminder_service.dart';

class _User extends Fake implements User {
  String? token = 'firebase-id-token';
  bool? forced;
  @override
  String get uid => 'alice';
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    forced = forceRefresh;
    return token;
  }
}

class _Auth extends Fake implements FirebaseAuth {
  User? user;
  _Auth(this.user);
  @override
  User? get currentUser => user;
}

class _Tasks extends Fake implements HouseholdTaskRepository {}

void main() {
  final now = DateTime(2026, 9, 22);
  final task = HouseholdTask(
    id: 'task',
    scopeId: 'household:alice|bob',
    scope: HouseholdTaskScope.shared,
    title: 'Tarefa',
    assigneeId: 'bob',
    status: HouseholdTaskStatus.pending,
    createdAt: now,
    updatedAt: now,
  );
  final reminder = HouseholdTaskReminder(
    id: '12345678-1234-4234-8234-123456789abc',
    taskId: task.id,
    scopeId: task.scopeId,
    senderUserId: 'alice',
    recipientUserId: 'bob',
    kind: HouseholdTaskReminderKind.partner,
    status: HouseholdTaskReminderStatus.pendingDelivery,
    remindAt: now,
    createdAt: now,
  );
  late _User user;
  late _Auth auth;
  late List<http.Request> requests;
  late http.Response reply;
  HybridHouseholdTaskReminderRepository repository({
    String endpoint = 'https://worker/household/reminders',
  }) => HybridHouseholdTaskReminderRepository(
    taskRepository: _Tasks(),
    auth: auth,
    partnerReminderEndpoint: endpoint,
    client: MockClient((request) async {
      requests.add(request);
      return reply;
    }),
  );
  setUp(() {
    user = _User();
    auth = _Auth(user);
    requests = [];
    reply = http.Response('{"ok":true,"messageId":"message"}', 200);
  });
  test('envia token Firebase e apenas reminderId/taskId', () async {
    await repository().saveReminder(reminder);
    expect(user.forced, isTrue);
    expect(
      requests.single.headers['Authorization'],
      'Bearer firebase-id-token',
    );
    expect(jsonDecode(requests.single.body), {
      'reminderId': reminder.id,
      'taskId': 'task',
    });
  });
  test('sucesso confirmado produz resultado enviado', () async {
    final service = HouseholdTaskReminderService(repository: repository());
    final result = await service.remindAssignee(
      task: task,
      senderUserId: 'alice',
      now: now,
    );
    expect(result.sent, isTrue);
    expect(result.reminder?.recipientUserId, 'bob');
  });
  test('replay idempotente confirmado também é sucesso', () async {
    reply = http.Response(
      '{"ok":true,"idempotent":true,"messageId":"message"}',
      200,
    );
    await expectLater(repository().saveReminder(reminder), completes);
  });
  for (final status in [401, 403, 404, 409, 422, 500, 502, 503]) {
    test('erro HTTP $status preserva categoria e não vira sucesso', () async {
      reply = http.Response('{"error":"Falha de envio"}', status);
      final service = HouseholdTaskReminderService(repository: repository());
      await expectLater(
        service.remindAssignee(task: task, senderUserId: 'alice', now: now),
        throwsA(
          isA<HouseholdReminderDeliveryException>().having(
            (e) => e.statusCode,
            'status',
            status,
          ),
        ),
      );
    });
  }
  for (final body in [
    '{}',
    '{"ok":false}',
    '{"ok":true}',
    'invalid',
    '{"ok":true,"messageId":""}',
  ]) {
    test('resposta sem confirmação válida é rejeitada: $body', () async {
      reply = http.Response(body, 200);
      await expectLater(
        repository().saveReminder(reminder),
        throwsA(isA<HouseholdReminderDeliveryException>()),
      );
    });
  }
  test('429 produz bloqueio com retryAfter', () async {
    reply = http.Response('{"retryAfterSeconds":120}', 429);
    final result = await HouseholdTaskReminderService(
      repository: repository(),
    ).remindAssignee(task: task, senderUserId: 'alice', now: now);
    expect(result.sent, isFalse);
    expect(result.retryAfter, const Duration(seconds: 120));
  });
  test('endpoint ausente não faz requisição', () async {
    await expectLater(
      repository(endpoint: '').saveReminder(reminder),
      throwsStateError,
    );
    expect(requests, isEmpty);
  });
  test('usuário ausente não faz requisição', () async {
    auth.user = null;
    await expectLater(repository().saveReminder(reminder), throwsStateError);
    expect(requests, isEmpty);
  });
  test('token ausente não faz requisição', () async {
    user.token = null;
    await expectLater(repository().saveReminder(reminder), throwsStateError);
    expect(requests, isEmpty);
  });
}
