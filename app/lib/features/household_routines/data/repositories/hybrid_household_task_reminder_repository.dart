import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../../core/notifications/local_reminder_notification_service.dart';
import '../../domain/models/household_task_reminder.dart';
import '../../domain/repositories/household_task_repository.dart';
import '../../domain/repositories/household_task_reminder_repository.dart';

class HybridHouseholdTaskReminderRepository
    implements HouseholdTaskReminderRepository {
  static const _defaultEndpoint = String.fromEnvironment(
    'HOUSEHOLD_REMINDER_ENDPOINT',
  );

  final HouseholdTaskRepository taskRepository;
  final LocalReminderNotificationService localNotifications;
  final FirebaseAuth auth;
  final http.Client client;
  final String partnerReminderEndpoint;

  HybridHouseholdTaskReminderRepository({
    required this.taskRepository,
    LocalReminderNotificationService? localNotifications,
    FirebaseAuth? auth,
    http.Client? client,
    String partnerReminderEndpoint = _defaultEndpoint,
  })  : localNotifications =
            localNotifications ?? LocalReminderNotificationService(),
        auth = auth ?? FirebaseAuth.instance,
        client = client ?? http.Client(),
        partnerReminderEndpoint = partnerReminderEndpoint.trim();

  @override
  Future<void> saveReminder(HouseholdTaskReminder reminder) async {
    if (reminder.kind == HouseholdTaskReminderKind.self) {
      await _scheduleLocalReminder(reminder);
      return;
    }

    await _sendPartnerReminder(reminder);
  }

  Future<void> _scheduleLocalReminder(HouseholdTaskReminder reminder) async {
    final task = await taskRepository.getTaskById(reminder.taskId);
    await localNotifications.schedule(
      reminderId: reminder.id,
      taskId: reminder.taskId,
      taskTitle: task?.title ?? 'Você tem uma tarefa da casa pendente.',
      remindAt: reminder.remindAt,
    );
  }

  Future<void> _sendPartnerReminder(HouseholdTaskReminder reminder) async {
    if (partnerReminderEndpoint.isEmpty) {
      throw StateError(
        'HOUSEHOLD_REMINDER_ENDPOINT não foi configurado para esta build.',
      );
    }

    final user = auth.currentUser;
    if (user == null) {
      throw StateError('É necessário estar autenticado para enviar lembretes.');
    }
    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Não foi possível validar a sessão atual.');
    }

    final response = await client.post(
      Uri.parse(partnerReminderEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'reminderId': reminder.id,
        'taskId': reminder.taskId,
      }),
    );

    if (response.statusCode == 429) {
      final data = _decodeJson(response.body);
      final seconds = _readPositiveInt(data['retryAfterSeconds']);
      throw HouseholdReminderCooldownException(
        Duration(seconds: seconds ?? 1),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeJson(response.body);
      final message = data['error']?.toString().trim();
      throw StateError(
        message == null || message.isEmpty
            ? 'Não foi possível enviar o lembrete ao responsável.'
            : message,
      );
    }
  }

  @override
  Future<HouseholdTaskReminder?> getLatestReminder({
    required String taskId,
    required String senderUserId,
    required String recipientUserId,
  }) async {
    // O cooldown autoritativo é validado no Worker. O domínio mantém esta
    // consulta para repositórios locais/fakes e para preservar os testes da regra.
    return null;
  }

  static Map<String, dynamic> _decodeJson(String source) {
    if (source.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(source);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  static int? _readPositiveInt(Object? value) {
    final parsed = value is num
        ? value.ceil()
        : int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : null;
  }
}
