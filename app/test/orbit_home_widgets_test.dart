import 'package:app/features/home/domain/models/orbit_home_overview.dart';
import 'package:app/features/home/presentation/widgets/orbit_home_chrome.dart';
import 'package:app/features/home/presentation/widgets/orbit_home_content.dart';
import 'package:app/features/home/presentation/widgets/orbit_home_primitives.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'fixtures/orbit_home_fixture.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  Widget harness({
    required bool shared,
    double scale = 1,
    bool populated = true,
    Map<OrbitHomeSection, String> errors = const {},
    List<String>? actions,
  }) {
    var visible = true;
    void action(String value) => actions?.add(value);
    return MaterialApp(
      theme: ThemeData.dark(),
      home: StatefulBuilder(
        builder: (context, setState) {
          final data = homeFixture(
            shared: shared,
            populated: populated,
            errors: errors,
          );
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              backgroundColor: OrbitHomeTokens.background,
              bottomNavigationBar: OrbitHomeNavigation(
                onHome: () => action('home'),
                onFinance: () => action('finance'),
                onRoutines: () => action('routines'),
                onAi: () => action('ai'),
                onCreate: () => action('create'),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    OrbitHomeHeader(
                      name: 'Pessoa Um',
                      partnerName: shared ? 'Pessoa Dois' : null,
                      valuesVisible: visible,
                      hasPendingItems: false,
                      onPrivacy: () => setState(() => visible = !visible),
                      onNotifications: () => action('pending'),
                      onWallets: () => action('wallets'),
                    ),
                    OrbitHomeScopeSelector(
                      shared: shared,
                      onSolo: () => action('solo'),
                      onShared: () => action('shared'),
                    ),
                    const SizedBox(height: 16),
                    OrbitHomeContent(
                      data: data,
                      valuesVisible: visible,
                      onWallet: () => action('wallet'),
                      onBudget: () => action('budget'),
                      onCalendar: () => action('calendar'),
                      onGoals: () => action('goals'),
                      onInsights: () => action('insights'),
                      onRoutines: () => action('routines'),
                      onSettlements: () => action('settlements'),
                      onContribution: () => action('contribution'),
                      onHistory: () => action('history'),
                      onRetry: () => action('retry'),
                      onCompleteTask: (task) => action(task.id),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  for (final shared in [false, true]) {
    for (final width in [320.0, 360.0, 412.0, 600.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets(
          '${shared ? 'Nós' : 'Solo'} at width $width and text $scale has no overflow',
          (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(harness(shared: shared, scale: scale));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.drag(
              find.byType(SingleChildScrollView).first,
              const Offset(0, -1600),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.text('Guardar roupa'), findsOneWidget);
          },
        );
      }

    }

    testWidgets(
      '${shared ? 'Nós' : 'Solo'} privacy masks amounts, progress and financial insight text',
      (tester) async {
        await tester.pumpWidget(harness(shared: shared));
        await tester.pumpAndSettle();
        expect(find.text(orbitMoney(2486.32)), findsOneWidget);
        await tester.tap(find.byTooltip('Ocultar valores'));
        await tester.pumpAndSettle();
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .join('\n');
        for (final value in [
          '2.486,32',
          '2.349,20',
          '4.896,40',
          '184,50',
          '6.800,00',
          '68%',
          '52%',
          '48%',
        ]) {
          expect(
            texts,
            isNot(contains(value)),
            reason: '$value leaked through privacy',
          );
        }
        expect(
          texts,
          contains('Mostre os valores para consultar seu insight financeiro.'),
        );
        expect(texts, contains('Lavar roupa'));
        await tester.tap(find.byTooltip('Mostrar valores'));
        await tester.pumpAndSettle();
        expect(find.text(orbitMoney(2486.32)), findsOneWidget);
      },
    );

    testWidgets(
      '${shared ? 'Nós' : 'Solo'} has useful empty and unavailable states',
      (tester) async {
        await tester.pumpWidget(harness(shared: shared, populated: false));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Viagem dos sonhos'), findsNothing);
        expect(find.textContaining('Nenhuma rotina para hoje'), findsOneWidget);
        await tester.pumpWidget(
          harness(
            shared: shared,
            populated: false,
            errors: {
              for (final section in OrbitHomeSection.values) section: 'Failed',
            },
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Resumo indisponível'), findsWidgets);
      },
    );
  }

  testWidgets(
    'navigation, scopes and pending panel emit the intended actions',
    (tester) async {
      final actions = <String>[];
      await tester.pumpWidget(harness(shared: false, actions: actions));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nós'));
      await tester.tap(find.byTooltip('Ver pendências'));
      await tester.tap(find.text('Finanças'));
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.tap(find.text('Rotinas'));
      await tester.tap(find.text('IA'));
      expect(actions, [
        'shared',
        'pending',
        'finance',
        'create',
        'routines',
        'ai',
      ]);
    },
  );

  testWidgets(
    'routine completion and section links stay actionable after scrolling',
    (tester) async {
      final actions = <String>[];
      await tester.pumpWidget(harness(shared: true, actions: actions));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Acertar agora'));
      await tester.tap(find.text('Acertar agora'));
      await tester.ensureVisible(find.text('Contribuição'));
      await tester.tap(find.text('Contribuição'));
      await tester.ensureVisible(find.text('Ver calendário'));
      await tester.tap(find.text('Ver calendário'));
      await tester.ensureVisible(find.text('Lavar roupa'));
      await tester.tap(find.byTooltip('Concluir tarefa').first);
      expect(actions, [
        'settlements',
        'contribution',
        'calendar',
        'Lavar roupa',
      ]);
      expect(find.byTooltip('Concluída'), findsOneWidget);
    },
  );
}
