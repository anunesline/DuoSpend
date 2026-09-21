import 'package:flutter/foundation.dart';

import '../../../../shared/knowledge/products/product_repository.dart';
import '../../domain/intelligence/consumption_intelligence_engine.dart';
import '../../domain/interactions/consumption_feedback_service.dart';
import '../../domain/interactions/consumption_interaction.dart';
import '../../domain/interactions/consumption_interaction_policy.dart';
import '../../domain/repositories/consumption_event_repository.dart';

class OrbitIntelligenceEntry {
  const OrbitIntelligenceEntry({
    required this.productId,
    required this.productName,
    required this.result,
    this.interaction,
  });
  final String productId;
  final String productName;
  final ConsumptionIntelligenceResult result;
  final ConsumptionInteraction? interaction;
}

class OrbitIntelligenceController extends ChangeNotifier {
  OrbitIntelligenceController({
    required this.userId,
    required this.scopeId,
    required this.products,
    required ConsumptionEventRepository events,
    this.engine = const ConsumptionIntelligenceEngine(),
    this.policy = const ConsumptionInteractionPolicy(),
  }) : _events = events,
       _feedback = ConsumptionFeedbackService(events);

  final String userId;
  final String scopeId;
  final ProductRepository products;
  final ConsumptionEventRepository _events;
  final ConsumptionIntelligenceEngine engine;
  final ConsumptionInteractionPolicy policy;
  final ConsumptionFeedbackService _feedback;

  bool isLoading = false;
  String? errorMessage;
  List<OrbitIntelligenceEntry> entries = const [];

  List<OrbitIntelligenceEntry> get actions => entries
      .where((entry) => entry.interaction != null)
      .where(
        (entry) =>
            entry.interaction!.type !=
            ConsumptionInteractionType.acknowledgePriceOpportunity,
      )
      .toList()
    ..sort((a, b) => b.interaction!.priority.compareTo(a.interaction!.priority));
  List<OrbitIntelligenceEntry> get insights => entries.where((entry) =>
      entry.interaction?.type == ConsumptionInteractionType.acknowledgePriceOpportunity).toList();
  List<OrbitIntelligenceEntry> get learned => entries.where((entry) =>
      entry.result.metrics.probableRecurrence != null).toList();

  OrbitIntelligenceEntry? get priorityAction =>
      actions.isEmpty ? null : actions.first;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await products.initialize(userId: userId);
      final results = <OrbitIntelligenceEntry>[];
      for (final product in products.search('')) {
        final metrics = await products.getPurchaseMetrics(
          userId: userId,
          productId: product.id,
        );
        final events = await _events.getByScopeAndProduct(
          scopeId: scopeId,
          productId: product.id,
        );
        final result = engine.analyze(
          productId: product.id,
          scopeId: scopeId,
          metrics: metrics,
          events: events,
          referenceAt: DateTime.now(),
        );
        results.add(OrbitIntelligenceEntry(
          productId: product.id,
          productName: product.name,
          result: result,
          interaction: policy.decide(result),
        ));
      }
      entries = List.unmodifiable(results);
    } catch (_) {
      errorMessage = 'Não foi possível carregar a inteligência do Orbit.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> respond(
    ConsumptionInteraction interaction,
    ConsumptionInteractionResponse response, {
    double? remainingQuantity,
    String? remainingUnit,
  }) async {
    await _feedback.record(ConsumptionFeedbackCommand(
      interaction: interaction,
      response: response,
      occurredAt: DateTime.now(),
      recordedAt: DateTime.now(),
      recordedByUserId: userId,
      remainingQuantity: remainingQuantity,
      remainingUnit: remainingUnit,
    ));
    await load();
  }
}
