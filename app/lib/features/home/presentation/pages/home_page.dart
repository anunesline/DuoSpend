import '../controllers/home_controller.dart';

import 'package:flutter/material.dart';
import '../widgets/balance_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/wallet_card.dart';
import '../widgets/transactions_preview.dart';
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
  animation: controller,
  builder: (context, _) {
    final wallet = controller.wallet;
    return Scaffold(
      appBar: AppBar(
        title: const Text("DuoSpend"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
  onPressed: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const NewTransactionPage(),
    ),
  );

  await controller.loadHome();
},
  child: const Icon(Icons.add),
),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "👋 Olá, Aline",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              "Bem-vinda ao DuoSpend",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            SizedBox(height: 24),

            BalanceCard(
              balance: wallet?.balance ?? 0,
          ),

            SizedBox(height: 20),

            SummaryCard(
              income: controller.totalIncome,
              expense: controller.totalExpense,
),

            SizedBox(height: 20),

            WalletCard(
            walletName: wallet?.name ?? "Carteira Principal",
            balance: wallet?.balance ?? 0,
),

            SizedBox(height: 20),

            TransactionsPreview(),
          ],
        ),
           ),
    );
  },
);
  }
}