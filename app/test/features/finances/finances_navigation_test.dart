import 'package:app/features/finances/data/financial_accounts_repository.dart';
import 'package:app/features/finances/presentation/account_form_page.dart';
import 'package:app/features/finances/presentation/finance_widgets.dart';
import 'package:app/features/finances/presentation/finances_page.dart';
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('hub, accounts, detail and form at $width / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = FinancialAccountsRepository(
          firestore: FakeFirebaseFirestore(),
          auth: MockFirebaseAuth(
            mockUser: MockUser(uid: 'user', displayName: 'Aline'),
            signedIn: true,
          ),
        );
        await repo.save(
          name: 'Minha conta de nome longo',
          kind: AccountKind.bank,
          bank: 'Banco',
          holder: 'Aline',
          pix: '',
          initialBalance: 100,
        );
        Future<void> noop() async {}
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: FinancesPage(
              repository: repo,
              userName: 'Aline',
              valuesVisible: true,
              hasWallet: true,
              onHome: () {},
              onCreate: noop,
              onRoutines: noop,
              onAi: noop,
              onCards: noop,
              onBills: noop,
              onBudgets: noop,
              onTransactions: noop,
              onReports: noop,
              onGoals: noop,
              onAccountsChanged: noop,
              onProfile: () {},
              onNotifications: () {},
              hasPendingItems: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.widgetWithText(FinanceEntry, 'Contas e carteiras'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Patrimônio total'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.widgetWithText(FinanceEntry, 'Minha conta de nome longo'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Detalhe da conta'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Editar'));
        await tester.pumpAndSettle();
        expect(find.byType(AccountFormPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        // Finance in the persistent navigation returns straight to the existing hub.
        await tester.tap(find.text('Finanças').last);
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(FinanceEntry, 'Contas e carteiras'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
