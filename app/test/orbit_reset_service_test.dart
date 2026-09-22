import 'package:app/features/settings/data/orbit_reset_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  OrbitResetService serviceFor(String userId) => OrbitResetService(
    firestore: firestore,
    auth: MockFirebaseAuth(mockUser: MockUser(uid: userId), signedIn: true),
  );

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('wallets').doc('shared').set({
      'memberIds': ['aline', 'matheus'],
      'balance': 100,
    });
    await firestore
        .collection('wallets')
        .doc('shared')
        .collection('transactions')
        .doc('expense')
        .set({'value': 50});
  });

  test(
    'shared reset requires both authorized members before deleting data',
    () async {
      final aline = serviceFor('aline');
      final matheus = serviceFor('matheus');

      await aline.requestSharedReset(
        walletId: 'shared',
        memberIds: ['aline', 'matheus'],
      );
      expect(
        (await firestore
                .collection('wallets')
                .doc('shared')
                .collection('transactions')
                .doc('expense')
                .get())
            .exists,
        isTrue,
      );

      final pending = await matheus.getPendingSharedReset('shared');
      expect(pending, isNotNull);
      expect(
        await matheus.confirmSharedReset(
          walletId: 'shared',
          requestId: pending!.id,
          memberIds: ['aline', 'matheus'],
        ),
        isTrue,
      );
      expect(
        (await firestore
                .collection('wallets')
                .doc('shared')
                .collection('transactions')
                .doc('expense')
                .get())
            .exists,
        isFalse,
      );
    },
  );

  test('requester can cancel a pending shared reset', () async {
    final aline = serviceFor('aline');
    await aline.requestSharedReset(
      walletId: 'shared',
      memberIds: ['aline', 'matheus'],
    );
    final request = await aline.getPendingSharedReset('shared');
    await aline.cancelSharedReset(walletId: 'shared', requestId: request!.id);
    expect(await aline.getPendingSharedReset('shared'), isNull);
    expect(
      (await firestore
              .collection('wallets')
              .doc('shared')
              .collection('transactions')
              .doc('expense')
              .get())
          .exists,
      isTrue,
    );
  });

  test(
    'non-member cannot request, confirm, or cancel a shared reset',
    () async {
      final aline = serviceFor('aline');
      final outsider = serviceFor('other');
      await expectLater(
        outsider.requestSharedReset(
          walletId: 'shared',
          memberIds: ['aline', 'matheus'],
        ),
        throwsStateError,
      );
      await aline.requestSharedReset(
        walletId: 'shared',
        memberIds: ['aline', 'matheus'],
      );
      final request = await aline.getPendingSharedReset('shared');
      await expectLater(
        outsider.confirmSharedReset(
          walletId: 'shared',
          requestId: request!.id,
          memberIds: ['aline', 'matheus'],
        ),
        throwsStateError,
      );
      await expectLater(
        outsider.cancelSharedReset(walletId: 'shared', requestId: request.id),
        throwsStateError,
      );
    },
  );

  test(
    'individual reset removes personal derived data but preserves shared data',
    () async {
      final aline = serviceFor('aline');
      final product = firestore
          .collection('users')
          .doc('aline')
          .collection('products')
          .doc('milk');
      await product.set({});
      await product.collection('priceHistory').doc('purchase').set({});
      await firestore
          .collection('users')
          .doc('aline')
          .collection('accountTransfers')
          .doc('transfer')
          .set({});
      for (final collection in [
        'household_lists',
        'household_list_items',
        'household_list_purchase_events',
        'consumption_events',
      ]) {
        await firestore.collection(collection).doc('personal-$collection').set({
          'scopeId': 'user:aline',
        });
        await firestore.collection(collection).doc('shared-$collection').set({
          'scopeId': 'household:aline|matheus',
        });
      }

      await aline.resetMyData();

      expect((await product.get()).exists, isFalse);
      expect(
        (await product.collection('priceHistory').doc('purchase').get()).exists,
        isFalse,
      );
      expect(
        (await firestore
                .collection('users')
                .doc('aline')
                .collection('accountTransfers')
                .doc('transfer')
                .get())
            .exists,
        isFalse,
      );
      expect(
        (await firestore
                .collection('household_lists')
                .doc('personal-household_lists')
                .get())
            .exists,
        isFalse,
      );
      expect(
        (await firestore
                .collection('consumption_events')
                .doc('personal-consumption_events')
                .get())
            .exists,
        isFalse,
      );
      expect(
        (await firestore
                .collection('household_lists')
                .doc('shared-household_lists')
                .get())
            .exists,
        isTrue,
      );
      expect(
        (await firestore
                .collection('consumption_events')
                .doc('shared-consumption_events')
                .get())
            .exists,
        isTrue,
      );
    },
  );

  test(
    'shared reset removes only shared lists and consumption events',
    () async {
      final aline = serviceFor('aline');
      final matheus = serviceFor('matheus');
      for (final collection in [
        'household_lists',
        'household_list_items',
        'household_list_purchase_events',
        'consumption_events',
      ]) {
        await firestore.collection(collection).doc('personal-$collection').set({
          'scopeId': 'user:aline',
        });
        await firestore.collection(collection).doc('shared-$collection').set({
          'scopeId': 'household:aline|matheus',
        });
      }
      await aline.requestSharedReset(
        walletId: 'shared',
        memberIds: ['aline', 'matheus'],
      );
      final request = await matheus.getPendingSharedReset('shared');
      await matheus.confirmSharedReset(
        walletId: 'shared',
        requestId: request!.id,
        memberIds: ['aline', 'matheus'],
      );

      expect(
        (await firestore
                .collection('household_lists')
                .doc('shared-household_lists')
                .get())
            .exists,
        isFalse,
      );
      expect(
        (await firestore
                .collection('consumption_events')
                .doc('shared-consumption_events')
                .get())
            .exists,
        isFalse,
      );
      expect(
        (await firestore
                .collection('household_lists')
                .doc('personal-household_lists')
                .get())
            .exists,
        isTrue,
      );
      expect(
        (await firestore
                .collection('consumption_events')
                .doc('personal-consumption_events')
                .get())
            .exists,
        isTrue,
      );
    },
  );
}
