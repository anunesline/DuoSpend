import 'package:flutter/material.dart';

import '../../../../core/context/wallet_context.dart';
import '../../../../shared/knowledge/products/product_repository.dart';
import '../../../consumers/presentation/controllers/consumer_controller.dart';
import '../../../shopping/presentation/controllers/shopping_controller.dart';
import '../../../transactions/presentation/controllers/purchase_controller.dart';
import '../../../transactions/presentation/pages/new_transaction_page.dart';
import '../controllers/home_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/transactions_preview.dart';
import '../widgets/wallet_card.dart';
import '../widgets/wallet_view_switcher.dart';

class HomePage extends StatefulWidget {
  final WalletContext walletContext;
  final ShoppingController shoppingController;
  final ConsumerController consumerController;
  final PurchaseController purchaseController;
  final ProductRepository productRepository;

  const HomePage({
    super.key,
    required this.walletContext,
    required this.shoppingController,
    required this.consumerController,
    required this.purchaseController,
    required this.productRepository,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController controller;

  @override
  void initState() {
    super.initState();

    controller = HomeController(
      walletContext: widget.walletContext,
    );

    _loadHome();
  }

  Future<void> _loadHome() async {
    await controller.loadHome();
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
          productRepository: widget.productRepository,
        ),
      ),
    );

    await _loadHome();
  }

  void _changeWalletView(bool selectShared) {
    final currentWallet = controller.wallet;

    if (currentWallet == null) {
      return;
    }

    if (currentWallet.isShared == selectShared) {
      return;
    }

    for (final wallet in controller.wallets) {
      if (wallet.isShared == selectShared) {
        controller.selectWalletById(wallet.id);
        return;
      }
    }
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
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final wallet = controller.wallet;
        final hasSharedWallet = controller.wallets.any(
          (availableWallet) => availableWallet.isShared,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('DuoSpend'),
            centerTitle: true,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: wallet == null
                ? null
                : _openNewTransactionPage,
            child: const Icon(Icons.add),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${controller.userName}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                WalletViewSwitcher(
                  isSharedSelected: wallet?.isShared ?? false,
                  sharedEnabled: hasSharedWallet,
                  onChanged: _changeWalletView,
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
                  walletName: wallet?.name ?? 'Nenhuma carteira',
                  balance: wallet?.balance ?? 0,
                  isShared: wallet?.isShared ?? false,
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