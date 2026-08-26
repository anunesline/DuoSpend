import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/household_task_reminder.dart';
import '../../domain/repositories/household_task_reminder_repository.dart';

class FirestoreHouseholdTaskReminderRepository
    implements HouseholdTaskReminderRepository {
  final FirebaseFirestore firestore;

  FirestoreHouseholdTaskReminderRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('household_task_reminders');

  @override
  Future<void> saveReminder(HouseholdTaskReminder reminder) async {
    await _collection.doc(reminder.id).set(reminder.toMap());
  }

  @override
  Future<HouseholdTaskReminder?> getLatestReminder({
    required String taskId,
    required String senderUserId,
    required String recipientUserId,
  }) async {
    final snapshot = await _collection.where('taskId', isEqualTo: taskId).get();
    final reminders = snapshot.docs
        .map((doc) => HouseholdTaskReminder.fromMap(doc.data()))
        .where(
          (reminder) =>
              reminder.senderUserId == senderUserId &&
              reminder.recipientUserId == recipientUserId,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return reminders.isEmpty ? null : reminders.first;
  }

  @override
  Future<List<HouseholdTaskReminder>> getDueReminders({
    required String recipientUserId,
    required DateTime now,
  }) async {
    final snapshot = await _collection
        .where('recipientUserId', isEqualTo: recipientUserId.trim())
        .get();
    final reminders = snapshot.docs
        .map((doc) => HouseholdTaskReminder.fromMap(doc.data()))
        .where(
          (reminder) =>
              reminder.isDue && !reminder.remindAt.isAfter(now),
        )
        .toList()
      ..sort((a, b) => a.remindAt.compareTo(b.remindAt));
    return List.unmodifiable(reminders);
  }

  @override
  Future<void> markDelivered({
    required String reminderId,
    required DateTime deliveredAt,
  }) async {
    await _collection.doc(reminderId).set(
      {
        'status': HouseholdTaskReminderStatus.delivered.name,
        'deliveredAt': deliveredAt.toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }
}
