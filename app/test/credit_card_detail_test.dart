import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:app/features/home/data/models/credit_card_invoice_model.dart';
import 'package:app/features/home/data/models/credit_card_model.dart';
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/home/data/repositories/credit_card_repository.dart';
import 'package:app/features/wallet/presentation/controllers/credit_card_controller.dart';
import 'package:app/features/wallet/presentation/pages/credit_cards_page.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';

class _FakeCardRepository extends CreditCardRepository {
  _FakeCardRepository(this.cards)
    : super(firestore: FakeFirebaseFirestore(), auth: MockFirebaseAuth());

  List<CreditCardModel> cards;

  @override
  Future<List<CreditCardModel>> getCards() async => cards;

  @override
  Future<List<CreditCardInvoiceModel>> getInvoices({
    required String cardId,
  }) async => const [];

  @override
  Future<List<TransactionModel>> getCardPurchases({
    required String cardId,
  }) async => const [];

  @override
  Future<CreditCardModel> updateCard({required CreditCardModel card}) async =>
      card;

  @override
  Future<void> setCardActive({
    required String cardId,
    required bool isActive,
  }) async {}
}

class _FailingCardRepository extends _FakeCardRepository {
  _FailingCardRepository(super.cards);

  @override
  Future<CreditCardModel> updateCard({required CreditCardModel card}) async {
    throw StateError('Falha ao salvar cartão.');
  }
}

MockFirebaseAuth _authFor(String uid) => MockFirebaseAuth(
  signedIn: true,
  mockUser: MockUser(uid: uid),
);

Future<CreditCardRepository> _repositoryWithWallet(
  Map<String, dynamic> walletData, {
  String walletId = 'principal',
}) async {
  final firestore = FakeFirebaseFirestore();

if (walletId == 'principal') {
  await firestore
      .collection('users')
      .doc('user-1')
      .collection('wallets')
      .doc(walletId)
      .set(walletData);
} else {
  await firestore.collection('wallets').doc(walletId).set(walletData);
}
  return CreditCardRepository(
    firestore: firestore,
    auth: _authFor('user-1'),
  );
}

void main() {
  testWidgets('abre detalhe de cartão sem carteira', (tester) async {
    final card = const CreditCardModel(
      id: 'card-1',
      ownerMemberId: 'user-1',
      name: 'Benefício',
      creditLimit: 1000,
      closingDay: 10,
      dueDay: 17,
    );
    final controller = CreditCardController(
      repository: _FakeCardRepository([card]),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CreditCardsPage(
          individualWallets: const [],
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Benefício'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Sem carteira', findRichText: true),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Informações do cartão', skipOffstage: false),
      400,
    );
    await tester.pumpAndSettle();
    expect(find.text('Informações do cartão'), findsOneWidget);
  });

  testWidgets('abre detalhe de cartão com carteira e permite voltar', (
    tester,
  ) async {
    final wallet = WalletModel(
      id: 'wallet-1',
      name: 'Carteira Principal',
      balance: 100,
    );
    final card = const CreditCardModel(
      id: 'card-2',
      ownerMemberId: 'user-1',
      walletId: 'wallet-1',
      name: 'Inter',
      creditLimit: 5000,
      closingDay: 10,
      dueDay: 17,
    );
    final controller = CreditCardController(
      repository: _FakeCardRepository([card]),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CreditCardsPage(
          individualWallets: [wallet],
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inter'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Carteira Principal', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Visão geral'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('mantém a lista atualizada após edição bem-sucedida', () async {
    final card = const CreditCardModel(
      id: 'card-3',
      ownerMemberId: 'user-1',
      name: 'Cartão original',
      creditLimit: 1000,
      closingDay: 10,
      dueDay: 17,
    );
    final controller = CreditCardController(
      repository: _FakeCardRepository([card]),
    );
    await controller.loadCards();
    final updated = card.copyWith(
      name: 'Cartão atualizado',
      creditLimit: 2000,
      closingDay: 12,
      dueDay: 19,
      walletId: null,
    );

    final result = await controller.updateCard(updated);

    expect(result, updated);
    expect(controller.cards.single, updated);
  });

  test('mantém o cartão anterior e expõe o erro quando a edição falha', () async {
    final card = const CreditCardModel(
      id: 'card-4',
      ownerMemberId: 'user-1',
      name: 'Cartão original',
      creditLimit: 1000,
      closingDay: 10,
      dueDay: 17,
    );
    final controller = CreditCardController(
      repository: _FailingCardRepository([card]),
    );
    await controller.loadCards();
    final updated = card.copyWith(creditLimit: 2000);

    final result = await controller.updateCard(updated);

    expect(result, isNull);
    expect(controller.cards.single, card);
    expect(controller.errorMessage, 'Falha ao salvar cartão.');
  });

  test('permite vincular a carteira principal legada sem metadados', () async {
    final repository = await _repositoryWithWallet({
      'name': 'Carteira Principal',
      'balance': 0,
    });
    const card = CreditCardModel(
      id: 'card-legacy',
      ownerMemberId: 'user-1',
      name: 'Cartão',
      creditLimit: 3500,
      closingDay: 10,
      dueDay: 17,
    );

    final updated = await repository.updateCard(
      card: card.copyWith(walletId: 'principal'),
    );

    expect(updated.walletId, 'principal');
  });

  test('permite carteira individual moderna e rejeita compartilhada', () async {
    final individual = await _repositoryWithWallet(
      {
        'name': 'Individual',
        'balance': 0,
        'ownerId': 'user-1',
        'type': 'individual',
        'memberIds': ['user-1'],
      },
      walletId: 'wallet-individual',
    );
    const card = CreditCardModel(
      id: 'card-modern',
      ownerMemberId: 'user-1',
      name: 'Cartão',
      creditLimit: 3500,
      closingDay: 10,
      dueDay: 17,
    );

    await expectLater(
      individual.updateCard(card: card.copyWith(walletId: 'wallet-individual')),
      completes,
    );

    final shared = await _repositoryWithWallet(
      {
        'name': 'Compartilhada',
        'balance': 0,
        'ownerId': 'user-1',
        'type': 'shared',
        'memberIds': ['user-1', 'user-2'],
      },
      walletId: 'wallet-shared',
    );

    await expectLater(
      shared.updateCard(card: card.copyWith(walletId: 'wallet-shared')),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('carteira individual'),
        ),
      ),
    );
  });

  testWidgets('interpreta corretamente os formatos do limite', (tester) async {
    const card = CreditCardModel(
      id: 'card-limit',
      ownerMemberId: 'user-1',
      name: 'Cartão',
      creditLimit: 3500,
      closingDay: 10,
      dueDay: 17,
    );
    final controller = CreditCardController(
      repository: _FakeCardRepository([card]),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CreditCardsPage(
          individualWallets: const [],
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cartão'));
    await tester.pumpAndSettle();

    final limitField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Limite',
    );
    for (final value in ['3500', '3500.00', '3.500,00']) {
      await tester.tap(find.byTooltip('Ações do cartão'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar cartão'));
      await tester.pumpAndSettle();
      await tester.enterText(limitField, value);
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(controller.cards.single.creditLimit, 3500.0);
    }
  });
}
