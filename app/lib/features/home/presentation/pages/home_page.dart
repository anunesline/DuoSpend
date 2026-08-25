import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/context/wallet_context.dart';
import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../../shared/knowledge/products/product_repository.dart';
import '../../../consumers/presentation/controllers/consumer_controller.dart';
import '../../../shopping/presentation/controllers/shopping_controller.dart';
import '../../../transactions/domain/purchase/services/balance_summary.dart';
import '../../../transactions/presentation/controllers/purchase_controller.dart';
import '../../../transactions/presentation/controllers/transaction_controller.dart';
import '../../../transactions/presentation/pages/financial_calendar_page.dart';
import '../../../transactions/presentation/pages/history_page.dart';
import '../../../transactions/presentation/pages/new_transaction_page.dart';
import '../../../wallet/presentation/pages/credit_cards_page.dart';
import '../controllers/home_controller.dart';
import '../widgets/balance_card.dart';
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

  Future<void> _openCreditCardsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditCardsPage(
          individualWallets: controller.individualWallets,
        ),
      ),
    );

    await _loadHome();
  }

  Future<void> _openWalletSelector() async {
    if (!controller.hasWallets) {
      await _showCreateIndividualWalletDialog();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final wallets = controller.wallets;
        final selectedWalletId = controller.selectedWalletId;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text(
                    'Suas carteiras',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Escolha qual carteira deseja visualizar.',
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: wallets.length,
                    itemBuilder: (context, index) {
                      final wallet = wallets[index];
                      final isSelected =
                          wallet.id == selectedWalletId;

                      return ListTile(
                        leading: Icon(
                          wallet.isShared
                              ? Icons.groups_rounded
                              : Icons.account_balance_wallet_rounded,
                        ),
                        title: Text(wallet.name),
                        subtitle: Text(
                          wallet.isShared
                              ? 'Compartilhada'
                              : 'Individual',
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded)
                            : null,
                        onTap: () {
                          controller.selectWallet(wallet);
                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.credit_card_rounded),
                  title: const Text('Cartões e faturas'),
                  subtitle: const Text(
                    'Gerencie cartões, limites e pagamentos.',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openCreditCardsPage();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_rounded),
                  title: const Text('Nova carteira'),
                  subtitle: const Text(
                    'Adicione outra conta ou carteira individual.',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showCreateIndividualWalletDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateIndividualWalletDialog() async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0,00');

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nova carteira'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Ex.: Banco Inter',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Saldo atual',
                  prefixText: 'R\$ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );

    if (shouldCreate != true || !mounted) {
      nameController.dispose();
      balanceController.dispose();
      return;
    }

    final name = nameController.text.trim();
    final balance = double.tryParse(
      balanceController.text
          .trim()
          .replaceAll('.', '')
          .replaceAll(',', '.'),
    );

    nameController.dispose();
    balanceController.dispose();

    if (name.isEmpty || balance == null) {
      _showMessage('Informe um nome e um saldo válido.');
      return;
    }

    final createdWallet = await controller.createIndividualWallet(
      name: name,
      initialBalance: balance,
    );

    if (!mounted) {
      return;
    }

    if (createdWallet == null) {
      _showMessage(
        controller.errorMessage ??
            'Não foi possível criar a carteira.',
      );
      return;
    }

    _showMessage('Carteira criada.');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
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

  Future<void> _openFinancialCalendarPage() async {
    final wallet = controller.wallet;

    if (wallet == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinancialCalendarPage(
          wallet: wallet,
          transactions: controller.transactions,
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

  Widget _buildSharedBalanceRow(BalanceSummary summary) {
    IconData icon;
    Color color;
    String subtitle;

    if (summary.hasCredit) {
      icon = Icons.call_received_rounded;
      color = DuoColors.success;
      subtitle =
          'Você tem ${_formatMoney(summary.amountToReceive)} para receber';
    } else if (summary.hasDebt) {
      icon = Icons.call_made_rounded;
      color = DuoColors.error;
      subtitle =
          'Você deve ${_formatMoney(summary.amountToPay)} ao parceiro';
    } else {
      icon = Icons.check_circle_rounded;
      color = DuoColors.primaryLight;
      subtitle = 'Nenhum acerto pendente';
    }

    return _QuickAccessRow(
      icon: icon,
      iconColor: color,
      title: 'Saldo entre vocês',
      subtitle: subtitle,
      onTap: _openHistoryPage,
    );
  }

  String _formatMoney(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    return formatter.format(value);
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

        final quickAccessRows = <Widget>[
          if (wallet != null)
            _QuickAccessRow(
              icon: Icons.calendar_month_rounded,
              iconColor: DuoColors.primaryLight,
              title: 'Calendário financeiro',
              subtitle: 'Saldo previsto e próximos compromissos',
              onTap: _openFinancialCalendarPage,
            ),
          if (hasConnectedPartner &&
              controller.hasPendingSharedConfirmations)
            _QuickAccessRow(
              icon: Icons.pending_actions_rounded,
              iconColor: DuoColors.warning,
              title: 'Pendências',
              subtitle: pendingConfirmationCount == 1
                  ? '1 confirmação aguardando'
                  : '$pendingConfirmationCount confirmações aguardando',
              onTap: _openHistoryPage,
            ),
          if (hasConnectedPartner && controller.balanceSummary != null)
            _buildSharedBalanceRow(controller.balanceSummary!),
        ];

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
                            income: controller.totalIncome,
                            expense: controller.totalExpense,
                          ),
                          if (quickAccessRows.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _QuickAccessCard(rows: quickAccessRows),
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
                            onTap: _openWalletSelector,
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
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Duo',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: DuoColors.textPrimary,
                    letterSpacing: -.6,
                  ),
                ),
                TextSpan(
                  text: 'Spend',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: DuoColors.primaryLight,
                    letterSpacing: -.6,
                  ),
                ),
              ],
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

class _QuickAccessCard extends StatelessWidget {
  final List<Widget> rows;

  const _QuickAccessCard({
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: DuoColors.divider,
              ),
          ],
        ],
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickAccessRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DuoColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                size: 20,
              ),
            ],
          ),
        ),
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
