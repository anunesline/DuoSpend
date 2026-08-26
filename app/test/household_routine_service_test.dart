import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/household_routines/domain/models/household_routine.dart';
import 'package:app/features/household_routines/domain/models/household_task.dart';
import 'package:app/features/household_routines/domain/repositories/household_routine_repository.dart';
import 'package:app/features/household_routines/domain/repositories/household_task_repository.dart';
import 'package:app/features/household_routines/domain/services/household_routine_service.dart';

void main() {
  group('HouseholdRoutineService', () {
    test('encadeia tarefas a partir do completedAt real', () async {
      final tasks = _FakeTaskRepository(); final routines = _FakeRoutineRepository(); final service = HouseholdRoutineService(taskRepository: tasks, routineRepository: routines);
      final routine = _routine(steps: const [HouseholdRoutineStep(title: 'Lavar roupa'), HouseholdRoutineStep(title: 'Estender roupa', delayAfterPrevious: Duration(hours: 2)), HouseholdRoutineStep(title: 'Recolher roupa', delayAfterPrevious: Duration(hours: 6)), HouseholdRoutineStep(title: 'Dobrar e guardar')]);
      await routines.saveRoutine(routine);
      final first = await service.startRoutine(routine: routine, scope: HouseholdTaskScope.shared, startsAt: DateTime(2026, 8, 26, 9));
      final stretch = await service.completeTask(taskId: first.id, completedAt: DateTime(2026, 8, 26, 10, 15));
      expect(stretch?.title, 'Estender roupa'); expect(stretch?.dueAt, DateTime(2026, 8, 26, 12, 15));
      final collect = await service.completeTask(taskId: stretch!.id, completedAt: DateTime(2026, 8, 26, 13));
      expect(collect?.dueAt, DateTime(2026, 8, 26, 19));
      final fold = await service.completeTask(taskId: collect!.id, completedAt: DateTime(2026, 8, 26, 19, 30));
      expect(fold?.title, 'Dobrar e guardar'); expect(fold?.dueAt, DateTime(2026, 8, 26, 19, 30));
    });

    test('nao duplica a proxima etapa ao concluir duas vezes', () async {
      final tasks = _FakeTaskRepository(); final routines = _FakeRoutineRepository(); final service = HouseholdRoutineService(taskRepository: tasks, routineRepository: routines);
      final routine = _routine(scopeId: 'me', steps: const [HouseholdRoutineStep(title: 'Lavar roupa'), HouseholdRoutineStep(title: 'Estender roupa')]);
      await routines.saveRoutine(routine);
      final first = await service.startRoutine(routine: routine, scope: HouseholdTaskScope.personal, startsAt: DateTime(2026, 8, 26, 8));
      final generated = await service.completeTask(taskId: first.id, completedAt: DateTime(2026, 8, 26, 9));
      final secondAttempt = await service.completeTask(taskId: first.id, completedAt: DateTime(2026, 8, 26, 9, 5));
      expect(generated, isNotNull); expect(secondAttempt, isNull); expect(tasks.tasks.where((task) => task.routineStepIndex == 1), hasLength(1));
    });

    test('cancelar uma etapa nao dispara o proximo gatilho', () async {
      final tasks = _FakeTaskRepository(); final routines = _FakeRoutineRepository(); final service = HouseholdRoutineService(taskRepository: tasks, routineRepository: routines);
      final routine = _routine(scopeId: 'me', steps: const [HouseholdRoutineStep(title: 'Lavar roupa'), HouseholdRoutineStep(title: 'Estender roupa')]);
      await routines.saveRoutine(routine);
      final first = await service.startRoutine(routine: routine, scope: HouseholdTaskScope.personal, startsAt: DateTime(2026, 8, 26, 8));
      await service.cancelTask(taskId: first.id, cancelledAt: DateTime(2026, 8, 26, 8, 30));
      expect(tasks.tasks, hasLength(1)); expect(tasks.tasks.single.status, HouseholdTaskStatus.cancelled);
    });

    test('preserva responsavel definido em cada etapa', () async {
      final tasks = _FakeTaskRepository(); final routines = _FakeRoutineRepository(); final service = HouseholdRoutineService(taskRepository: tasks, routineRepository: routines);
      final routine = _routine(steps: const [HouseholdRoutineStep(title: 'Lavar roupa', assigneeId: 'aline'), HouseholdRoutineStep(title: 'Estender roupa', assigneeId: 'matheus')]);
      await routines.saveRoutine(routine);
      final first = await service.startRoutine(routine: routine, scope: HouseholdTaskScope.shared, startsAt: DateTime(2026, 8, 26, 8));
      final next = await service.completeTask(taskId: first.id, completedAt: DateTime(2026, 8, 26, 9));
      expect(first.assigneeId, 'aline'); expect(next?.assigneeId, 'matheus');
    });

    test('rotina recorrente agenda novo ciclo a partir da conclusao final', () async {
      final tasks = _FakeTaskRepository(); final routines = _FakeRoutineRepository(); final service = HouseholdRoutineService(taskRepository: tasks, routineRepository: routines);
      final routine = _routine(scopeId: 'me', repeatEveryDays: 7, steps: const [HouseholdRoutineStep(title: 'Trocar roupa de cama')]);
      await routines.saveRoutine(routine);
      final first = await service.startRoutine(routine: routine, scope: HouseholdTaskScope.personal, startsAt: DateTime(2026, 8, 26, 8));
      final completedAt = DateTime(2026, 8, 26, 10, 30);
      final nextCycle = await service.completeTask(taskId: first.id, completedAt: completedAt);
      expect(nextCycle?.title, 'Trocar roupa de cama'); expect(nextCycle?.routineStepIndex, 0); expect(nextCycle?.dueAt, DateTime(2026, 9, 2, 10, 30)); expect(nextCycle?.previousTaskId, first.id);
    });
  });
}

HouseholdRoutine _routine({String scopeId = 'shared-home', int? repeatEveryDays, required List<HouseholdRoutineStep> steps}) => HouseholdRoutine(id: 'laundry', scopeId: scopeId, name: 'Roupas', steps: steps, repeatEveryDays: repeatEveryDays, createdAt: DateTime(2026, 8, 26), updatedAt: DateTime(2026, 8, 26));

class _FakeTaskRepository implements HouseholdTaskRepository {
  final List<HouseholdTask> tasks = [];
  @override Future<void> saveTask(HouseholdTask task) async { final index = tasks.indexWhere((item) => item.id == task.id); if (index == -1) { tasks.add(task); } else { tasks[index] = task; } }
  @override Future<HouseholdTask?> getTaskById(String taskId) async { for (final task in tasks) { if (task.id == taskId) return task; } return null; }
  @override Future<List<HouseholdTask>> getTasksByScope(String scopeId) async => tasks.where((task) => task.scopeId == scopeId).toList();
  @override Future<List<HouseholdTask>> getPendingTasksByScope(String scopeId) async => tasks.where((task) => task.scopeId == scopeId && task.isPending).toList();
  @override Future<HouseholdTask?> findPendingRoutineStep({required String routineId, required int stepIndex, required String scopeId}) async { for (final task in tasks) { if (task.routineId == routineId && task.routineStepIndex == stepIndex && task.scopeId == scopeId && task.isPending) return task; } return null; }
}

class _FakeRoutineRepository implements HouseholdRoutineRepository {
  final List<HouseholdRoutine> routines = [];
  @override Future<void> saveRoutine(HouseholdRoutine routine) async { final index = routines.indexWhere((item) => item.id == routine.id); if (index == -1) { routines.add(routine); } else { routines[index] = routine; } }
  @override Future<HouseholdRoutine?> getRoutineById(String routineId) async { for (final routine in routines) { if (routine.id == routineId) return routine; } return null; }
  @override Future<List<HouseholdRoutine>> getRoutinesByScope(String scopeId) async => routines.where((routine) => routine.scopeId == scopeId).toList();
}
