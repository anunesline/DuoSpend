import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/household_routines/domain/models/household_routine.dart';
import 'package:app/features/household_routines/domain/models/household_task.dart';
import 'package:app/features/household_routines/domain/repositories/household_routine_repository.dart';
import 'package:app/features/household_routines/domain/repositories/household_task_repository.dart';
import 'package:app/features/household_routines/domain/services/household_routine_service.dart';

void main() {
  group('HouseholdRoutineService', () {
    test('encadeia tarefas a partir do completedAt real', () async {
      final taskRepository = _FakeTaskRepository();
      final routineRepository = _FakeRoutineRepository();
      final service = HouseholdRoutineService(
        taskRepository: taskRepository,
        routineRepository: routineRepository,
      );

      final routine = HouseholdRoutine(
        id: 'laundry',
        scopeId: 'shared-home',
        name: 'Roupas',
        steps: const [
          HouseholdRoutineStep(title: 'Lavar roupa'),
          HouseholdRoutineStep(
            title: 'Estender roupa',
            delayAfterPrevious: Duration(hours: 2),
          ),
          HouseholdRoutineStep(
            title: 'Recolher roupa',
            delayAfterPrevious: Duration(hours: 6),
          ),
          HouseholdRoutineStep(title: 'Dobrar e guardar'),
        ],
        createdAt: DateTime(2026, 8, 26, 8),
        updatedAt: DateTime(2026, 8, 26, 8),
      );

      await routineRepository.saveRoutine(routine);

      final first = await service.startRoutine(
        routine: routine,
        scope: HouseholdTaskScope.shared,
        startsAt: DateTime(2026, 8, 26, 9),
      );

      final washCompletedAt = DateTime(2026, 8, 26, 10, 15);
      final stretch = await service.completeTask(
        taskId: first.id,
        completedAt: washCompletedAt,
      );

      expect(stretch?.title, 'Estender roupa');
      expect(stretch?.dueAt, DateTime(2026, 8, 26, 12, 15));

      final stretchCompletedAt = DateTime(2026, 8, 26, 13);
      final collect = await service.completeTask(
        taskId: stretch!.id,
        completedAt: stretchCompletedAt,
      );

      expect(collect?.title, 'Recolher roupa');
      expect(collect?.dueAt, DateTime(2026, 8, 26, 19));

      final collectCompletedAt = DateTime(2026, 8, 26, 19, 30);
      final fold = await service.completeTask(
        taskId: collect!.id,
        completedAt: collectCompletedAt,
      );

      expect(fold?.title, 'Dobrar e guardar');
      expect(fold?.dueAt, collectCompletedAt);
    });

    test('nao duplica a proxima etapa ao concluir duas vezes', () async {
      final taskRepository = _FakeTaskRepository();
      final routineRepository = _FakeRoutineRepository();
      final service = HouseholdRoutineService(
        taskRepository: taskRepository,
        routineRepository: routineRepository,
      );

      final routine = HouseholdRoutine(
        id: 'laundry',
        scopeId: 'me',
        name: 'Roupas',
        steps: const [
          HouseholdRoutineStep(title: 'Lavar roupa'),
          HouseholdRoutineStep(title: 'Estender roupa'),
        ],
        createdAt: DateTime(2026, 8, 26),
        updatedAt: DateTime(2026, 8, 26),
      );

      await routineRepository.saveRoutine(routine);

      final first = await service.startRoutine(
        routine: routine,
        scope: HouseholdTaskScope.personal,
        startsAt: DateTime(2026, 8, 26, 8),
      );

      final generated = await service.completeTask(
        taskId: first.id,
        completedAt: DateTime(2026, 8, 26, 9),
      );

      final secondAttempt = await service.completeTask(
        taskId: first.id,
        completedAt: DateTime(2026, 8, 26, 9, 5),
      );

      expect(generated, isNotNull);
      expect(secondAttempt, isNull);
      expect(
        taskRepository.tasks.where((task) => task.routineStepIndex == 1),
        hasLength(1),
      );
    });

    test('cancelar uma etapa nao dispara o proximo gatilho', () async {
      final taskRepository = _FakeTaskRepository();
      final routineRepository = _FakeRoutineRepository();
      final service = HouseholdRoutineService(
        taskRepository: taskRepository,
        routineRepository: routineRepository,
      );

      final routine = HouseholdRoutine(
        id: 'laundry',
        scopeId: 'me',
        name: 'Roupas',
        steps: const [
          HouseholdRoutineStep(title: 'Lavar roupa'),
          HouseholdRoutineStep(title: 'Estender roupa'),
        ],
        createdAt: DateTime(2026, 8, 26),
        updatedAt: DateTime(2026, 8, 26),
      );

      await routineRepository.saveRoutine(routine);

      final first = await service.startRoutine(
        routine: routine,
        scope: HouseholdTaskScope.personal,
        startsAt: DateTime(2026, 8, 26, 8),
      );

      await service.cancelTask(
        taskId: first.id,
        cancelledAt: DateTime(2026, 8, 26, 8, 30),
      );

      expect(taskRepository.tasks, hasLength(1));
      expect(taskRepository.tasks.single.status, HouseholdTaskStatus.cancelled);
    });

    test('preserva responsavel definido em cada etapa', () async {
      final taskRepository = _FakeTaskRepository();
      final routineRepository = _FakeRoutineRepository();
      final service = HouseholdRoutineService(
        taskRepository: taskRepository,
        routineRepository: routineRepository,
      );

      final routine = HouseholdRoutine(
        id: 'laundry',
        scopeId: 'shared-home',
        name: 'Roupas',
        steps: const [
          HouseholdRoutineStep(title: 'Lavar roupa', assigneeId: 'aline'),
          HouseholdRoutineStep(title: 'Estender roupa', assigneeId: 'matheus'),
        ],
        createdAt: DateTime(2026, 8, 26),
        updatedAt: DateTime(2026, 8, 26),
      );

      await routineRepository.saveRoutine(routine);

      final first = await service.startRoutine(
        routine: routine,
        scope: HouseholdTaskScope.shared,
        startsAt: DateTime(2026, 8, 26, 8),
      );

      final next = await service.completeTask(
        taskId: first.id,
        completedAt: DateTime(2026, 8, 26, 9),
      );

      expect(first.assigneeId, 'aline');
      expect(next?.assigneeId, 'matheus');
    });
  });
}

class _FakeTaskRepository implements HouseholdTaskRepository {
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
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  @override
  Future<List<HouseholdTask>> getTasksByScope(String scopeId) async {
    return tasks.where((task) => task.scopeId == scopeId).toList();
  }

  @override
  Future<List<HouseholdTask>> getPendingTasksByScope(String scopeId) async {
    return tasks
        .where((task) => task.scopeId == scopeId && task.isPending)
        .toList();
  }

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

class _FakeRoutineRepository implements HouseholdRoutineRepository {
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
      if (routine.id == routineId) {
        return routine;
      }
    }
    return null;
  }

  @override
  Future<List<HouseholdRoutine>> getRoutinesByScope(String scopeId) async {
    return routines.where((routine) => routine.scopeId == scopeId).toList();
  }
}
