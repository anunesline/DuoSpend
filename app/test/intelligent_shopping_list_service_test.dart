import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/household_routines/data/repositories/firestore_household_list_repository.dart';
import 'package:app/features/household_routines/domain/models/household_list.dart';
import 'package:app/features/household_routines/domain/services/intelligent_shopping_list_service.dart';

void main() {
  test(
    'produto conhecido entra uma vez na lista ativa e preserva autoria',
    () async {
      final repository = FirestoreHouseholdListRepository(
        firestore: FakeFirebaseFirestore(),
      );
      final at = DateTime.utc(2026, 9, 21);
      await repository.saveList(
        HouseholdList(
          id: 'market',
          scopeId: 'household:aline|matheus',
          name: 'Mercado',
          type: HouseholdListType.shopping,
          status: HouseholdListStatus.active,
          createdAt: at,
          updatedAt: at,
        ),
      );
      final service = IntelligentShoppingListService(repository);
      final first = await service.addKnownProduct(
        scopeId: 'household:aline|matheus',
        productId: 'paper',
        displayName: 'Papel toalha',
        addedBy: 'aline',
        at: at,
      );
      final retry = await service.addKnownProduct(
        scopeId: 'household:aline|matheus',
        productId: 'paper',
        displayName: 'Papel toalha',
        addedBy: 'matheus',
        at: at,
      );
      final items = await repository.getItemsByList('market');
      expect(items, hasLength(1));
      expect(first!.productId, 'paper');
      expect(first.createdBy, 'aline');
      expect(retry!.id, first.id);
    },
  );
}
