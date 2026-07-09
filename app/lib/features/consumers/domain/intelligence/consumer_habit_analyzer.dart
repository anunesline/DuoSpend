import 'consumer_habit.dart';

class ConsumerHabitAnalyzer {
  const ConsumerHabitAnalyzer();

  ConsumerHabit? findHabit({
    required String productName,
    required List<ConsumerHabit> habits,
  }) {
    final normalizedProductName = productName.trim().toLowerCase();

    for (final habit in habits) {
      final habitProductName = habit.productName.trim().toLowerCase();
      final habitNormalizedName =
          habit.normalizedProductName?.trim().toLowerCase();

      if (habitProductName == normalizedProductName ||
          habitNormalizedName == normalizedProductName) {
        return habit;
      }
    }

    return null;
  }
}