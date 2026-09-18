import 'package:app/features/home/data/models/credit_card_invoice_model.dart';
import 'package:app/features/home/data/models/credit_card_model.dart';
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/wallet/presentation/controllers/wallet_details_controller.dart';
import 'package:app/features/wallet/presentation/pages/wallet_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _today = DateTime(2026, 5, 10);
final _wallet = WalletModel(
  id: 'wallet',
  name: 'Minha carteira',
  balance: 1000,
);
TransactionModel _transaction(
  String id,
  DateTime date,
  double value, {
  String type = 'expense',
  String status = 'pending',
  String? method,
}) => TransactionModel(
  id: id,
  description: id,
  value: value,
  type: type,
  date: date,
  walletId: _wallet.id,
  category: 'Casa',
  subcategory: 'Outros',
  financialStatus: status,
  paymentMethod: method,
);
CreditCardInvoiceModel _invoice(
  String id,
  DateTime date,
  double value, {
  bool paid = false,
}) => CreditCardInvoiceModel(
  id: id,
  cardId: 'card',
  ownerMemberId: 'user',
  referenceYear: date.year,
  referenceMonth: date.month,
  closingDate: date.subtract(const Duration(days: 10)),
  dueDate: date,
  total: value,
  status: paid ? 'paid' : 'open',
  createdAt: _today,
  updatedAt: _today,
);
WalletDetailsController _controller(WalletDetailsData data) =>
    WalletDetailsController(
      wallet: data.wallet,
      loader: (_) async => data,
      clock: () => _today,
    );

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('projection excludes settled entries, paid invoices, credit purchases and next month', () async {
    final controller = _controller(
      WalletDetailsData(
        wallet: _wallet,
        transactions: [
          _transaction('Receita', DateTime(2026, 5, 12), 500, type: 'income'),
          _transaction('Boleto', DateTime(2026, 5, 15), 200),
          _transaction(
            'Já pago',
            DateTime(2026, 5, 15),
            300,
            status: 'settled',
          ),
          _transaction(
            'Crédito',
            DateTime(2026, 5, 15),
            100,
            status: 'invoice',
            method: 'creditCard',
          ),
          _transaction('Junho', DateTime(2026, 6, 1), 900),
        ],
        invoices: [
          _invoice('aberta', DateTime(2026, 5, 20), 100),
          _invoice('paga', DateTime(2026, 5, 20), 250, paid: true),
        ],
      ),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.forecast.projectedBalance, 1200);
    expect(controller.upcoming.map((e) => e.value), [500, 200, 100]);
    expect(controller.currentInvoice('card')!.id, 'aberta');
  });

  test('period includes the last day and zero activity does not invent percentages', () async {
    final controller = _controller(
      WalletDetailsData(
        wallet: _wallet,
        transactions: [
          _transaction(
            'Abril',
            DateTime(2026, 4, 30, 23, 59),
            125,
            type: 'income',
            status: 'settled',
          ),
          _transaction('Maio', DateTime(2026, 5, 1), 40, status: 'settled'),
          _transaction('Pendente', DateTime(2026, 4, 20), 70),
        ],
      ),
    );
    addTearDown(controller.dispose);
    await controller.load();
    controller.selectPeriod(DateTime(2026, 4, 1), DateTime(2026, 4, 30));
    expect(controller.income, 125);
    expect(controller.expense, 0);
    expect(controller.periodTransactions.map((t) => t.id), [
      'Abril',
      'Pendente',
    ]);
    controller.selectPeriod(DateTime(2026, 3, 1), DateTime(2026, 3, 31));
    expect(controller.incomeRatio, 0);
    expect(controller.expenseRatio, 0);
  });

  test(
    'refresh reports failure and can recover with a fresh balance',
    () async {
      var attempts = 0;
      final controller = WalletDetailsController(
        wallet: _wallet,
        loader: (_) async {
          if (attempts++ == 0) throw StateError('offline');
          return WalletDetailsData(wallet: _wallet.copyWith(balance: 2000));
        },
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.error, isNotNull);
      expect(controller.loading, isFalse);
      await controller.load();
      expect(controller.error, isNull);
      expect(controller.data.wallet.balance, 2000);
    },
  );

  for (final (width, scale) in [(360.0, 1.0), (426.5, 1.0), (360.0, 1.5)]) {
    testWidgets(
      'wallet fits $width at $scale, hides amounts and opens statement',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = _controller(
          WalletDetailsData(
            wallet: _wallet,
            transactions: [
              _transaction('Aluguel', DateTime(2026, 5, 15), 200),
              _transaction(
                'Salário',
                DateTime(2026, 5, 17),
                500,
                type: 'income',
              ),
              _transaction(
                'Pagamento',
                DateTime(2026, 5, 2),
                123.45,
                status: 'settled',
              ),
            ],
            cards: const [
              CreditCardModel(
                id: 'card',
                ownerMemberId: 'user',
                walletId: 'wallet',
                name: 'Meu cartão',
                creditLimit: 5000,
                closingDay: 10,
                dueDay: 20,
                lastFourDigits: '4321',
              ),
            ],
            invoices: [_invoice('atual', DateTime(2026, 5, 20), 100)],
          ),
        );
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: WalletDetailsPage(wallet: _wallet, controller: controller),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Ocultar valores'));
        await tester.pumpAndSettle();
        expect(find.textContaining('1.000,00'), findsNothing);
        expect(find.textContaining('123,45'), findsNothing);
        expect(find.textContaining('200,00'), findsNothing);
        expect(find.textContaining('100,00'), findsNothing);
        await tester.tap(find.text('Extrato'));
        await tester.pumpAndSettle();
        expect(find.text('Pagamento'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Este mês'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mês passado'));
        await tester.pumpAndSettle();
        expect(find.text('Nenhuma transação neste período.'), findsOneWidget);
      },
    );
  }
}
