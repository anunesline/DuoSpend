import 'package:app/features/household_routines/data/repositories/firestore_household_list_repository.dart';
import 'package:app/features/household_routines/data/repositories/firestore_household_routine_repository.dart';
import 'package:app/features/household_routines/data/repositories/firestore_household_task_repository.dart';
import 'package:app/features/household_routines/domain/models/household_list.dart';
import 'package:app/features/household_routines/domain/models/household_list_item.dart';
import 'package:app/features/household_routines/domain/models/household_task_reminder.dart';
import 'package:app/features/household_routines/domain/repositories/household_task_reminder_repository.dart';
import 'package:app/features/household_routines/domain/services/household_routine_service.dart';
import 'package:app/features/household_routines/domain/services/household_task_reminder_service.dart';
import 'package:app/features/household_routines/presentation/controllers/household_routines_controller.dart';
import 'package:app/features/auth/data/repositories/user_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FirestoreHouseholdListRepository lists;
  late HouseholdRoutinesController controller;

  setUp(() {
    final firestore = FakeFirebaseFirestore();
    final tasks = FirestoreHouseholdTaskRepository(firestore: firestore);
    final routines = FirestoreHouseholdRoutineRepository(firestore: firestore);
    lists = FirestoreHouseholdListRepository(firestore: firestore);
    controller = HouseholdRoutinesController(
      taskRepository: tasks,
      routineRepository: routines,
      listRepository: lists,
      routineService: HouseholdRoutineService(
        taskRepository: tasks,
        routineRepository: routines,
      ),
      reminderService: HouseholdTaskReminderService(
        repository: _ReminderRepository(),
      ),
      userRepository: UserRepository(firestore: firestore),
    );
  });

  test(
    'manual items retain their creator in personal and shared lists',
    () async {
      for (final entry in [
        ('user:aline', 'aline'),
        ('household:aline|matheus', 'matheus'),
      ]) {
        final list = await controller.createList(
          scopeId: entry.$1,
          name: 'Mercado',
          type: HouseholdListType.shopping,
        );
        final item = await controller.createListItem(
          list: list!,
          displayName: 'Leite',
          createdBy: entry.$2,
        );
        final restored = (await lists.getItemsByList(list.id)).single;
        expect(item?.createdBy, entry.$2);
        expect(restored.createdBy, entry.$2);

        await controller.setListItemPurchased(
          item: restored,
          purchased: true,
          completedBy: 'aline',
        );
        final bought = (await lists.getItemsByList(list.id)).single;
        expect(bought.createdBy, entry.$2);
        expect(bought.completedBy, 'aline');
        expect(bought.completedAt, isNotNull);
      }
    },
  );

  test('legacy item without authorship remains readable', () {
    final item = HouseholdListItem.fromMap({
      'id': 'legacy',
      'listId': 'list',
      'scopeId': 'user:aline',
      'displayName': 'Arroz',
      'status': 'pending',
      'createdAt': DateTime.utc(2026, 9, 22).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 9, 22).toIso8601String(),
    });
    expect(item.createdBy, isNull);
    expect(item.displayName, 'Arroz');
  });
}

class _ReminderRepository implements HouseholdTaskReminderRepository {
  @override
  Future<HouseholdTaskReminder?> getLatestReminder({
    required String taskId,
    required String senderUserId,
    required String recipientUserId,
  }) async => null;

  @override
  Future<void> saveReminder(HouseholdTaskReminder reminder) async {}
}
