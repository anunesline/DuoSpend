import 'package:flutter/material.dart';

import '../../../consumers/presentation/controllers/consumer_controller.dart';
import '../../../shopping/presentation/controllers/shopping_controller.dart';
import '../../../transactions/presentation/controllers/purchase_controller.dart';
import '../../../transactions/presentation/pages/new_transaction_page.dart';
import '../controllers/home_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/transactions_preview.dart';
import '../widgets/wallet_card.dart';

class HomePage extends StatefulWidget {
  final ShoppingController shoppingController;
  final ConsumerController consumerController;
  final PurchaseController purchaseController;

  const HomePage({
    super.key,
    required this.shoppingController,
    required this.consumerController,
    required this.purchaseController,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController controller = HomeController();

  @override
  void initState() {
    super.initState();
    _loadHomeAndConsumers();
  }

  Future<void> _loadHomeAndConsumers() async {
    await controller.loadHome();

    final wallet = controller.wallet;

    if (wallet == null) {
      return;
    }

    await widget.consumerController.initializeWallet(
      walletId: wallet.id,
    );
  }

  Future<void> _openNewTransactionPage() async {
    final wallet = controller.wallet;

    if (wallet == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewTransactionPage(
          walletId: wallet.id,
          consumerController: widget.consumerController,
          purchaseController: widget.purchaseController,
        ),
      ),
    );

    await _loadHomeAndConsumers();
  }

  Future<void> _testShoppingKnowledgeEngine() async {
    await widget.shoppingController.createItemFromNameForTest(
      'Leite integral',
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Produto aprendido: leite integral'),
      ),
    );
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Olá, Aline',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bem-vinda ao DuoSpend',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                BalanceCard(
                  balance: wallet?.balance ?? 0,
                ),
                const SizedBox(height: 20),
                SummaryCard(
                  income: controller.totalIncome,
                  expense: controller.totalExpense,
                ),
                const SizedBox(height: 20),
                WalletCard(
                  walletName: wallet?.name ?? 'Carteira Principal',
                  balance: wallet?.balance ?? 0,
                ),
                const SizedBox(height: 20),
                TransactionsPreview(
                  transactions: controller.transactions,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _testShoppingKnowledgeEngine,
                  icon: const Icon(
                    Icons.psychology_alt_outlined,
                  ),
                  label: const Text(
                    'Testar inteligência de produtos',
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