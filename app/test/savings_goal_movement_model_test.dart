import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/goals/data/models/savings_goal_movement_model.dart';
import 'package:app/features/goals/domain/models/savings_goal_movement.dart';

void main() {
  test('mapeia movimentação persistida e preserva legado sem id', () {
    final movement = SavingsGoalMovementModel.fromMap(
      {
        'goalId': 'goal-1',
        'walletId': 'wallet-1',
        'type': 'withdrawal',
        'amount': '125.50',
        'createdByUserId': 'user-1',
        'occurredAt': '2026-08-25T18:30:00.000',
      },
      documentId: 'movement-1',
    );

    expect(movement.id, 'movement-1');
    expect(movement.goalId, 'goal-1');
    expect(movement.walletId, 'wallet-1');
    expect(movement.type, SavingsGoalMovementType.withdrawal);
    expect(movement.amount, 125.50);
    expect(movement.createdByUserId, 'user-1');
    expect(movement.occurredAt, DateTime(2026, 8, 25, 18, 30));
  });
}
