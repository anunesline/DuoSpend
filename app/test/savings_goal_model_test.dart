import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/goals/data/models/savings_goal_model.dart';
import 'package:app/features/goals/domain/models/savings_goal.dart';

void main() {
  test('serializa e restaura uma meta financeira', () {
    final goal = SavingsGoal(
      id: 'goal-1',
      name: 'Viagem',
      targetAmount: 5000,
      savedAmount: 1250,
      category: SavingsGoalCategory.travel,
      deadline: DateTime(2027, 1, 10),
      walletId: 'shared-wallet',
      createdByUserId: 'user-1',
      memberIds: const ['user-1', 'user-2'],
      status: SavingsGoalStatus.active,
      createdAt: DateTime(2026, 8, 25),
      updatedAt: DateTime(2026, 8, 26),
    );

    final restored = SavingsGoalModel.fromMap(SavingsGoalModel.toMap(goal));

    expect(restored.id, goal.id);
    expect(restored.name, goal.name);
    expect(restored.targetAmount, 5000);
    expect(restored.savedAmount, 1250);
    expect(restored.category, SavingsGoalCategory.travel);
    expect(restored.deadline, DateTime(2027, 1, 10));
    expect(restored.memberIds, ['user-1', 'user-2']);
    expect(restored.status, SavingsGoalStatus.active);
  });

  test('mantém o criador como membro em registros antigos', () {
    final restored = SavingsGoalModel.fromMap({
      'id': 'legacy-goal',
      'name': 'Reserva',
      'targetAmount': 1000,
      'savedAmount': 0,
      'walletId': 'wallet-1',
      'createdByUserId': 'user-1',
      'status': 'active',
      'createdAt': '2026-08-25T00:00:00.000',
      'updatedAt': '2026-08-25T00:00:00.000',
    });

    expect(restored.memberIds, ['user-1']);
    expect(restored.hasMember('user-1'), isTrue);
    expect(restored.category, SavingsGoalCategory.others);
  });
}
