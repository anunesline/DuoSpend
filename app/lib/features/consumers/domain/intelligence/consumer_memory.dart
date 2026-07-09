import 'consumer_habit.dart';

class ConsumerMemory {
  final String consumerId;
  final String walletId;

  final List<ConsumerHabit> habits;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ConsumerMemory({
    required this.consumerId,
    required this.walletId,
    required this.habits,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConsumerMemory.empty({
    required String consumerId,
    required String walletId,
  }) {
    final now = DateTime.now();

    return ConsumerMemory(
      consumerId: consumerId,
      walletId: walletId,
      habits: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  ConsumerMemory copyWith({
    String? consumerId,
    String? walletId,
    List<ConsumerHabit>? habits,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConsumerMemory(
      consumerId: consumerId ?? this.consumerId,
      walletId: walletId ?? this.walletId,
      habits: habits ?? this.habits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  ConsumerHabit? findHabitByProduct(String productName) {
    for (final habit in habits) {
      if (habit.productName.toLowerCase() == productName.toLowerCase()) {
        return habit;
      }
    }

    return null;
  }
}