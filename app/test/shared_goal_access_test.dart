import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/goals/data/models/savings_goal_model.dart';
import 'package:app/features/goals/data/repositories/savings_goal_repository.dart';
import 'package:app/features/goals/domain/models/savings_goal.dart';

void main() {
  MockFirebaseAuth auth(String userId) => MockFirebaseAuth(
        mockUser: MockUser(uid: userId),
        signedIn: true,
      );

  SavingsGoal sharedGoal() => SavingsGoal(
        id: 'shared-goal',
        name: 'Viagem',
        targetAmount: 3000,
        walletId: 'shared-wallet',
        createdByUserId: 'aline',
        memberIds: const ['aline', 'matheus'],
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

  test('membro consulta meta compartilhada, não membro é bloqueado', () async {
    final firestore = FakeFirebaseFirestore();
    final goal = sharedGoal();
    await firestore
        .collection('savingsGoals')
        .doc(goal.id)
        .set(SavingsGoalModel.toMap(goal));

    final memberRepository = SavingsGoalRepository(
      firestore: firestore,
      auth: auth('matheus'),
    );
    final outsiderRepository = SavingsGoalRepository(
      firestore: firestore,
      auth: auth('outsider'),
    );

    expect((await memberRepository.getGoalById(goal.id))?.id, goal.id);
    await expectLater(
      outsiderRepository.getGoalById(goal.id),
      throwsStateError,
    );
  });
}
