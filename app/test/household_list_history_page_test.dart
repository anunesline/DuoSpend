import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/household_routines/domain/models/household_list.dart';
import 'package:app/features/household_routines/domain/models/household_list_item.dart';
import 'package:app/features/household_routines/presentation/pages/household_list_history_page.dart';

void main() {
  final list = HouseholdList(
    id: 'market',
    scopeId: 'user:aline',
    name: 'Mercado',
    type: HouseholdListType.shopping,
    status: HouseholdListStatus.active,
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 1),
  );

  testWidgets('lista sem eventos mostra estado vazio Orbit', (tester) async {
    await tester.pumpWidget(
      _app(list: list, events: const []),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma compra registrada'), findsOneWidget);
    expect(
      find.text('As compras marcadas nesta lista aparecerão aqui.'),
      findsOneWidget,
    );
  });

  testWidgets('origens manual, antiga e financeira são apresentadas',
      (tester) async {
    final events = [
      _event(id: 'financial', source: 'financialTransaction'),
      _event(id: 'manual', source: 'manual'),
      _event(id: 'legacy'),
    ];
    await tester.pumpWidget(
      _app(list: list, events: events, memberName: 'Aline'),
    );
    await tester.pumpAndSettle();

    expect(find.text('via transação'), findsOneWidget);
    expect(find.text('marcado na lista'), findsNWidgets(2));
    expect(find.text('Por Aline'), findsNWidgets(3));
    expect(find.textContaining('user:aline'), findsNothing);
    expect(find.textContaining('transaction:'), findsNothing);
  });

  testWidgets('UID sem perfil resolvido não é exibido', (tester) async {
    await tester.pumpWidget(
      _app(list: list, events: [_event(id: 'manual')]),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('user:aline'), findsNothing);
    expect(find.textContaining('Por '), findsNothing);
  });
}

Widget _app({
  required HouseholdList list,
  required List<HouseholdListItemPurchaseEvent> events,
  String? memberName,
}) =>
    MaterialApp(
      home: HouseholdListHistoryPage(
        list: list,
        loadEvents: () async => events,
        resolveMemberName: (_) => memberName,
      ),
    );

HouseholdListItemPurchaseEvent _event({
  required String id,
  String? source,
}) =>
    HouseholdListItemPurchaseEvent(
      id: id,
      itemId: 'milk',
      listId: 'market',
      scopeId: 'user:aline',
      displayName: 'Leite',
      identityKey: 'leite',
      purchasedAt: DateTime.utc(2026, 9, 5, 14, 30),
      purchasedBy: 'user:aline',
      source: source,
      sourceReferenceId:
          source == 'financialTransaction' ? 'transaction:item' : null,
    );
