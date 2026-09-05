import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/household_routines/data/repositories/firestore_household_list_repository.dart';
import 'package:app/features/household_routines/domain/models/household_list.dart';
import 'package:app/features/household_routines/domain/models/household_list_item.dart';
import 'package:app/features/household_routines/domain/services/shopping_list_transaction_synchronizer.dart';

void main() {
  const scopeId = 'user:aline';
  final purchasedAt = DateTime.utc(2026, 9, 5, 14, 30);

  test('Leite pendente é concluído e gera um evento financeiro', () async {
    final fixture = await _fixture(scopeId: scopeId, itemName: 'Leite');
    await fixture.sync('Leite', purchasedAt: purchasedAt);

    final item = (await fixture.repository.getItemsByList('market')).single;
    final events = await fixture.repository.getPurchaseEvents(scopeId: scopeId);
    expect(item.isPurchased, isTrue);
    expect(item.completedAt, purchasedAt);
    expect(item.financialReferenceId, 'transaction-1:financial-item-1');
    expect(events, hasLength(1));
    expect(events.single.source, 'financialTransaction');
    expect(events.single.sourceReferenceId, 'transaction-1:financial-item-1');
    expect(
      (await fixture.repository.firestore.collection('transactions').get())
          .docs,
      isEmpty,
    );
  });

  test('diferença de caixa e espaços corresponde', () async {
    final fixture = await _fixture(scopeId: scopeId, itemName: ' LEITE ');
    await fixture.sync('leite', purchasedAt: purchasedAt);
    expect((await fixture.items()).single.isPurchased, isTrue);
  });

  test('produto diferente e variante semântica não correspondem', () async {
    final different = await _fixture(scopeId: scopeId, itemName: 'Leite');
    await different.sync('Café', purchasedAt: purchasedAt);
    expect((await different.items()).single.isPurchased, isFalse);

    final variant = await _fixture(scopeId: scopeId, itemName: 'Leite integral');
    await variant.sync('Leite sem lactose', purchasedAt: purchasedAt);
    expect((await variant.items()).single.isPurchased, isFalse);
  });

  test('item concluído não gera evento e reprocessamento é idempotente', () async {
    final fixture = await _fixture(scopeId: scopeId, itemName: 'Leite');
    await fixture.sync('Leite', purchasedAt: purchasedAt);
    await fixture.sync('Leite', purchasedAt: purchasedAt);
    expect(await fixture.repository.getPurchaseEvents(scopeId: scopeId), hasLength(1));

    final completed = await _fixture(
      scopeId: scopeId,
      itemName: 'Leite',
      purchased: true,
    );
    await completed.sync('Leite', purchasedAt: purchasedAt);
    expect(await completed.repository.getPurchaseEvents(scopeId: scopeId), isEmpty);
  });

  test('mesmo produto pendente em listas diferentes permanece intacto', () async {
    final fixture = await _fixture(scopeId: scopeId, itemName: 'Leite');
    await fixture.addListAndItem(listId: 'secondary', itemName: 'leite');
    await fixture.sync('LEITE', purchasedAt: purchasedAt);
    expect((await fixture.items()).single.isPurchased, isFalse);
    expect((await fixture.items('secondary')).single.isPurchased, isFalse);
    expect(await fixture.repository.getPurchaseEvents(scopeId: scopeId), isEmpty);
  });

  test('marcação manual continua preservando seu evento', () async {
    final fixture = await _fixture(scopeId: scopeId, itemName: 'Leite');
    final item = (await fixture.items()).single;
    final completed = item.markPurchased(at: purchasedAt, by: 'aline');
    await fixture.repository.markItemPurchased(
      item: completed,
      event: HouseholdListItemPurchaseEvent(
        id: 'manual-event',
        itemId: item.id,
        listId: item.listId,
        scopeId: item.scopeId,
        displayName: item.displayName,
        identityKey: item.identityKey,
        purchasedAt: purchasedAt,
        purchasedBy: 'aline',
      ),
    );
    final event = (await fixture.repository.getPurchaseEvents(scopeId: scopeId)).single;
    expect(event.id, 'manual-event');
    expect(event.source, isNull);
  });
}

class _Fixture {
  final String scopeId;
  final FirestoreHouseholdListRepository repository;
  final ShoppingListTransactionSynchronizer synchronizer;

  _Fixture(this.scopeId, this.repository, this.synchronizer);

  Future<void> sync(String name, {required DateTime purchasedAt}) =>
      synchronizer.synchronize(
        scopeId: scopeId,
        transactionId: 'transaction-1',
        purchasedAt: purchasedAt,
        purchasedBy: 'aline',
        items: [
          PurchasedTransactionItem(id: 'financial-item-1', displayName: name),
        ],
      );

  Future<List<HouseholdListItem>> items([String listId = 'market']) =>
      repository.getItemsByList(listId);

  Future<void> addListAndItem({required String listId, required String itemName}) async {
    final now = DateTime.utc(2026, 9, 1);
    await repository.saveList(_list(listId, scopeId, now));
    await repository.saveItem(_item('$listId-item', listId, scopeId, itemName, now));
  }
}

Future<_Fixture> _fixture({
  required String scopeId,
  required String itemName,
  bool purchased = false,
}) async {
  final repository = FirestoreHouseholdListRepository(
    firestore: FakeFirebaseFirestore(),
  );
  final fixture = _Fixture(
    scopeId,
    repository,
    ShoppingListTransactionSynchronizer(repository: repository),
  );
  final now = DateTime.utc(2026, 9, 1);
  await repository.saveList(_list('market', scopeId, now));
  var item = _item('market-item', 'market', scopeId, itemName, now);
  if (purchased) item = item.markPurchased(at: now, by: 'aline');
  await repository.saveItem(item);
  return fixture;
}

HouseholdList _list(String id, String scopeId, DateTime now) => HouseholdList(
      id: id,
      scopeId: scopeId,
      name: 'Mercado',
      type: HouseholdListType.shopping,
      status: HouseholdListStatus.active,
      createdAt: now,
      updatedAt: now,
    );

HouseholdListItem _item(
  String id,
  String listId,
  String scopeId,
  String name,
  DateTime now,
) =>
    HouseholdListItem(
      id: id,
      listId: listId,
      scopeId: scopeId,
      displayName: name,
      identityKey: HouseholdListItemIdentity.normalize(name),
      status: HouseholdListItemStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
