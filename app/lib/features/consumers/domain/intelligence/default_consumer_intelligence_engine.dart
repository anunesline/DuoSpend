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

    for (final item in payload.purchase.items) {
      final existingHabit = analyzer.findHabit(
        productName: item.name,
        habits: currentMemory.habits,
      );

      if (existingHabit == null) {
        final newHabit = ConsumerHabit(
          id: '${payload.consumerId}_${item.name}',
          consumerId: payload.consumerId,
          walletId: payload.walletId,
          productName: item.name,
          normalizedProductName: item.name.trim().toLowerCase(),
          category: item.financialCategory,
          subcategory: item.financialSubcategory,
          brand: item.brand,
          variant: null,
          packageDescription: '${item.quantity} ${item.unit}',
          occurrences: 1,
          firstSeenAt: payload.purchase.purchaseDate,
          lastSeenAt: payload.purchase.purchaseDate,
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
        lastSeenAt: payload.purchase.purchaseDate,
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