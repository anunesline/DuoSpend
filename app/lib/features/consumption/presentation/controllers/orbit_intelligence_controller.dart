import 'package:flutter/foundation.dart';

import '../../../../shared/knowledge/products/product_repository.dart';
import '../../domain/intelligence/consumption_intelligence_engine.dart';
import '../../domain/interactions/consumption_feedback_service.dart';
import '../../domain/interactions/consumption_interaction.dart';
import '../../domain/interactions/consumption_interaction_policy.dart';
import '../../domain/repositories/consumption_event_repository.dart';
import '../../../financial_intelligence/domain/signals/financial_signals.dart';
import '../../../orbit_intelligence/domain/orbit_intelligence_item.dart';
import '../../../orbit_intelligence/domain/orbit_personality.dart';
import '../../../orbit_intelligence/domain/orbit_personality_renderer.dart';
import '../../../orbit_intelligence/data/orbit_personality_preferences.dart';
import '../../../financial_intelligence/domain/services/financial_intelligence_coordinator.dart';
import '../../../home/data/repositories/wallet_repository.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../../budgets/data/repositories/budget_repository.dart';
import '../../../home/data/repositories/credit_card_repository.dart';
import '../../../financial_intelligence/domain/facts/financial_facts.dart';

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
    this.financialSignals = const [],
    this.orchestrator = const OrbitIntelligenceOrchestrator(),
    this.financialCoordinator = const FinancialIntelligenceCoordinator(),
    WalletRepository? walletRepository,
    TransactionRepository? transactionRepository,
    BudgetRepository? budgetRepository,
    CreditCardRepository? creditCardRepository,
    this.engine = const ConsumptionIntelligenceEngine(),
    this.policy = const ConsumptionInteractionPolicy(),
    OrbitPersonalityPreferences? personalityPreferences,
    this.personalityRenderer = const OrbitPersonalityRenderer(),
  }) : _events = events,
       _walletRepository = walletRepository,
       _transactionRepository = transactionRepository,
       _budgetRepository = budgetRepository,
       _creditCardRepository = creditCardRepository,
       _feedback = ConsumptionFeedbackService(events),
       _personalityPreferences =
           personalityPreferences ?? OrbitPersonalityPreferences.instance;

  final String userId;
  final String scopeId;
  final ProductRepository products;
  final ConsumptionEventRepository _events;
  final ConsumptionIntelligenceEngine engine;
  final ConsumptionInteractionPolicy policy;
  List<FinancialSignal> financialSignals;
  final OrbitIntelligenceOrchestrator orchestrator;
  final FinancialIntelligenceCoordinator financialCoordinator;
  final WalletRepository? _walletRepository;
  final TransactionRepository? _transactionRepository;
  final BudgetRepository? _budgetRepository;
  final CreditCardRepository? _creditCardRepository;
  final ConsumptionFeedbackService _feedback;
  final OrbitPersonalityPreferences _personalityPreferences;
  final OrbitPersonalityRenderer personalityRenderer;

  bool isLoading = false;
  String? errorMessage;
  List<OrbitIntelligenceEntry> entries = const [];
  OrbitPersonality? personality;
  List<OrbitIntelligenceItem> _centralItems = const [];
  final Map<String, OrbitPersonalityRenderResult> _rendered = {};
  final Set<String> _presented = {};

  List<OrbitIntelligenceEntry> get actions =>
      entries
          .where((entry) => entry.interaction != null)
          .where(
            (entry) =>
                entry.interaction!.type !=
                ConsumptionInteractionType.acknowledgePriceOpportunity,
          )
          .toList()
        ..sort(
          (a, b) => b.interaction!.priority.compareTo(a.interaction!.priority),
        );
  List<OrbitIntelligenceEntry> get insights => entries
      .where(
        (entry) =>
            entry.interaction?.type ==
            ConsumptionInteractionType.acknowledgePriceOpportunity,
      )
      .toList();
  List<OrbitIntelligenceEntry> get learned => entries
      .where((entry) => entry.result.metrics.probableRecurrence != null)
      .toList();

  OrbitIntelligenceEntry? get priorityAction =>
      actions.isEmpty ? null : actions.first;

  List<OrbitIntelligenceItem> get centralItems =>
      _centralItems.isNotEmpty || (entries.isEmpty && financialSignals.isEmpty)
      ? _centralItems
      : _sourceItems();
  List<OrbitIntelligenceItem> get centralActions => centralItems
      .where((item) => item.kind == OrbitIntelligenceKind.action)
      .toList(growable: false);
  List<OrbitIntelligenceItem> get centralInsights => centralItems
      .where((item) => item.kind == OrbitIntelligenceKind.insight)
      .toList(growable: false);
  List<OrbitIntelligenceItem> get centralLearned => centralItems
      .where((item) => item.kind == OrbitIntelligenceKind.learned)
      .toList(growable: false);

  Future<void> loadPersonality() async {
    personality = await _personalityPreferences.loadPersonality(userId);
    await _rebuildCentralItems();
    notifyListeners();
  }

  Future<void> setPersonality(OrbitPersonality value) async {
    personality = value;
    await _personalityPreferences.savePersonality(userId, value);
    await _rebuildCentralItems();
    notifyListeners();
  }

  /// This explicit lifecycle hook is called by the page after a loaded list is
  /// logically presented. Rebuilds and getters never write variant history.
  Future<void> markCentralItemsPresented() async {
    final selected = personality;
    if (selected == null) return;
    for (final item in _centralItems) {
      final rendered = _rendered[item.id];
      if (rendered == null || rendered.factType == 'fallback') continue;
      final key = '${item.id}|${selected.name}|${rendered.variantId}';
      if (!_presented.add(key)) continue;
      await _personalityPreferences.recordVariant(
        userId: userId,
        personality: selected,
        factType: rendered.factType,
        family: rendered.family,
        variantId: rendered.variantId,
      );
    }
  }

  Future<void> _rebuildCentralItems() async {
    final sourceItems = _sourceItems();
    final rendered = <String, OrbitPersonalityRenderResult>{};
    final output = <OrbitIntelligenceItem>[];
    for (final item in sourceItems) {
      final selected = personality;
      final initial = personalityRenderer.render(
        item: item,
        personality: selected,
      );
      final recent = selected == null || initial.factType == 'fallback'
          ? const <String>[]
          : await _personalityPreferences.recentVariants(
              userId: userId,
              personality: selected,
              factType: initial.factType,
              family: initial.family,
            );
      final result = personalityRenderer.render(
        item: item,
        personality: selected,
        recentVariantIds: recent,
      );
      rendered[item.id] = result;
      output.add(
        OrbitIntelligenceItem(
          id: item.id,
          dedupeKey: item.dedupeKey,
          domain: item.domain,
          kind: item.kind,
          priority: item.priority,
          scope: item.scope,
          content: result.content,
          source: item.source,
          action: item.action,
        ),
      );
    }
    _rendered
      ..clear()
      ..addAll(rendered);
    _centralItems = List.unmodifiable(output);
  }

  List<OrbitIntelligenceItem> _sourceItems() => orchestrator.build(
    consumption: const ConsumptionCentralAdapter().adapt(entries),
    financial: const FinancialCentralAdapter().adapt(financialSignals),
  );

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final referenceAt = DateTime.now();
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
          referenceAt: referenceAt,
        );
        results.add(
          OrbitIntelligenceEntry(
            productId: product.id,
            productName: product.name,
            result: result,
            interaction: policy.decide(result),
          ),
        );
      }
      entries = List.unmodifiable(results);
      final wallet = await (_walletRepository ?? WalletRepository())
          .getHomeWallet();
      if (wallet != null && _scopeMatchesWallet(wallet)) {
        final transactions =
            await (_transactionRepository ?? TransactionRepository())
                .getTransactionsByWallet(wallet.id, wallet: wallet);
        final budgets = await (_budgetRepository ?? BudgetRepository())
            .getByWallet(wallet: wallet);
        final creditCards =
            await (_creditCardRepository ?? CreditCardRepository()).getCards();
        final invoiceSources = <FinancialCardInvoiceSource>[];
        final cardsForWallet = creditCards.where(
          (card) => card.walletId == wallet.id,
        );
        for (final card in cardsForWallet) {
          final invoices =
              await (_creditCardRepository ?? CreditCardRepository())
                  .getInvoices(cardId: card.id);
          invoiceSources.addAll(
            invoices.map(
              (invoice) => FinancialCardInvoiceSource(
                invoice: invoice,
                walletId: wallet.id,
              ),
            ),
          );
        }
        financialSignals = financialCoordinator.build(
          wallet: wallet,
          transactions: transactions,
          referenceAt: referenceAt,
          budgets: budgets,
          invoices: invoiceSources,
        );
      } else {
        financialSignals = const [];
      }
      await _rebuildCentralItems();
    } catch (_) {
      errorMessage = 'Não foi possível carregar a inteligência do Orbit.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool _scopeMatchesWallet(WalletModel wallet) {
    final members = wallet.memberIds.map((id) => id.trim()).toSet();
    if (wallet.isShared) {
      final expected = scopeId.startsWith('household:')
          ? scopeId.substring('household:'.length).split('|').toSet()
          : <String>{};
      return expected.isNotEmpty &&
          expected.length == members.length &&
          expected.containsAll(members);
    }
    return scopeId == 'user:${wallet.ownerId.trim()}' ||
        scopeId == 'user:$userId';
  }

  Future<void> respond(
    ConsumptionInteraction interaction,
    ConsumptionInteractionResponse response, {
    double? remainingQuantity,
    String? remainingUnit,
  }) async {
    await _feedback.record(
      ConsumptionFeedbackCommand(
        interaction: interaction,
        response: response,
        occurredAt: DateTime.now(),
        recordedAt: DateTime.now(),
        recordedByUserId: userId,
        remainingQuantity: remainingQuantity,
        remainingUnit: remainingUnit,
      ),
    );
    await load();
  }
}
