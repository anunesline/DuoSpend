import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/household_routine.dart';
import '../../domain/repositories/household_routine_repository.dart';

class FirestoreHouseholdRoutineRepository implements HouseholdRoutineRepository {
  final FirebaseFirestore firestore;

  FirestoreHouseholdRoutineRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('household_routines');

  @override
  Future<void> saveRoutine(HouseholdRoutine routine) async {
    await _collection.doc(routine.id).set(routine.toMap());
  }

  @override
  Future<HouseholdRoutine?> getRoutineById(String routineId) async {
    final snapshot = await _collection.doc(routineId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return HouseholdRoutine.fromMap(data);
  }

  @override
  Future<List<HouseholdRoutine>> getRoutinesByScope(String scopeId) async {
    final snapshot = await _collection.where('scopeId', isEqualTo: scopeId).get();
    final routines = snapshot.docs
        .map((doc) => HouseholdRoutine.fromMap(doc.data()))
        .toList();

    routines.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return routines;
  }
}
