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

    if (existing != null) {
      return existing;
    }

    final task = HouseholdTask(
      id: uuid.v4(),
      scopeId: routine.scopeId,
      scope: scope,
      title: firstStep.title,
      notes: firstStep.notes,
      assigneeId: firstStep.assigneeId,
      status: HouseholdTaskStatus.pending,
      dueAt: startsAt,
      createdAt: startsAt,
      updatedAt: startsAt,
      routineId: routine.id,
      routineStepIndex: 0,
    );

    await taskRepository.saveTask(task);
    return task;
  }

  Future<HouseholdTask?> completeTask({
    required String taskId,
    required DateTime completedAt,
  }) async {
    final task = await taskRepository.getTaskById(taskId);

    if (task == null) {
      throw StateError('Household task not found: $taskId');
    }

    if (!task.isPending) {
      return null;
    }

    final completedTask = task.complete(completedAt);
    await taskRepository.saveTask(completedTask);

    if (!task.belongsToRoutine) {
      return null;
    }

    final routine = await routineRepository.getRoutineById(task.routineId!);

    if (routine == null) {
      return null;
    }

    final currentStepIndex = task.routineStepIndex!;
    final nextStep = routine.nextStepAfter(currentStepIndex);

    if (nextStep == null) {
      return null;
    }

    final nextStepIndex = currentStepIndex + 1;
    final existingNextTask = await taskRepository.findPendingRoutineStep(
      routineId: routine.id,
      stepIndex: nextStepIndex,
      scopeId: task.scopeId,
    );

    if (existingNextTask != null) {
      return existingNextTask;
    }

    final dueAt = completedAt.add(nextStep.delayAfterPrevious);

    final nextTask = HouseholdTask(
      id: uuid.v4(),
      scopeId: task.scopeId,
      scope: task.scope,
      title: nextStep.title,
      notes: nextStep.notes,
      assigneeId: nextStep.assigneeId,
      status: HouseholdTaskStatus.pending,
      dueAt: dueAt,
      createdAt: completedAt,
      updatedAt: completedAt,
      routineId: routine.id,
      routineStepIndex: nextStepIndex,
      previousTaskId: task.id,
    );

    await taskRepository.saveTask(nextTask);
    return nextTask;
  }

  Future<void> cancelTask({
    required String taskId,
    required DateTime cancelledAt,
  }) async {
    final task = await taskRepository.getTaskById(taskId);

    if (task == null) {
      throw StateError('Household task not found: $taskId');
    }

    if (!task.isPending) {
      return;
    }

    await taskRepository.saveTask(task.cancel(cancelledAt));
  }
}
