import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/household_task.dart';
import '../../domain/repositories/household_task_repository.dart';

class FirestoreHouseholdTaskRepository implements HouseholdTaskRepository {
  final FirebaseFirestore firestore;

  FirestoreHouseholdTaskRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('household_tasks');

  @override
  Future<void> saveTask(HouseholdTask task) async {
    await _collection.doc(task.id).set(task.toMap());
  }

  @override
  Future<HouseholdTask?> getTaskById(String taskId) async {
    final snapshot = await _collection.doc(taskId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return HouseholdTask.fromMap(data);
  }

  @override
  Future<List<HouseholdTask>> getTasksByScope(String scopeId) async {
    final snapshot = await _collection.where('scopeId', isEqualTo: scopeId).get();
    final tasks = snapshot.docs
        .map((doc) => HouseholdTask.fromMap(doc.data()))
        .toList();

    tasks.sort((a, b) {
      final aDate = a.dueAt ?? a.createdAt;
      final bDate = b.dueAt ?? b.createdAt;
      return aDate.compareTo(bDate);
    });

    return tasks;
  }

  @override
  Future<List<HouseholdTask>> getPendingTasksByScope(String scopeId) async {
    final tasks = await getTasksByScope(scopeId);
    return tasks.where((task) => task.isPending).toList();
  }

  @override
  Future<HouseholdTask?> findPendingRoutineStep({
    required String routineId,
    required int stepIndex,
    required String scopeId,
  }) async {
    final tasks = await getTasksByScope(scopeId);

    for (final task in tasks) {
      if (task.routineId == routineId &&
          task.routineStepIndex == stepIndex &&
          task.isPending) {
        return task;
      }
    }

    return null;
  }
}
