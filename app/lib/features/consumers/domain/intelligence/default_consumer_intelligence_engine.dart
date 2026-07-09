import 'consumer_habit.dart';
import 'consumer_habit_analyzer.dart';
import 'consumer_habit_updater.dart';
import 'consumer_intelligence_engine.dart';
import 'consumer_knowledge_payload.dart';
import 'consumer_memory.dart';

class DefaultConsumerIntelligenceEngine
    implements ConsumerIntelligenceEngine {
  final ConsumerHabitAnalyzer analyzer;
  final ConsumerHabitUpdater updater;

  const DefaultConsumerIntelligenceEngine({
    required this.analyzer,
    required this.updater,
  });

  @override
  Future<ConsumerMemory> learn({
    required ConsumerKnowledgePayload payload,
    required ConsumerMemory memory,
  }) async {
    var currentMemory = memory;

    for (final item in payload.transaction.items) {
      final existingHabit = analyzer.findHabit(
        payload,
        currentMemory.habits,
      );

      if (existingHabit == null) {
        final newHabit = ConsumerHabit(
          id: '${payload.consumerId}_${item.description}',
          consumerId: payload.consumerId,
          walletId: payload.walletId,
          productName: item.description,
          normalizedProductName: item.description,
          category: payload.transaction.category,
          subcategory: payload.transaction.subcategory,
          brand: null,
          variant: null,
          packageDescription: null,
          occurrences: 1,
          firstSeenAt: payload.transaction.date,
          lastSeenAt: payload.transaction.date,
          confidence: 0.2,
          averageIntervalInDays: null,
        );

        currentMemory = updater.addHabit(
          memory: currentMemory,
          habit: newHabit,
        );

        continue;
      }

      final updatedHabit = existingHabit.copyWith(
        occurrences: existingHabit.occurrences + 1,
        lastSeenAt: payload.transaction.date,
        confidence: (existingHabit.confidence + 0.1).clamp(0.0, 1.0),
      );

      currentMemory = updater.replaceHabit(
        memory: currentMemory,
        updatedHabit: updatedHabit,
      );
    }

    return currentMemory;
  }
}