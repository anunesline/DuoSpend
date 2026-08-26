import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/household_routines/domain/models/household_routine.dart';
import 'package:app/features/household_routines/domain/models/household_task.dart';
import 'package:app/features/household_routines/domain/repositories/household_routine_repository.dart';
import 'package:app/features/household_routines/domain/repositories/household_task_repository.dart';
import 'package:app/features/household_routines/domain/services/household_routine_service.dart';
import 'package:app/features/household_routines/domain/services/household_scope_id.dart';

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

  test('tarefa simples recorrente cria proxima ocorrencia pela conclusao real', () async {
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
  });

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
    expect(tasks.tasks.where((item) => item.previousTaskId == task.id), hasLength(1));
  });
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
    routines.add(routine);
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
