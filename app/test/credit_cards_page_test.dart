import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/home/data/repositories/credit_card_repository.dart';
import 'package:app/features/wallet/presentation/controllers/credit_card_controller.dart';
import 'package:app/features/wallet/presentation/pages/credit_cards_page.dart';

void main() {
  const userId = 'user-1';

  WalletModel wallet() => WalletModel(
        id: 'wallet-1',
        name: 'Carteira Principal',
        balance: 1000,
        ownerId: userId,
        memberIds: const [userId],
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );

  Future<CreditCardController> controller({bool withWallet = false}) async {
    final firestore = FakeFirebaseFirestore();
    if (withWallet) {
      final financialWallet = wallet();
      await firestore
          .collection('wallets')
          .doc(financialWallet.id)
          .set(financialWallet.toMap());
    }

    return CreditCardController(
      repository: CreditCardRepository(
        firestore: firestore,
        auth: MockFirebaseAuth(
          mockUser: MockUser(uid: userId),
          signedIn: true,
        ),
      ),
    );
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    required CreditCardController controller,
    List<WalletModel> wallets = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreditCardsPage(
          individualWallets: wallets,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillCard(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.add_card_rounded));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Meu cartão');
    await tester.enterText(fields.at(2), '1000');
    await tester.enterText(fields.at(3), '20');
    await tester.enterText(fields.at(4), '10');
  }

  Future<List<FlutterError>> runWithoutFlutterErrors(
    Future<void> Function() action,
  ) async {
    final errors = <FlutterError>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(FlutterError(details.exception.toString()));
    };
    try {
      await action();
    } finally {
      FlutterError.onError = previous;
    }
    return errors;
  }

  testWidgets('cria cartão com carteira e desmonta o diálogo sem assertion',
      (tester) async {
    final cardController = await controller(withWallet: true);
    addTearDown(cardController.dispose);
    await pumpPage(
      tester,
      controller: cardController,
      wallets: [wallet()],
    );

    final errors = await runWithoutFlutterErrors(() async {
      await fillCard(tester);
      await tester.tap(find.text('Sem carteira'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carteira Principal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();
    });

    expect(errors, isEmpty);
    expect(find.text('Meu cartão'), findsOneWidget);
  });

  testWidgets('cria cartão sem carteira e desmonta o diálogo sem assertion',
      (tester) async {
    final cardController = await controller();
    addTearDown(cardController.dispose);
    await pumpPage(tester, controller: cardController);

    final errors = await runWithoutFlutterErrors(() async {
      await fillCard(tester);
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();
    });

    expect(errors, isEmpty);
    expect(find.text('Meu cartão'), findsOneWidget);
    expect(find.text('Sem carteira'), findsOneWidget);
  });
}
