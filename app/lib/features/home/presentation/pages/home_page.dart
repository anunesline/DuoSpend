import 'package:flutter/material.dart';

import '../../../../core/context/wallet_context.dart';
import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../../shared/knowledge/products/product_repository.dart';
import '../../../budgets/presentation/pages/budgets_page.dart';
import '../../../consumers/presentation/controllers/consumer_controller.dart';
import '../../../financial_intelligence/presentation/pages/insights_page.dart';
import '../../../goals/presentation/pages/savings_goals_page.dart';
import '../../../household_routines/presentation/controllers/household_routines_controller.dart';
import '../../../household_routines/presentation/pages/household_routines_hub_page.dart';
import '../../../reports/presentation/pages/monthly_report_page.dart';
import '../../../shopping/presentation/controllers/shopping_controller.dart';
import '../../../transactions/domain/purchase/services/balance_summary.dart';
import '../../../transactions/presentation/controllers/purchase_controller.dart';
import '../../../transactions/presentation/controllers/transaction_controller.dart';
import '../../../transactions/presentation/pages/financial_calendar_page.dart';
import '../../../transactions/presentation/pages/history_page.dart';
import '../../../transactions/presentation/pages/new_transaction_page.dart';
import '../../../wallet/presentation/pages/credit_cards_page.dart';
import '../controllers/home_controller.dart';
import '../controllers/orbit_dashboard_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/orbit_insight_card.dart';
import '../widgets/orbit_month_summary.dart';
import '../widgets/transactions_preview.dart';
import '../widgets/wallet_card.dart';

class HomePage extends StatefulWidget {
  final WalletContext walletContext;
  final ShoppingController shoppingController;
  final ConsumerController consumerController;
  final PurchaseController purchaseController;
  final ProductRepository productRepository;
  final HouseholdRoutinesController householdRoutinesController;

  const HomePage({
    super.key,
    required this.walletContext,
    required this.shoppingController,
    required this.consumerController,
    required this.purchaseController,
    required this.productRepository,
    required this.householdRoutinesController,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController controller;
  late final OrbitDashboardController orbitController;
  late final TransactionController transactionController;

  @override
  void initState() {
    super.initState();
    controller = HomeController(walletContext: widget.walletContext);
    orbitController = OrbitDashboardController();
    transactionController = TransactionController();
    _loadHome();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Bom dia';
    if (hour >= 12 && hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String get _greetingEmoji {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '☀️';
    if (hour >= 12 && hour < 18) return '🌤️';
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
    return '${weekDays[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]}';
  }

  Future<void> _loadHome() async {
    await controller.loadHome();
    await _loadOrbitSummary();
  }

  Future<void> _loadOrbitSummary() async {
    final wallet = controller.wallet;
    if (wallet == null) return;
    await orbitController.load(
      wallet: wallet,
      transactions: controller.transactions,
    );
  }

  Future<void> _selectWallet(String walletId) async {
    controller.selectWalletById(walletId);
    await _loadOrbitSummary();
  }

  Future<void> _openCreditCardsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreditCardsPage(individualWallets: controller.individualWallets),
      ),
    );
    await _loadHome();
  }

  Future<void> _openWalletSelector() async {
    if (!controller.hasWallets) {
      await _showCreateIndividualWalletDialog();
      return;
    }
    String? selectedId;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
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
                subtitle: Text('Escolha qual carteira deseja visualizar.'),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = controller.wallets[index];
                    return ListTile(
                      leading: Icon(
                        wallet.isShared
                            ? Icons.groups_rounded
                            : Icons.account_balance_wallet_rounded,
                      ),
                      title: Text(wallet.name),
                      subtitle: Text(
                        wallet.isShared ? 'Compartilhada' : 'Individual',
                      ),
                      trailing: wallet.id == controller.selectedWalletId
                          ? const Icon(Icons.check_circle_rounded)
                          : null,
                      onTap: () {
                        selectedId = wallet.id;
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
                subtitle: const Text('Gerencie cartões, limites e pagamentos.'),
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
      ),
    );
    if (selectedId != null) await _selectWallet(selectedId!);
  }

  Future<void> _showCreateIndividualWalletDialog() async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0,00');
    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    if (shouldCreate != true || !mounted) {
      nameController.dispose();
      balanceController.dispose();
      return;
    }
    final name = nameController.text.trim();
    final balance = double.tryParse(
      balanceController.text.trim().replaceAll('.', '').replaceAll(',', '.'),
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
    if (!mounted) return;
    if (createdWallet == null) {
      _showMessage(
        controller.errorMessage ?? 'Não foi possível criar a carteira.',
      );
      return;
    }
    await _loadOrbitSummary();
    _showMessage('Carteira criada.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _openNewTransactionPage() async {
    final wallet = controller.wallet;
    if (wallet == null) return;
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

  Future<void> _openSavingsGoalsPage() async {
    final wallet = controller.wallet;
    final userId = controller.user?.uid;
    if (wallet == null || userId == null || userId.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavingsGoalsPage(
          contextWallet: wallet,
          individualWallets: controller.individualWallets,
          currentUserId: userId,
        ),
      ),
    );
    await _loadHome();
  }

  Future<void> _openBudgetsPage() async {
    final wallet = controller.wallet;
    final userId = controller.user?.uid;
    if (wallet == null || userId == null || userId.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetsPage(
          wallet: wallet,
          transactions: controller.transactions,
          currentUserId: userId,
        ),
      ),
    );
    await _loadHome();
  }

  Future<void> _openMonthlyReportPage() async {
    final wallet = controller.wallet;
    if (wallet == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MonthlyReportPage(
          wallet: wallet,
          transactions: controller.transactions,
          currentUserId: controller.user?.uid,
        ),
      ),
    );
    await _loadHome();
  }

  Future<void> _openInsightsPage() async {
    final wallet = controller.wallet;
    if (wallet == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InsightsPage(wallet: wallet)),
    );
  }

  Future<void> _openFinancialCalendarPage() async {
    final wallet = controller.wallet;
    if (wallet == null) return;
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
    final userId = controller.user?.uid;
    if (wallet == null || userId == null || userId.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryPage(
          wallet: wallet,
          transactions: controller.transactions,
          transactionController: transactionController,
          currentUserId: userId,
        ),
      ),
    );
    await _loadHome();
  }

  Future<void> _openHouseholdRoutinesPage() async {
    final userId = controller.user?.uid.trim();
    if (userId == null || userId.isEmpty) return;

    final sharedWallet = controller.connectedSharedWallet;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HouseholdRoutinesHubPage(
          controller: widget.householdRoutinesController,
          currentUserId: userId,
          sharedHouseholdId: sharedWallet?.id,
          sharedMemberIds: sharedWallet?.memberIds ?? const [],
        ),
      ),
    );
  }

  Future<void> _toggleWalletContext() async {
    if (!controller.hasConnectedPartner) return;
    if (controller.isSharedWalletSelected) {
      if (controller.individualWallets.isNotEmpty)
        await _selectWallet(controller.individualWallets.first.id);
      return;
    }
    final sharedWallet = controller.connectedSharedWallet;
    if (sharedWallet != null) await _selectWallet(sharedWallet.id);
  }

  Widget _buildSharedBalanceRow(BalanceSummary summary) {
    if (summary.hasCredit) {
      return _QuickAccessRow(
        icon: Icons.call_received_rounded,
        iconColor: DuoColors.success,
        title: 'Saldo entre vocês',
        subtitle:
            'Você tem R\$ ${summary.amountToReceive.toStringAsFixed(2).replaceAll('.', ',')} para receber',
        onTap: _openHistoryPage,
      );
    }
    if (summary.hasDebt) {
      return _QuickAccessRow(
        icon: Icons.call_made_rounded,
        iconColor: DuoColors.error,
        title: 'Saldo entre vocês',
        subtitle:
            'Você deve R\$ ${summary.amountToPay.toStringAsFixed(2).replaceAll('.', ',')} ao parceiro',
        onTap: _openHistoryPage,
      );
    }
    return _QuickAccessRow(
      icon: Icons.check_circle_rounded,
      iconColor: DuoColors.primaryLight,
      title: 'Saldo entre vocês',
      subtitle: 'Nenhum acerto pendente',
      onTap: _openHistoryPage,
    );
  }

  @override
  void dispose() {
    transactionController.dispose();
    orbitController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, orbitController]),
      builder: (context, _) {
        final wallet = controller.wallet;
        final hasPartner = controller.hasConnectedPartner;
        final sharedRows = <Widget>[
          if (hasPartner && controller.hasPendingSharedConfirmations)
            _QuickAccessRow(
              icon: Icons.pending_actions_rounded,
              iconColor: DuoColors.warning,
              title: 'Pendências',
              subtitle: controller.pendingSharedConfirmationCount == 1
                  ? '1 confirmação aguardando'
                  : '${controller.pendingSharedConfirmationCount} confirmações aguardando',
              onTap: _openHistoryPage,
            ),
          if (hasPartner && controller.balanceSummary != null)
            _buildSharedBalanceRow(controller.balanceSummary!),
        ];

        return Scaffold(
          backgroundColor: DuoColors.background,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: wallet == null
              ? null
              : _NewTransactionButton(onPressed: _openNewTransactionPage),
          body: controller.isLoading
              ? const _PremiumLoadingState()
              : SafeArea(
                  child: RefreshIndicator(
                    color: DuoColors.primary,
                    backgroundColor: DuoColors.surface,
                    onRefresh: _loadHome,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HomeTopBar(
                            isSharedSelected: controller.isSharedWalletSelected,
                            hasConnectedPartner: hasPartner,
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
                          if (controller.isSharedWalletSelected) ...[
                            _SharedContextBanner(
                              walletName:
                                  wallet?.name ?? 'Carteira compartilhada',
                            ),
                            const SizedBox(height: 14),
                          ],
                          BalanceCard(
                            balance: wallet?.balance ?? 0,
                            income: controller.totalIncome,
                            expense: controller.totalExpense,
                          ),
                          if (wallet != null) ...[
                            const SizedBox(height: 18),
                            OrbitInsightCard(
                              wallet: wallet,
                              onTap: _openInsightsPage,
                            ),
                            const SizedBox(height: 26),
                            _SectionTitle(
                              title: controller.isSharedWalletSelected
                                  ? 'Nosso mês'
                                  : 'Seu mês',
                            ),
                            const SizedBox(height: 12),
                            OrbitMonthSummary(
                              summary: orbitController.summary,
                              isLoading: orbitController.isLoading,
                              onBudgetTap: _openBudgetsPage,
                              onGoalTap: _openSavingsGoalsPage,
                              onInvoiceTap: _openCreditCardsPage,
                            ),
                            if (sharedRows.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _QuickAccessCard(rows: sharedRows),
                            ],
                            const SizedBox(height: 26),
                            _SectionTitle(
                              title: controller.isSharedWalletSelected
                                  ? 'Acompanhar juntos'
                                  : 'Explorar',
                              actionLabel: 'Insights',
                              onAction: _openInsightsPage,
                            ),
                            const SizedBox(height: 12),
                            _ExploreGrid(
                              onReport: _openMonthlyReportPage,
                              onCalendar: _openFinancialCalendarPage,
                              onWallet: _openWalletSelector,
                              onCards: _openCreditCardsPage,
                              onRoutines: _openHouseholdRoutinesPage,
                            ),
                          ],
                          const SizedBox(height: 28),
                          _SectionTitle(
                            title: 'Últimas movimentações',
                            actionLabel: 'Ver todas',
                            onAction: wallet == null ? null : _openHistoryPage,
                          ),
                          const SizedBox(height: 14),
                          TransactionsPreview(
                            transactions: controller.transactions,
                            onViewAll: wallet == null ? null : _openHistoryPage,
                          ),
                          if (wallet == null) ...[
                            const SizedBox(height: 28),
                            const _SectionTitle(title: 'Carteira'),
                            const SizedBox(height: 14),
                            WalletCard(
                              walletName: 'Nenhuma carteira',
                              balance: 0,
                              isShared: false,
                              onTap: _openWalletSelector,
                            ),
                          ],
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
  Widget build(BuildContext context) => Row(
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
          icon: isSharedSelected ? Icons.person_rounded : Icons.group_rounded,
          onTap: onToggleWallet,
        ),
    ],
  );
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
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: DuoColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: DuoColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: DuoColors.primaryLight),
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
  Widget build(BuildContext context) => Column(
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

class _SharedContextBanner extends StatelessWidget {
  final String walletName;
  const _SharedContextBanner({required this.walletName});

  @override
  Widget build(BuildContext context) => DuoCard(
    borderRadius: 18,
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    gradient: DuoColors.heroGradient,
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: DuoColors.primary.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.groups_rounded,
            color: DuoColors.primaryLight,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Visão de vocês',
                style: TextStyle(
                  color: DuoColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                walletName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DuoColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _QuickAccessCard extends StatelessWidget {
  final List<Widget> rows;
  const _QuickAccessCard({required this.rows});

  @override
  Widget build(BuildContext context) => DuoCard(
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
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
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

class _ExploreGrid extends StatelessWidget {
  final VoidCallback onReport;
  final VoidCallback onCalendar;
  final VoidCallback onWallet;
  final VoidCallback onCards;
  final VoidCallback onRoutines;
  const _ExploreGrid({
    required this.onReport,
    required this.onCalendar,
    required this.onWallet,
    required this.onCards,
    required this.onRoutines,
  });

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 1.65,
    children: [
      _ExploreTile(
        icon: Icons.insights_rounded,
        label: 'Relatório',
        onTap: onReport,
      ),
      _ExploreTile(
        icon: Icons.calendar_month_rounded,
        label: 'Calendário',
        onTap: onCalendar,
      ),
      _ExploreTile(
        icon: Icons.home_work_rounded,
        label: 'Rotinas da Casa',
        onTap: onRoutines,
      ),
      _ExploreTile(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Carteiras',
        onTap: onWallet,
      ),
      _ExploreTile(
        icon: Icons.credit_card_rounded,
        label: 'Cartões',
        onTap: onCards,
      ),
    ],
  );
}

class _ExploreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ExploreTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => DuoCard(
    borderRadius: 18,
    padding: EdgeInsets.zero,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: DuoColors.primaryLight, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DuoColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
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

class _NewTransactionButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _NewTransactionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) => Container(
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
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 21, color: DuoColors.textPrimary),
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

class _PremiumLoadingState extends StatelessWidget {
  const _PremiumLoadingState();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: DuoColors.primary));
}
