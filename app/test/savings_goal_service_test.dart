import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/goals/domain/models/savings_goal.dart';
import 'package:app/features/goals/domain/services/savings_goal_service.dart';

void main() {
  const service = SavingsGoalService();
  final now = DateTime(2026, 8, 25, 10);

  SavingsGoal createGoal({
    double targetAmount = 1000,
    double initialAmount = 0,
    SavingsGoalCategory category = SavingsGoalCategory.others,
    DateTime? deadline,
  }) {
    return service.create(
      id: 'goal-1',
      name: 'Reserva de emergência',
      targetAmount: targetAmount,
      walletId: 'wallet-1',
      createdByUserId: 'user-1',
      memberIds: const ['user-1', 'user-2', 'user-2'],
      initialAmount: initialAmount,
      category: category,
      deadline: deadline,
      now: now,
    );
  }

  group('SavingsGoalService', () {
    test('cria meta ativa com progresso e prazo normalizados', () {
      final goal = createGoal(
        initialAmount: 250,
        category: SavingsGoalCategory.emergency,
        deadline: DateTime(2026, 12, 20, 18),
      );

      expect(goal.status, SavingsGoalStatus.active);
      expect(goal.savedAmount, 250);
      expect(goal.remainingAmount, 750);
      expect(goal.progressPercentage, 25);
      expect(goal.category, SavingsGoalCategory.emergency);
      expect(goal.deadline, DateTime(2026, 12, 20));
      expect(goal.memberIds, ['user-1', 'user-2']);
      expect(goal.hasMember('user-2'), isTrue);
    });

    test('conclui meta quando o aporte alcança o valor-alvo', () {
      final goal = createGoal(initialAmount: 750);

      final completed = service.contribute(
        goal: goal,
        amount: 250,
        now: now.add(const Duration(days: 1)),
      );

      expect(completed.savedAmount, 1000);
      expect(completed.remainingAmount, 0);
      expect(completed.progress, 1);
      expect(completed.isCompleted, isTrue);
      expect(completed.status, SavingsGoalStatus.completed);
    });

    test('impede aporte acima do valor restante', () {
      final goal = createGoal(initialAmount: 900);

      expect(
        () => service.contribute(goal: goal, amount: 101),
        throwsStateError,
      );
    });

    test('retirada devolve meta concluída ao estado ativo', () {
      final goal = createGoal(initialAmount: 1000);

      final updated = service.withdraw(
        goal: goal,
        amount: 200,
        now: now.add(const Duration(days: 1)),
      );

      expect(updated.savedAmount, 800);
      expect(updated.status, SavingsGoalStatus.active);
      expect(updated.remainingAmount, 200);
    });

    test('impede retirada acima do valor reservado', () {
      final goal = createGoal(initialAmount: 100);

      expect(() => service.withdraw(goal: goal, amount: 101), throwsStateError);
    });

    test('valida nome, valores, carteira, usuário e prazo', () {
      expect(
        () => service.create(
          id: 'goal',
          name: ' ',
          targetAmount: 100,
          walletId: 'wallet',
          createdByUserId: 'user',
          now: now,
        ),
        throwsArgumentError,
      );

      expect(
        () => service.create(
          id: 'goal',
          name: 'Meta',
          targetAmount: 0,
          walletId: 'wallet',
          createdByUserId: 'user',
          now: now,
        ),
        throwsArgumentError,
      );

      expect(
        () => service.create(
          id: 'goal',
          name: 'Meta',
          targetAmount: 100,
          initialAmount: 101,
          walletId: 'wallet',
          createdByUserId: 'user',
          now: now,
        ),
        throwsArgumentError,
      );

      expect(
        () => service.create(
          id: 'goal',
          name: 'Meta',
          targetAmount: 100,
          walletId: 'wallet',
          createdByUserId: 'user',
          deadline: DateTime(2026, 8, 24),
          now: now,
        ),
        throwsArgumentError,
      );
    });

    test('edição mantém valor reservado e recalcula o status', () {
      final completed = createGoal(targetAmount: 500, initialAmount: 500);

      final updated = service.update(
        goal: completed,
        name: 'Reserva ampliada',
        targetAmount: 800,
        category: SavingsGoalCategory.investment,
        deadline: DateTime(2026, 12, 20, 18),
        now: now.add(const Duration(days: 1)),
      );

      expect(updated.name, 'Reserva ampliada');
      expect(updated.targetAmount, 800);
      expect(updated.savedAmount, 500);
      expect(updated.category, SavingsGoalCategory.investment);
      expect(updated.status, SavingsGoalStatus.active);
      expect(updated.deadline, DateTime(2026, 12, 20));
    });

    test('edição não reduz alvo abaixo do valor reservado', () {
      final goal = createGoal(targetAmount: 1000, initialAmount: 600);

      expect(
        () => service.update(
          goal: goal,
          name: goal.name,
          targetAmount: 599.99,
          now: now,
        ),
        throwsStateError,
      );
    });

    test('edição preserva prazo legado no passado', () {
      final goal = createGoal(deadline: DateTime(2026, 8, 25))
          .copyWith(deadline: DateTime(2026, 8, 20));

      final updated = service.update(
        goal: goal,
        name: 'Meta antiga',
        targetAmount: goal.targetAmount,
        deadline: DateTime(2026, 8, 20),
        now: now,
      );

      expect(updated.deadline, DateTime(2026, 8, 20));
    });

    test('arquivamento bloqueia novos movimentos', () {
      final archived = service.archive(goal: createGoal());

      expect(archived.isArchived, isTrue);
      expect(
        () => service.contribute(goal: archived, amount: 10),
        throwsStateError,
      );
      expect(
        () => service.withdraw(goal: archived, amount: 10),
        throwsStateError,
      );
    });
  });
}
