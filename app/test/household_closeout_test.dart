import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/household_routines/domain/models/household_routine.dart';
import 'package:app/features/household_routines/domain/models/household_task.dart';
import 'package:app/features/household_routines/domain/models/household_task_reminder.dart';
import 'package:app/features/household_routines/domain/repositories/household_routine_repository.dart';
import 'package:app/features/household_routines/domain/repositories/household_task_repository.dart';
import 'package:app/features/household_routines/domain/repositories/household_task_reminder_repository.dart';
import 'package:app/features/household_routines/domain/services/household_routine_service.dart';
import 'package:app/features/household_routines/domain/services/household_scope_id.dart';
import 'package:app/features/household_routines/domain/services/household_task_reminder_service.dart';
import 'package:app/features/household_routines/presentation/controllers/household_routines_controller.dart';

void main() {
  test('household compartilhado independe da ordem e do id da carteira', () {
    expect(
      HouseholdScopeId.shared(const ['matheus', 'aline']),
      'household:aline|matheus',
    );
    expect(
      HouseholdScopeId.shared(const ['aline', 'matheus']),
      'household:aline|matheus',
    );
  });

  test(
    'tarefa simples recorrente cria proxima ocorrencia pela conclusao real',
    () async {
      final tasks = _TaskRepository();
      final routines = _RoutineRepository();
      final service = HouseholdRoutineService(
        taskRepository: tasks,
        routineRepository: routines,
      );
      final task = HouseholdTask(
        id: 'trash-1',
        scopeId: 'user:aline',
        scope: HouseholdTaskScope.personal,
        title: 'Tirar o lixo',
        assigneeId: 'aline',
        status: HouseholdTaskStatus.pending,
        dueAt: DateTime(2026, 8, 27, 22),
        repeatEveryDays: 7,
        createdAt: DateTime(2026, 8, 26),
        updatedAt: DateTime(2026, 8, 26),
      );
      await tasks.saveTask(task);

      final completedAt = DateTime(2026, 8, 28, 9, 30);
      final next = await service.completeTask(
        taskId: task.id,
        completedAt: completedAt,
      );

      expect(next, isNotNull);
      expect(next?.title, 'Tirar o lixo');
      expect(next?.repeatEveryDays, 7);
      expect(next?.dueAt, DateTime(2026, 9, 4, 9, 30));
      expect(next?.previousTaskId, task.id);
    },
  );

  test('concluir tarefa recorrente duas vezes nao duplica ocorrencia', () async {
    final tasks = _TaskRepository();
    final routines = _RoutineRepository();
    final service = HouseholdRoutineService(
      taskRepository: tasks,
      routineRepository: routines,
    );
    final task = HouseholdTask(
      id: 'trash-1',
      scopeId: 'user:aline',
      scope: HouseholdTaskScope.personal,
      title: 'Tirar o lixo',
      status: HouseholdTaskStatus.pending,
      repeatEveryDays: 7,
      createdAt: DateTime(2026, 8, 26),
      updatedAt: DateTime(2026, 8, 26),
    );
    await tasks.saveTask(task);

    final first = await service.completeTask(
      taskId: task.id,
      completedAt: DateTime(2026, 8, 26, 22),
    );
    final second = await service.completeTask(
      taskId: task.id,
      completedAt: DateTime(2026, 8, 26, 22, 5),
    );

    expect(first, isNotNull);
    expect(second, isNull);
    expect(
      tasks.tasks.where((item) => item.previousTaskId == task.id),
      hasLength(1),
    );
  });

  test('edicao de tarefa pendente permite limpar horario e recorrencia', () async {
    final tasks = _TaskRepository();
    final routines = _RoutineRepository();
    final controller = _controller(tasks, routines);
    final task = HouseholdTask(
      id: 'trash-1',
      scopeId: 'user:aline',
      scope: HouseholdTaskScope.personal,
      title: 'Tirar lixo',
      notes: 'Antes de dormir',
      assigneeId: 'aline',
      status: HouseholdTaskStatus.pending,
      dueAt: DateTime(2026, 8, 27, 22),
      repeatEveryDays: 7,
      createdAt: DateTime(2026, 8, 26),
      updatedAt: DateTime(2026, 8, 26),
    );
    await tasks.saveTask(task);

    final updated = await controller.updateTask(
      task: task,
      title: 'Tirar o lixo',
      notes: '',
      assigneeId: 'aline',
      dueAt: null,
      repeatEveryDays: null,
    );

    expect(updated?.title, 'Tirar o lixo');
    expect(updated?.notes, isNull);
    expect(updated?.dueAt, isNull);
    expect(updated?.repeatEveryDays, isNull);
    expect((await tasks.getTaskById(task.id))?.dueAt, isNull);
  });

  test('editar rotina preserva tarefas ja geradas e concluidas', () async {
    final tasks = _TaskRepository();
    final routines = _RoutineRepository();
    final controller = _controller(tasks, routines);
    final routine = HouseholdRoutine(
      id: 'laundry',
      scopeId: 'household:aline|matheus',
      name: 'Roupas',
      steps: const [
        HouseholdRoutineStep(title: 'Lavar roupa', assigneeId: 'aline'),
        HouseholdRoutineStep(
          title: 'Estender roupa',
          delayAfterPrevious: Duration(hours: 2),
          assigneeId: 'matheus',
        ),
      ],
      createdAt: DateTime(2026, 8, 26),
      updatedAt: DateTime(2026, 8, 26),
    );
    await routines.saveRoutine(routine);
    await tasks.saveTask(
      HouseholdTask(
        id: 'laundry-0',
        scopeId: routine.scopeId,
        scope: HouseholdTaskScope.shared,
        title: 'Lavar roupa',
        status: HouseholdTaskStatus.completed,
        completedAt: DateTime(2026, 8, 26, 14),
        routineId: routine.id,
        routineStepIndex: 0,
        createdAt: DateTime(2026, 8, 26, 12),
        updatedAt: DateTime(2026, 8, 26, 14),
      ),
    );

    final beforeTaskIds = tasks.tasks.map((item) => item.id).toList();
    final updated = await controller.updateRoutine(
      routine: routine,
      name: 'Roupas da semana',
      steps: const [
        HouseholdRoutineStep(title: 'Lavar roupa', assigneeId: 'aline'),
        HouseholdRoutineStep(
          title: 'Estender roupa',
          delayAfterPrevious: Duration(hours: 3),
          assigneeId: 'matheus',
        ),
        HouseholdRoutineStep(title: 'Guardar roupa', assigneeId: 'aline'),
      ],
      repeatEveryDays: 7,
    );

    expect(updated?.name, 'Roupas da semana');
    expect(updated?.steps, hasLength(3));
    expect(updated?.repeatEveryDays, 7);
    expect(tasks.tasks.map((item) => item.id).toList(), beforeTaskIds);
    expect(tasks.tasks.single.status, HouseholdTaskStatus.completed);
    expect((await routines.getRoutineById(routine.id))?.steps, hasLength(3));
  });
}

HouseholdRoutinesController _controller(
  _TaskRepository tasks,
  _RoutineRepository routines,
) {
  final routineService = HouseholdRoutineService(
    taskRepository: tasks,
    routineRepository: routines,
  );
  return HouseholdRoutinesController(
    taskRepository: tasks,
    routineRepository: routines,
    routineService: routineService,
    reminderService: HouseholdTaskReminderService(
      repository: _ReminderRepository(),
    ),
  );
}

class _TaskRepository implements HouseholdTaskRepository {
  final List<HouseholdTask> tasks = [];

  @override
  Future<void> saveTask(HouseholdTask task) async {
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      tasks.add(task);
    } else {
      tasks[index] = task;
    }
  }

  @override
  Future<HouseholdTask?> getTaskById(String taskId) async {
    for (final task in tasks) {
      if (task.id == taskId) return task;
    }
    return null;
  }

  @override
  Future<List<HouseholdTask>> getTasksByScope(String scopeId) async =>
      tasks.where((task) => task.scopeId == scopeId).toList();

  @override
  Future<List<HouseholdTask>> getPendingTasksByScope(String scopeId) async =>
      tasks.where((task) => task.scopeId == scopeId && task.isPending).toList();

  @override
  Future<HouseholdTask?> findPendingRoutineStep({
    required String routineId,
    required int stepIndex,
    required String scopeId,
  }) async {
    for (final task in tasks) {
      if (task.routineId == routineId &&
          task.routineStepIndex == stepIndex &&
          task.scopeId == scopeId &&
          task.isPending) {
        return task;
      }
    }
    return null;
  }
}

class _RoutineRepository implements HouseholdRoutineRepository {
  final List<HouseholdRoutine> routines = [];

  @override
  Future<void> saveRoutine(HouseholdRoutine routine) async {
    final index = routines.indexWhere((item) => item.id == routine.id);
    if (index == -1) {
      routines.add(routine);
    } else {
      routines[index] = routine;
    }
  }

  @override
  Future<HouseholdRoutine?> getRoutineById(String routineId) async {
    for (final routine in routines) {
      if (routine.id == routineId) return routine;
    }
    return null;
  }

  @override
  Future<List<HouseholdRoutine>> getRoutinesByScope(String scopeId) async =>
      routines.where((routine) => routine.scopeId == scopeId).toList();
}

class _ReminderRepository implements HouseholdTaskReminderRepository {
  @override
  Future<void> saveReminder(HouseholdTaskReminder reminder) async {}

  @override
  Future<HouseholdTaskReminder?> getLatestReminder({
    required String taskId,
    required String senderUserId,
    required String recipientUserId,
  }) async =>
      null;
}
