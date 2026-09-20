import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:app/features/home/data/models/credit_card_model.dart';
import 'package:app/features/home/data/models/credit_card_invoice_model.dart';
import 'package:app/features/home/data/repositories/credit_card_repository.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/wallet/presentation/controllers/credit_card_controller.dart';
import 'package:app/features/wallet/presentation/pages/credit_cards_page.dart';

class VisualCardRepository extends CreditCardRepository {
  VisualCardRepository({this.empty = false, this.failCategories = false})
    : super(firestore: FakeFirebaseFirestore(), auth: MockFirebaseAuth());

  final bool empty;
  bool failCategories;
  int categoryLoads = 0;
  final requestedInvoiceIds = <String>[];
  static const card = CreditCardModel(
    id: 'card',
    ownerMemberId: 'user',
    name: 'Cartão de teste',
    creditLimit: 3500,
    usedLimit: 400,
    closingDay: 10,
    dueDay: 17,
  );

  static TransactionModel purchase(String id, String category, double value) =>
      TransactionModel(
        id: id,
        description: 'Compra de teste $id',
        value: value,
        type: 'expense',
        date: DateTime.now(),
        walletId: 'wallet',
        category: category,
        subcategory: '',
        paymentSourceId: 'card',
      );

  @override
  Future<List<CreditCardModel>> getCards() async => [card];

  @override
  Future<List<CreditCardInvoiceModel>> getInvoices({
    required String cardId,
  }) async => empty
      ? []
      : [
          CreditCardInvoiceModel(
            id: 'current-invoice',
            cardId: cardId,
            ownerMemberId: 'user',
            referenceYear: 2026,
            referenceMonth: 9,
            closingDate: DateTime(2026, 9, 10),
            dueDate: DateTime(2026, 9, 17),
            total: 400,
            createdAt: DateTime(2026, 9),
            updatedAt: DateTime(2026, 9),
          ),
        ];

  @override
  Future<List<TransactionModel>> getCardPurchases({
    required String cardId,
  }) async => empty
      ? []
      : [
          purchase('1', 'Alimentação', 300), purchase('2', 'Transporte', 100),
          // Deliberately not in the current invoice.
          purchase('old', 'Saúde', 900),
        ];

  @override
  Future<List<TransactionModel>> getInvoicePurchases({
    required String cardId,
    required String invoiceId,
  }) async {
    categoryLoads++;
    requestedInvoiceIds.add(invoiceId);
    if (failCategories) throw StateError('Test failure');
    return [
      purchase('1', 'Alimentação', 300),
      purchase('2', 'Transporte', 100),
    ];
  }
}

Future<CreditCardController> mountCardDetail(
  WidgetTester tester,
  VisualCardRepository repository, {
  double width = 360,
  double textScale = 1,
  Future<void> Function()? onNewTransaction,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = CreditCardController(repository: repository);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: CreditCardsPage(
        individualWallets: const [],
        controller: controller,
        onNewTransaction: onNewTransaction,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cartão de teste'));
  await tester.pumpAndSettle();
  // Exercise the detail layout, not the unchanged card-list layout.
  tester.view.physicalSize = Size(width, 800);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('verso do cartão mostra limites sem alterar estado financeiro', (
    tester,
  ) async {
    final controller = await mountCardDetail(
      tester,
      VisualCardRepository(empty: true),
    );
    final front = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == 'Mostrar resumo do limite',
    );
    expect(tester.getSize(front).height, lessThan(180));
    await tester.tap(front);
    await tester.pumpAndSettle();
    expect(find.text('Resumo do limite'), findsOneWidget);
    expect(find.text('Utilizado'), findsOneWidget);
    expect(controller.cards.single, same(VisualCardRepository.card));
    await tester.tap(
      find.bySemanticsLabel(RegExp(r'^Mostrar frente do cartão')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Resumo do limite'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'gráfico usa somente compras da fatura atual e não recarrega no flip',
    (tester) async {
      final repository = VisualCardRepository();
      await mountCardDetail(tester, repository);
      await tester.scrollUntilVisible(find.text('75%'), 200);
      expect(find.text('25%'), findsOneWidget);
      expect(repository.requestedInvoiceIds, ['current-invoice']);
      await tester.drag(find.byType(ListView).last, const Offset(0, 1500));
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel(RegExp(r'^Mostrar resumo do limite')),
      );
      await tester.pumpAndSettle();
      expect(repository.categoryLoads, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('CTA chama fluxo existente e atualiza os dados no retorno', (
    tester,
  ) async {
    var calls = 0;
    final repository = VisualCardRepository();
    await mountCardDetail(
      tester,
      repository,
      onNewTransaction: () async {
        calls++;
      },
    );
    await tester.scrollUntilVisible(find.text('Nova transação'), 300);
    await tester.tap(find.text('Nova transação'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.drag(find.byType(ListView).last, const Offset(0, 1500));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('75%'), 200);
    expect(repository.categoryLoads, greaterThanOrEqualTo(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('estados vazios compactos sem dados fictícios em 320dp', (
    tester,
  ) async {
    await mountCardDetail(
      tester,
      VisualCardRepository(empty: true),
      width: 320,
      textScale: 1.5,
    );
    await tester.scrollUntilVisible(
      find.text('Nenhuma compra encontrada.'),
      200,
    );
    expect(
      find.text('Nenhum gasto categorizado nesta fatura.'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.text('Nenhuma compra encontrada.')).height,
      lessThan(100),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'falha no gráfico oferece nova tentativa sem fingir ausência de gastos',
    (tester) async {
      final repository = VisualCardRepository(failCategories: true);
      await mountCardDetail(tester, repository);
      await tester.scrollUntilVisible(find.text('Tentar novamente'), 200);
      await tester.ensureVisible(
        find.widgetWithText(TextButton, 'Tentar novamente'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível carregar os gastos.'), findsOneWidget);
      repository.failCategories = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('75%'), findsOneWidget);
      expect(repository.categoryLoads, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
