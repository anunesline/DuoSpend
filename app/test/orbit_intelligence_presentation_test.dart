import 'package:app/features/consumption/domain/intelligence/consumption_intelligence_engine.dart';
import 'package:app/features/consumption/domain/interactions/consumption_interaction.dart';
import 'package:app/features/consumption/domain/models/consumption_event.dart';
import 'package:app/features/consumption/domain/repositories/consumption_event_repository.dart';
import 'package:app/features/consumption/presentation/controllers/orbit_intelligence_controller.dart';
import 'package:app/features/consumption/presentation/pages/orbit_intelligence_page.dart';
import 'package:app/features/home/presentation/pages/home_page.dart';
import 'package:app/features/home/presentation/widgets/orbit_home_primitives.dart';
import 'package:app/features/household_routines/domain/models/household_list_item.dart';
import 'package:app/features/household_routines/presentation/pages/household_list_detail_page.dart';
import 'package:app/shared/knowledge/products/product_purchase_metrics.dart';
import 'package:app/shared/knowledge/products/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  OrbitIntelligenceController controller() => OrbitIntelligenceController(
    userId: 'aline',
    scopeId: 'user:aline',
    products: ProductRepository(),
    events: _Events(),
  );

  OrbitIntelligenceEntry entry(
    ConsumptionInteractionType type, {
    int priority = 20,
    bool learned = false,
  }) => OrbitIntelligenceEntry(
    productId: 'detergente',
    productName: 'Detergente',
    result: ConsumptionIntelligenceResult(
      productId: 'detergente',
      scopeId: 'user:aline',
      metrics: learned ? _learnedMetrics : _metrics,
      state: const ConsumptionDerivedState(
        state: ConsumptionState.withinExpectedRhythm,
        evidenceQuality: ConsumptionEvidenceQuality.strong,
      ),
      signals: const [],
      activeEvents: const [],
      policyVersion: 1,
    ),
    interaction: ConsumptionInteraction(
      id: '${type.name}:$priority',
      type: type,
      productId: 'detergente',
      scopeId: 'user:aline',
      priority: priority,
      state: ConsumptionState.withinExpectedRhythm,
      evidenceQuality: ConsumptionEvidenceQuality.strong,
      allowedResponses: const [],
      triggerFactIds: const [],
      policyVersion: 1,
    ),
  );

  Widget page(OrbitIntelligenceController state, {double scale = 1}) =>
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData().copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: OrbitIntelligencePage(
            userId: 'aline',
            scopeId: 'user:aline',
            products: ProductRepository(),
            controller: state,
          ),
        ),
      );

  test('oportunidade é insight, nunca ação pendente/Home', () {
    final state = controller()
      ..entries = [
        entry(
          ConsumptionInteractionType.acknowledgePriceOpportunity,
          priority: 99,
        ),
      ];
    expect(state.actions, isEmpty);
    expect(state.priorityAction, isNull);
    expect(state.insights, hasLength(1));
  });

  test('Home seleciona somente a ação humana de maior prioridade', () {
    final state = controller()
      ..entries = [
        entry(ConsumptionInteractionType.confirmStock, priority: 90),
        entry(ConsumptionInteractionType.offerAddToShoppingList, priority: 100),
        entry(ConsumptionInteractionType.confirmExceptionalPurchase),
      ];
    expect(
      state.priorityAction!.interaction!.type,
      ConsumptionInteractionType.offerAddToShoppingList,
    );
    expect(state.actions, hasLength(3));
  });

  testWidgets('destaque real da Home é único, concreto e acionável', (
    tester,
  ) async {
    final tapped = <bool>[];
    final state = controller()
      ..entries = [
        entry(ConsumptionInteractionType.confirmExceptionalPurchase),
        entry(ConsumptionInteractionType.confirmStock, priority: 90),
      ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrbitAiHomeHighlight(
            controller: state,
            onTap: () => tapped.add(true),
          ),
        ),
      ),
    );
    expect(find.textContaining('Ainda tem Detergente?'), findsOneWidget);
    expect(find.byType(OrbitHomeMessage), findsOneWidget);
    await tester.tap(find.byType(OrbitHomeMessage));
    expect(tapped, [true]);
  });

  for (final type in [
    ConsumptionInteractionType.confirmStock,
    ConsumptionInteractionType.offerAddToShoppingList,
    ConsumptionInteractionType.confirmExceptionalPurchase,
  ]) {
    testWidgets('destaque real da Home renderiza $type', (tester) async {
      final state = controller()..entries = [entry(type)];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrbitAiHomeHighlight(controller: state, onTap: () {}),
          ),
        ),
      );
      final expected = switch (type) {
        ConsumptionInteractionType.confirmStock => 'Ainda tem Detergente?',
        ConsumptionInteractionType.offerAddToShoppingList =>
          'Quer colocar Detergente na lista de compras?',
        ConsumptionInteractionType.confirmExceptionalPurchase =>
          'Essa compra de Detergente foi fora do seu padrão?',
        ConsumptionInteractionType.acknowledgePriceOpportunity => '',
      };
      expect(find.textContaining(expected), findsOneWidget);
    });
  }

  testWidgets('Home não destaca oportunidade de preço nem estado sem ação', (
    tester,
  ) async {
    final state = controller()
      ..entries = [
        entry(ConsumptionInteractionType.acknowledgePriceOpportunity),
      ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrbitAiHomeHighlight(controller: state, onTap: () {}),
        ),
      ),
    );
    expect(find.byType(OrbitHomeMessage), findsNothing);
  });

  testWidgets(
    'tile real de Rotinas mostra metadados factuais sem inventar autor',
    (tester) async {
      HouseholdListItem item({
        String? createdBy,
        DateTime? completedAt,
        String? completedBy,
      }) => HouseholdListItem(
        id: 'item',
        listId: 'list',
        scopeId: 'user:aline',
        displayName: 'Leite',
        identityKey: 'leite',
        status: completedAt == null
            ? HouseholdListItemStatus.pending
            : HouseholdListItemStatus.purchased,
        createdAt: DateTime.utc(2026, 9, 2),
        createdBy: createdBy,
        updatedAt: completedAt ?? DateTime.utc(2026, 9, 2),
        completedAt: completedAt,
        completedBy: completedBy,
      );
      Widget tile(HouseholdListItem value) => MaterialApp(
        home: Scaffold(
          body: HouseholdListItemTile(
            item: value,
            onChanged: (_) {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpWidget(tile(item(createdBy: 'Aline')));
      expect(
        find.textContaining('Adicionado por Aline · 02/09'),
        findsOneWidget,
      );
      await tester.pumpWidget(tile(item()));
      expect(find.textContaining('Incluído em 02/09'), findsOneWidget);
      expect(find.textContaining('por '), findsNothing);
      await tester.pumpWidget(
        tile(
          item(
            createdBy: 'Aline',
            completedAt: DateTime.utc(2026, 9, 5),
            completedBy: 'Mateus',
          ),
        ),
      );
      expect(
        find.textContaining('comprado em 05/09 por Mateus'),
        findsOneWidget,
      );
      await tester.pumpWidget(
        tile(item(completedAt: DateTime.utc(2026, 9, 5))),
      );
      expect(find.textContaining('comprado em 05/09'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Central separa ação, insight e aprendizado', (tester) async {
    final state = controller()
      ..entries = [
        entry(ConsumptionInteractionType.confirmStock, priority: 90),
        entry(ConsumptionInteractionType.acknowledgePriceOpportunity),
        entry(
          ConsumptionInteractionType.confirmExceptionalPurchase,
          learned: true,
        ),
      ];
    await tester.pumpWidget(page(state));
    expect(find.text('O que precisa de mim?'), findsOneWidget);
    expect(find.text('O que o Orbit percebeu?'), findsOneWidget);
    expect(find.text('O que o Orbit aprendeu?'), findsOneWidget);
    expect(find.text('Ainda tem Detergente?'), findsOneWidget);
    expect(
      find.text('Você pagou menos que o habitual em Detergente'),
      findsOneWidget,
    );
  });

  for (final type in [
    ConsumptionInteractionType.confirmStock,
    ConsumptionInteractionType.offerAddToShoppingList,
    ConsumptionInteractionType.confirmExceptionalPurchase,
  ]) {
    testWidgets('Central renderiza ação concreta $type', (tester) async {
      final state = controller()..entries = [entry(type)];
      await tester.pumpWidget(page(state));
      final expected = switch (type) {
        ConsumptionInteractionType.confirmStock => 'Ainda tem Detergente?',
        ConsumptionInteractionType.offerAddToShoppingList =>
          'Quer colocar Detergente na lista de compras?',
        ConsumptionInteractionType.confirmExceptionalPurchase =>
          'Essa compra foi fora do seu padrão?',
        ConsumptionInteractionType.acknowledgePriceOpportunity => '',
      };
      expect(find.text(expected), findsOneWidget);
    });
  }

  testWidgets('Central tem estados vazio, loading e erro com retry', (
    tester,
  ) async {
    final state = controller();
    await tester.pumpWidget(page(state));
    expect(find.textContaining('ainda está aprendendo'), findsOneWidget);
    state.isLoading = true;
    state.notifyListeners();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    state
      ..isLoading = false
      ..errorMessage = 'indisponível';
    state.notifyListeners();
    await tester.pump();
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('Central real mostra estado vazio para produtos sem sinais', (
    tester,
  ) async {
    final source = entry(ConsumptionInteractionType.confirmStock);
    final state = controller()
      ..entries = [
        OrbitIntelligenceEntry(
          productId: source.productId,
          productName: source.productName,
          result: source.result,
        ),
      ];
    await tester.pumpWidget(page(state));
    expect(find.textContaining('ainda está aprendendo'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });

  for (final width in [320.0, 360.0, 600.0]) {
    testWidgets('Central não transborda em $width com texto ampliado', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = controller()
        ..entries = [
          entry(ConsumptionInteractionType.offerAddToShoppingList),
          entry(
            ConsumptionInteractionType.confirmExceptionalPurchase,
            learned: true,
          ),
          entry(ConsumptionInteractionType.acknowledgePriceOpportunity),
        ];
      await tester.pumpWidget(page(state, scale: 1.6));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

final _metrics = _makeMetrics();
final _learnedMetrics = _makeMetrics(
  price: 8,
  interval: const Duration(days: 30),
  learned: true,
);
ProductPurchaseMetrics _makeMetrics({
  double? price,
  Duration? interval,
  bool learned = false,
}) => ProductPurchaseMetrics(
  productId: 'detergente',
  history: const [],
  averageUnitPrice: price,
  minimumUnitPrice: price,
  maximumUnitPrice: price,
  absolutePriceVariation: null,
  percentagePriceVariation: null,
  totalQuantity: 0,
  totalSpent: 0,
  purchaseFrequencyPer30Days: null,
  averagePurchaseInterval: interval,
  spendingByMerchant: const [],
  spendingByCategory: const [],
  probableRecurrence: learned
      ? ProductProbableRecurrence(
          averageInterval: interval!,
          nextExpectedPurchaseAt: DateTime.utc(2026, 10, 1),
          observationCount: 3,
        )
      : null,
);

class _Events implements ConsumptionEventRepository {
  @override
  Future<ConsumptionEvent?> getById(String id) async => null;
  @override
  Future<List<ConsumptionEvent>> getByProduct({
    required String productId,
    DateTime? from,
    DateTime? until,
    bool includeInactive = false,
  }) async => [];
  @override
  Future<List<ConsumptionEvent>> getByScope({
    required String scopeId,
    DateTime? from,
    DateTime? until,
    bool includeInactive = false,
  }) async => [];
  @override
  Future<List<ConsumptionEvent>> getByScopeAndProduct({
    required String scopeId,
    required String productId,
    DateTime? from,
    DateTime? until,
    bool includeInactive = false,
  }) async => [];
  @override
  Future<void> invalidate({
    required String eventId,
    required DateTime invalidatedAt,
    String? invalidatedByUserId,
    String? reason,
  }) async {}
  @override
  Future<void> record(ConsumptionEvent event) async {}
}
