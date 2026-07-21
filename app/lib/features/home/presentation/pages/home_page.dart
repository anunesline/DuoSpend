import 'package:flutter/material.dart';

import '../../../../core/context/wallet_context.dart';
import '../../../../shared/knowledge/products/product_repository.dart';
import '../../../consumers/presentation/controllers/consumer_controller.dart';
import '../../../shopping/presentation/controllers/shopping_controller.dart';
import '../../../transactions/presentation/controllers/purchase_controller.dart';
import '../../../transactions/presentation/pages/new_transaction_page.dart';
import '../controllers/home_controller.dart';
import 'partner_invites_page.dart';
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

  Future<void> _enableCoupleMode() async {
    final createdWallet = await controller.createSharedWallet();

    if (!mounted) {
      return;
    }

    if (createdWallet == null) {
      _showErrorMessage();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'A ${createdWallet.name} foi criada.',
        ),
      ),
    );
  }

  Future<void> _openPartnerInviteDialog() async {
    final emailController = TextEditingController();

    final invitedEmail = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Convidar parceiro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informe o e-mail que seu parceiro usará no DuoSpend.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'E-mail do parceiro',
                  hintText: 'parceiro@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  final normalizedEmail = value.trim();

                  if (normalizedEmail.isEmpty) {
                    return;
                  }

                  Navigator.of(dialogContext).pop(normalizedEmail);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final normalizedEmail = emailController.text.trim();

                if (normalizedEmail.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(normalizedEmail);
              },
              child: const Text('Enviar convite'),
            ),
          ],
        );
      },
    );

    emailController.dispose();

    if (invitedEmail == null || invitedEmail.isEmpty) {
      return;
    }

    final invite = await controller.sendPartnerInvite(
      invitedEmail: invitedEmail,
    );

    if (!mounted) {
      return;
    }

    if (invite == null) {
      _showErrorMessage();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Convite enviado para ${invite.invitedEmail}.',
        ),
      ),
    );
  }

  Future<void> _openPartnerInvitesPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PartnerInvitesPage(),
      ),
    );

    await _loadHome();
  }

  void _showErrorMessage() {
    final message =
        controller.errorMessage ?? 'Não foi possível concluir esta ação.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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
        final hasSharedWallet = controller.hasSharedWallet;

        return Scaffold(
          appBar: AppBar(
            title: const Text('DuoSpend'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Convites',
                icon: const Icon(Icons.mail_outline_rounded),
                onPressed: _openPartnerInvitesPage,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: wallet == null
                ? null
                : _openNewTransactionPage,
            child: const Icon(Icons.add),
          ),
          body: controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  onRefresh: _loadHome,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                        if (!hasSharedWallet) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: controller.isCreatingSharedWallet
                                  ? null
                                  : _enableCoupleMode,
                              icon: controller.isCreatingSharedWallet
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.favorite_outline,
                                    ),
                              label: Text(
                                controller.isCreatingSharedWallet
                                    ? 'Criando carteira...'
                                    : 'Usar em casal',
                              ),
                            ),
                          ),
                        ],
                        if (controller.canInvitePartner) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: controller.isSendingPartnerInvite
                                  ? null
                                  : _openPartnerInviteDialog,
                              icon: controller.isSendingPartnerInvite
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_add_alt_1_outlined,
                                    ),
                              label: Text(
                                controller.isSendingPartnerInvite
                                    ? 'Enviando convite...'
                                    : 'Convidar parceiro',
                              ),
                            ),
                          ),
                        ],
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
                ),
        );
      },
    );
  }
}