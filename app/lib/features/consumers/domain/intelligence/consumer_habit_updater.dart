import 'consumer_habit.dart';
import 'consumer_memory.dart';

class ConsumerHabitUpdater {
  const ConsumerHabitUpdater();

  ConsumerMemory addHabit({
    required ConsumerMemory memory,
    required ConsumerHabit habit,
  }) {
    return memory.copyWith(
      habits: [
        ...memory.habits,
        habit,
      ],
      updatedAt: DateTime.now(),
    );
  }

  ConsumerMemory replaceHabit({
    required ConsumerMemory memory,
    required ConsumerHabit updatedHabit,
  }) {
    final habits = memory.habits
        .map(
          (habit) =>
              habit.id == updatedHabit.id
                  ? updatedHabit
                  : habit,
        )
        .toList();

    return memory.copyWith(
      habits: habits,
      updatedAt: DateTime.now(),
    );
  }
}
