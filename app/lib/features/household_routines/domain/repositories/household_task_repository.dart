import '../models/household_task.dart';

abstract class HouseholdTaskRepository {
  Future<void> saveTask(HouseholdTask task);

  Future<HouseholdTask?> getTaskById(String taskId);

  Future<List<HouseholdTask>> getTasksByScope(String scopeId);

  Future<List<HouseholdTask>> getPendingTasksByScope(String scopeId);

  Future<HouseholdTask?> findPendingRoutineStep({
    required String routineId,
    required int stepIndex,
    required String scopeId,
  });
}
