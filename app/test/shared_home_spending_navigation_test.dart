import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/home/domain/services/orbit_home_overview_builder.dart';
import 'package:app/features/home/presentation/widgets/orbit_home_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('shared monthly spending opens history instead of budgets', (
    tester,
  ) async {
    final actions = <String>[];
    final wallet = WalletModel(
      id: 'shared',
      name: 'Nossa carteira',
      balance: 100,
      type: WalletType.shared,
      ownerId: 'aline',
      memberIds: const ['aline', 'matheus'],
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 1),
    );
    final data = const OrbitHomeOverviewBuilder().build(
      wallet: wallet,
      currentUserId: 'aline',
      reference: DateTime.utc(2026, 9, 22),
      transactions: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OrbitHomeContent(
              data: data,
              valuesVisible: true,
              onWallet: () => actions.add('wallet'),
              onBudget: () => actions.add('budget'),
              onCalendar: () => actions.add('calendar'),
              onGoals: () => actions.add('goals'),
              onInsights: () => actions.add('insights'),
              onRoutines: () => actions.add('routines'),
              onSettlements: () => actions.add('settlements'),
              onContribution: () => actions.add('contribution'),
              onHistory: () => actions.add('history'),
              onRetry: () => actions.add('retry'),
              onCompleteTask: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Gastos do mês'));
    expect(actions, ['history']);
  });
}
