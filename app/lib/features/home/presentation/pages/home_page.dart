import 'package:flutter/material.dart';

import '../../../../core/context/wallet_context.dart';
import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../../shared/knowledge/products/product_repository.dart';
import '../../../consumers/presentation/controllers/consumer_controller.dart';
import '../../../shopping/presentation/controllers/shopping_controller.dart';
import '../../../transactions/presentation/controllers/purchase_controller.dart';
import '../../../transactions/presentation/controllers/transaction_controller.dart';
import '../../../transactions/presentation/pages/history_page.dart';
import '../../../transactions/presentation/pages/new_transaction_page.dart';
import '../controllers/home_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/shared_balance_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/transactions_preview.dart';
import '../widgets/wallet_card.dart';

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
  late final TransactionController transactionController;

  @override
  void initState() {
    super.initState();

    controller = HomeController(
      walletContext: widget.walletContext,
    );

    transactionController = TransactionController();

    _loadHome();
  }

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Bom dia';
    }

    if (hour >= 12 && hour < 18) {
      return 'Boa tarde';
    }

    return 'Boa noite';
  }

  String get _greetingEmoji {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return '☀️';
    }

    if (hour >= 12 && hour < 18) {
      return '🌤️';
    }

    return '🌙';
  }

  String get _formattedDate {
    const weekDays = [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ];

    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    final now = DateTime.now();

    return '${weekDays[now.weekday - 1]}, '
        '${now.day} de ${months[now.month - 1]}';
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
          walletContext: widget.walletContext,
          walletId: wallet.id,
          consumerController: widget.consumerController,
          purchaseController: widget.purchaseController,
          productRepository: widget.productRepository,
        ),
      ),
    );

    await _loadHome();
  }

  Future<void> _openHistoryPage() async {
    final wallet = controller.wallet;
    final currentUserId = controller.user?.uid;

    if (wallet == null ||
        currentUserId == null ||
        currentUserId.isEmpty) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryPage(
          wallet: wallet,
          transactions: controller.transactions,
          transactionController: transactionController,
          currentUserId: currentUserId,
        ),
      ),
    );

    await _loadHome();
  }

  void _toggleWalletContext() {
    if (!controller.hasConnectedPartner) {
      return;
    }

    if (controller.isSharedWalletSelected) {
      for (final wallet in controller.individualWallets) {
        controller.selectWalletById(wallet.id);
        return;
      }

      return;
    }

    final sharedWallet = controller.connectedSharedWallet;

    if (sharedWallet == null) {
      return;
    }

    controller.selectWalletById(sharedWallet.id);
  }

  @override
  void dispose() {
    transactionController.dispose();
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final wallet = controller.wallet;
        final hasConnectedPartner = controller.hasConnectedPartner;
        final pendingConfirmationCount =
            controller.pendingSharedConfirmationCount;

        return Scaffold(
          backgroundColor: DuoColors.background,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: wallet == null
              ? null
              : _NewTransactionButton(
                  onPressed: _openNewTransactionPage,
                ),
          body: controller.isLoading
              ? const _PremiumLoadingState()
              : SafeArea(
                  child: RefreshIndicator(
                    color: DuoColors.primary,
                    backgroundColor: DuoColors.surface,
                    onRefresh: _loadHome,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        112,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HomeTopBar(
                            isSharedSelected:
                                controller.isSharedWalletSelected,
                            hasConnectedPartner: hasConnectedPartner,
                            onToggleWallet: _toggleWalletContext,
                          ),
                          const SizedBox(height: 24),
                          _GreetingBlock(
                            greeting: _greeting,
                            userName: controller.userName,
                            emoji: _greetingEmoji,
                            date: _formattedDate,
                          ),
                          const SizedBox(height: 22),
                          BalanceCard(
                            balance: wallet?.balance ?? 0,
                          ),
                          const SizedBox(height: 16),
                          SummaryCard(
                            income: controller.totalIncome,
                            expense: controller.totalExpense,
                          ),
                          if (hasConnectedPartner &&
                              controller
                                  .hasPendingSharedConfirmations) ...[
                            const SizedBox(height: 20),
                            _PendingConfirmationsCard(
                              count: pendingConfirmationCount,
                              onTap: _openHistoryPage,
                            ),
                          ],
                          if (hasConnectedPartner &&
                              controller.balanceSummary != null) ...[
                            const SizedBox(height: 20),
                            SharedBalanceCard(
                              summary: controller.balanceSummary!,
                            ),
                          ],
                          const SizedBox(height: 28),
                          const _SectionTitle(
                            title: 'Carteira',
                          ),
                          const SizedBox(height: 14),
                          WalletCard(
                            walletName:
                                wallet?.name ?? 'Nenhuma carteira',
                            balance: wallet?.balance ?? 0,
                            isShared:
                                wallet?.isShared ?? false,
                          ),
                          const SizedBox(height: 28),
                          _SectionTitle(
                            title: 'Últimas movimentações',
                            actionLabel: 'Ver todas',
                            onAction: wallet == null
                                ? null
                                : _openHistoryPage,
                          ),
                          const SizedBox(height: 14),
                          TransactionsPreview(
                            transactions:
                                controller.transactions,
                            onViewAll: wallet == null
                                ? null
                                : _openHistoryPage,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  final bool isSharedSelected;
  final bool hasConnectedPartner;
  final VoidCallback onToggleWallet;

  const _HomeTopBar({
    required this.isSharedSelected,
    required this.hasConnectedPartner,
    required this.onToggleWallet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'DuoSpend',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: DuoColors.textPrimary,
              letterSpacing: -.6,
            ),
          ),
        ),
        if (hasConnectedPartner)
          _WalletContextChip(
            label: isSharedSelected ? 'Eu' : 'Nós',
            icon: isSharedSelected
                ? Icons.person_rounded
                : Icons.group_rounded,
            onTap: onToggleWallet,
          ),
      ],
    );
  }
}

class _WalletContextChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _WalletContextChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: DuoColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: DuoColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: DuoColors.primaryLight,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: DuoColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingBlock extends StatelessWidget {
  final String greeting;
  final String userName;
  final String emoji;
  final String date;

  const _GreetingBlock({
    required this.greeting,
    required this.userName,
    required this.emoji,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $userName $emoji',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: DuoColors.textPrimary,
            letterSpacing: -.35,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          date,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: DuoColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PendingConfirmationsCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _PendingConfirmationsCard({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final description = count == 1
        ? 'Uma despesa precisa da sua resposta.'
        : '$count despesas precisam da sua resposta.';

    return DuoCard(
      onTap: onTap,
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: DuoColors.warning.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: DuoColors.warning,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Aguardando confirmação',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: DuoColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 26,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DuoColors.warning,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: DuoColors.background,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DuoColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: DuoColors.textHint,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: DuoColors.textPrimary,
              letterSpacing: -.35,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: DuoColors.primaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _NewTransactionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NewTransactionButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: DuoColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: DuoColors.primaryGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 21,
                  color: DuoColors.textPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'Nova transação',
                  style: TextStyle(
                    color: DuoColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumLoadingState extends StatelessWidget {
  const _PremiumLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: DuoColors.primary,
      ),
    );
  }
}
