import '../../../transactions/presentation/pages/history_page.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/home_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/transactions_preview.dart';
import '../widgets/wallet_card.dart';
import '../../../transactions/presentation/pages/new_transaction_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController controller = HomeController();

  @override
  void initState() {
    super.initState();
    controller.loadHome();
  }

  Future<void> _openNewTransactionPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NewTransactionPage(),
      ),
    );

    await controller.loadHome();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final wallet = controller.wallet;

        return Scaffold(
          appBar: AppBar(
            title: const Text('DuoSpend'),
            centerTitle: true,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openNewTransactionPage,
            child: const Icon(Icons.add),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '👋 Olá, ${controller.userName}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Bem-vindo ao DuoSpend',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                BalanceCard(
                  balance: wallet?.balance ?? 0,
                ),
                const SizedBox(height: AppSpacing.lg),
                SummaryCard(
                  income: controller.totalIncome,
                  expense: controller.totalExpense,
                ),
                const SizedBox(height: AppSpacing.lg),
                WalletCard(
                  walletName: wallet?.name ?? 'Carteira Principal',
                  balance: wallet?.balance ?? 0,
                ),
                const SizedBox(height: AppSpacing.lg),
                GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoryPage(),
      ),
    );
  },
  child: TransactionsPreview(
    transactions: controller.transactions,
  ),
),
              ],
            ),
          ),
        );
      },
    );
  }
}