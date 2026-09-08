import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/household_routines/data/repositories/firestore_household_list_repository.dart';
import 'package:app/features/household_routines/domain/models/household_list.dart';
import 'package:app/features/household_routines/domain/models/household_list_item.dart';

void main() {
  test('cria e lê listas pessoal e compartilhada', () async {
    final repository = FirestoreHouseholdListRepository(
      firestore: FakeFirebaseFirestore(),
    );
    final now = DateTime.utc(2026, 9, 5);
    await repository.saveList(_list(
      id: 'personal',
      scopeId: 'user:aline',
      name: 'Casa',
      type: HouseholdListType.general,
      now: now,
    ));
    await repository.saveList(_list(
      id: 'shared',
      scopeId: 'household:aline|matheus',
      name: 'Mercado',
      type: HouseholdListType.shopping,
      now: now,
    ));

    expect((await repository.getListsByScope('user:aline')).single.name, 'Casa');
    expect(
      (await repository.getListsByScope('household:aline|matheus')).single.isShopping,
      isTrue,
    );
  });

  test('compra preserva evento histórico entre compras sucessivas', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreHouseholdListRepository(firestore: firestore);
    final list = _list(
      id: 'market',
      scopeId: 'user:aline',
      name: 'Mercado',
      type: HouseholdListType.shopping,
      now: DateTime.utc(2026, 9, 1),
    );
    final item = _item(list, DateTime.utc(2026, 9, 1));
    await repository.saveList(list);
    await repository.saveItem(item);

    final firstPurchase = item.markPurchased(
      at: DateTime.utc(2026, 9, 1, 10),
      by: 'aline',
    );
    await repository.markItemPurchased(
      item: firstPurchase,
      event: _event(firstPurchase, 'event-1'),
    );
    expect((await repository.getItemsByList(list.id)).single.completedAt,
        DateTime.utc(2026, 9, 1, 10));

    await repository.saveItem(firstPurchase.markPending(DateTime.utc(2026, 9, 2)));
    final repurchased = (await repository.getItemsByList(list.id)).single.markPurchased(
          at: DateTime.utc(2026, 9, 16),
          by: 'aline',
        );
    await repository.markItemPurchased(
      item: repurchased,
      event: _event(repurchased, 'event-2'),
    );

    final events = await repository.getPurchaseEvents(
      scopeId: list.scopeId,
      identityKey: 'leite',
    );
    expect(events, hasLength(2));
    expect(events.map((event) => event.purchasedAt), [
      DateTime.utc(2026, 9, 1, 10),
      DateTime.utc(2026, 9, 16),
    ]);
    expect((await repository.getItemsByList(list.id)).single.completedAt,
        DateTime.utc(2026, 9, 16));
    expect((await firestore.collection('transactions').get()).docs, isEmpty);
  });

  test('desmarcar não apaga o histórico de compra', () async {
    final repository = FirestoreHouseholdListRepository(
      firestore: FakeFirebaseFirestore(),
    );
    final list = _list(
      id: 'market',
      scopeId: 'user:aline',
      name: 'Mercado',
      type: HouseholdListType.shopping,
      now: DateTime.utc(2026, 9, 1),
    );
    final item = _item(list, DateTime.utc(2026, 9, 1));
    await repository.saveItem(item);
    final purchased = item.markPurchased(at: DateTime.utc(2026, 9, 1));
    await repository.markItemPurchased(
      item: purchased,
      event: _event(purchased, 'event-1'),
    );
    await repository.saveItem(purchased.markPending(DateTime.utc(2026, 9, 2)));

    final restored = (await repository.getItemsByList(list.id)).single;
    expect(restored.isPurchased, isFalse);
    expect(restored.completedAt, isNull);
    expect(await repository.getPurchaseEvents(scopeId: list.scopeId), hasLength(1));
    expect(
      await repository.getPurchaseEventsByList(
        scopeId: list.scopeId,
        listId: list.id,
      ),
      hasLength(1),
    );
  });

  test('histórico da lista filtra eventos e ordena do mais recente', () async {
    final repository = FirestoreHouseholdListRepository(
      firestore: FakeFirebaseFirestore(),
    );
    final list = _list(
      id: 'market',
      scopeId: 'user:aline',
      name: 'Mercado',
      type: HouseholdListType.shopping,
      now: DateTime.utc(2026, 9, 1),
    );
    final item = _item(list, DateTime.utc(2026, 9, 1));
    final first = item.markPurchased(at: DateTime.utc(2026, 9, 1));
    final second = item.markPurchased(at: DateTime.utc(2026, 9, 16));
    final otherListItem = HouseholdListItem(
      id: 'other-milk',
      listId: 'other-list',
      scopeId: list.scopeId,
      displayName: 'Leite',
      identityKey: 'leite',
      status: HouseholdListItemStatus.purchased,
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 10),
      completedAt: DateTime.utc(2026, 9, 10),
    );
    await repository.markItemPurchased(
      item: first,
      event: _event(first, 'first'),
    );
    await repository.saveItem(first.markPending(DateTime.utc(2026, 9, 2)));
    await repository.markItemPurchased(
      item: second,
      event: _event(second, 'second'),
    );
    await repository.markItemPurchased(
      item: otherListItem,
      event: _event(otherListItem, 'other'),
    );

    final history = await repository.getPurchaseEventsByList(
      scopeId: list.scopeId,
      listId: list.id,
    );
    expect(history.map((event) => event.id), ['second', 'first']);
    expect(history.every((event) => event.listId == list.id), isTrue);
  });

  test('normalização respeita diferenças seguras de identidade', () {
    expect(HouseholdListItemIdentity.normalize(' LEITE  '), 'leite');
    expect(HouseholdListItemIdentity.normalize('Leite integral'), 'leite integral');
    expect(HouseholdListItemIdentity.normalize('Leite sem lactose'),
        'leite sem lactose');
  });

  test('documentos antigos sem tipo e status usam fallbacks seguros', () {
    final list = HouseholdList.fromMap({
      'id': 'old',
      'scopeId': 'user:aline',
      'name': 'Antiga',
    });
    final item = HouseholdListItem.fromMap({
      'id': 'old-item',
      'listId': 'old',
      'scopeId': 'user:aline',
      'name': 'Leite',
    });
    expect(list.type, HouseholdListType.general);
    expect(list.isActive, isTrue);
    expect(item.identityKey, 'leite');
    expect(item.isPurchased, isFalse);
  });
}

HouseholdList _list({
  required String id,
  required String scopeId,
  required String name,
  required HouseholdListType type,
  required DateTime now,
}) =>
    HouseholdList(
      id: id,
      scopeId: scopeId,
      name: name,
      type: type,
      status: HouseholdListStatus.active,
      createdAt: now,
      updatedAt: now,
    );

HouseholdListItem _item(HouseholdList list, DateTime now) => HouseholdListItem(
      id: 'milk',
      listId: list.id,
      scopeId: list.scopeId,
      displayName: 'Leite',
      identityKey: HouseholdListItemIdentity.normalize('Leite'),
      status: HouseholdListItemStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

HouseholdListItemPurchaseEvent _event(HouseholdListItem item, String id) =>
    HouseholdListItemPurchaseEvent(
      id: id,
      itemId: item.id,
      listId: item.listId,
      scopeId: item.scopeId,
      displayName: item.displayName,
      identityKey: item.identityKey,
      purchasedAt: item.completedAt!,
      purchasedBy: item.completedBy,
    );
