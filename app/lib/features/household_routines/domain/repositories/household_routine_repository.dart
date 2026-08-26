import '../models/household_routine.dart';

abstract class HouseholdRoutineRepository {
  Future<void> saveRoutine(HouseholdRoutine routine);

  Future<HouseholdRoutine?> getRoutineById(String routineId);

  Future<List<HouseholdRoutine>> getRoutinesByScope(String scopeId);
}
