import 'package:uuid/uuid.dart';

import '../models/household_routine.dart';
import '../models/household_task.dart';
import '../repositories/household_routine_repository.dart';
import '../repositories/household_task_repository.dart';

class HouseholdRoutineService {
  final HouseholdTaskRepository taskRepository;
  final HouseholdRoutineRepository routineRepository;
  final Uuid uuid;

  const HouseholdRoutineService({
    required this.taskRepository,
    required this.routineRepository,
    this.uuid = const Uuid(),
  });

  Future<HouseholdTask> startRoutine({
    required HouseholdRoutine routine,
    required HouseholdTaskScope scope,
    required DateTime startsAt,
  }) async {
    final firstStep = routine.stepAt(0)!;
    final existing = await taskRepository.findPendingRoutineStep(
      routineId: routine.id,
      stepIndex: 0,
      scopeId: routine.scopeId,
    );
    if (existing != null) return existing;

    final task = _buildTask(
      routine: routine,
      step: firstStep,
      stepIndex: 0,
      scope: scope,
      dueAt: startsAt,
      createdAt: startsAt,
    );
    await taskRepository.saveTask(task);
    return task;
  }

  Future<HouseholdTask?> completeTask({
    required String taskId,
    required DateTime completedAt,
  }) async {
    final task = await taskRepository.getTaskById(taskId);
    if (task == null) throw StateError('Household task not found: $taskId');
    if (!task.isPending) return null;

    await taskRepository.saveTask(task.complete(completedAt));

    if (!task.belongsToRoutine) {
      if (!task.isRecurring) return null;
      final nextDueAt = completedAt.add(Duration(days: task.repeatEveryDays!));
      final nextTask = HouseholdTask(
        id: uuid.v4(),
        scopeId: task.scopeId,
        scope: task.scope,
        title: task.title,
        notes: task.notes,
        assigneeId: task.assigneeId,
        status: HouseholdTaskStatus.pending,
        dueAt: nextDueAt,
        repeatEveryDays: task.repeatEveryDays,
        createdAt: completedAt,
        updatedAt: completedAt,
        previousTaskId: task.id,
      );
      await taskRepository.saveTask(nextTask);
      return nextTask;
    }

    final routine = await routineRepository.getRoutineById(task.routineId!);
    if (routine == null) return null;

    final currentStepIndex = task.routineStepIndex!;
    final nextStep = routine.nextStepAfter(currentStepIndex);
    if (nextStep != null) {
      return _createNextStepIfNeeded(
        routine: routine,
        task: task,
        step: nextStep,
        stepIndex: currentStepIndex + 1,
        completedAt: completedAt,
      );
    }

    if (!routine.isRecurring) return null;

    final existingFirst = await taskRepository.findPendingRoutineStep(
      routineId: routine.id,
      stepIndex: 0,
      scopeId: task.scopeId,
    );
    if (existingFirst != null) return existingFirst;

    final firstStep = routine.stepAt(0)!;
    final dueAt = completedAt.add(Duration(days: routine.repeatEveryDays!));
    final nextCycle = _buildTask(
      routine: routine,
      step: firstStep,
      stepIndex: 0,
      scope: task.scope,
      dueAt: dueAt,
      createdAt: completedAt,
      previousTaskId: task.id,
    );
    await taskRepository.saveTask(nextCycle);
    return nextCycle;
  }

  Future<HouseholdTask> _createNextStepIfNeeded({
    required HouseholdRoutine routine,
    required HouseholdTask task,
    required HouseholdRoutineStep step,
    required int stepIndex,
    required DateTime completedAt,
  }) async {
    final existing = await taskRepository.findPendingRoutineStep(
      routineId: routine.id,
      stepIndex: stepIndex,
      scopeId: task.scopeId,
    );
    if (existing != null) return existing;

    final nextTask = _buildTask(
      routine: routine,
      step: step,
      stepIndex: stepIndex,
      scope: task.scope,
      dueAt: completedAt.add(step.delayAfterPrevious),
      createdAt: completedAt,
      previousTaskId: task.id,
    );
    await taskRepository.saveTask(nextTask);
    return nextTask;
  }

  HouseholdTask _buildTask({
    required HouseholdRoutine routine,
    required HouseholdRoutineStep step,
    required int stepIndex,
    required HouseholdTaskScope scope,
    required DateTime dueAt,
    required DateTime createdAt,
    String? previousTaskId,
  }) {
    return HouseholdTask(
      id: uuid.v4(),
      scopeId: routine.scopeId,
      scope: scope,
      title: step.title,
      notes: step.notes,
      assigneeId: step.assigneeId,
      status: HouseholdTaskStatus.pending,
      dueAt: dueAt,
      createdAt: createdAt,
      updatedAt: createdAt,
      routineId: routine.id,
      routineStepIndex: stepIndex,
      previousTaskId: previousTaskId,
    );
  }

  Future<void> cancelTask({
    required String taskId,
    required DateTime cancelledAt,
  }) async {
    final task = await taskRepository.getTaskById(taskId);
    if (task == null) throw StateError('Household task not found: $taskId');
    if (!task.isPending) return;
    await taskRepository.saveTask(task.cancel(cancelledAt));
  }
}
