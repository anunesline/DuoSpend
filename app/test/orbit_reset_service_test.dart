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
}
