import 'package:flutter/material.dart';

import '../../../../core/context/wallet_context.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../../shared/knowledge/products/product_repository.dart';
import '../../../budgets/presentation/pages/budgets_page.dart';
import '../../../consumers/presentation/controllers/consumer_controller.dart';
import '../../../financial_intelligence/presentation/pages/insights_page.dart';
import '../../../goals/presentation/pages/savings_goals_page.dart';
import '../../../household_routines/presentation/controllers/household_routines_controller.dart';
import '../../../household_routines/presentation/pages/household_routines_hub_page.dart';
import '../../../receipt_scanner/domain/models/receipt_transaction_draft.dart';
import '../../../receipt_scanner/presentation/pages/receipt_scanner_page.dart';
import '../../../reports/presentation/pages/monthly_report_page.dart';
import '../../../shopping/presentation/controllers/shopping_controller.dart';
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

  String get _questionCopy {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Que tal começar o dia mais leve e com as finanças no controle?';
    if (hour < 18) return 'Como estão suas finanças hoje?';
    return 'Que tal fechar o dia com as finanças no controle?';
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
        builder: (_) => CreditCardsPage(
          individualWallets: controller.individualWallets,
        ),
      ),
    );
    await _loadHome();
  }

  Future<void> _openWalletSelector() async {
    if (!controller.hasWallets) {
      _showMessage('Crie uma carteira para começar.');
      return;
    }

    String? selectedId;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: DuoColors.surface,
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
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openCreditCardsPage();
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedId != null) await _selectWallet(selectedId!);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openNewTransactionPage({ReceiptTransactionDraft? draft}) async {
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
          receiptDraft: draft,
        ),
      ),
    );
    await _loadHome();
  }

  Future<void> _openReceiptScanner() async {
    final draft = await Navigator.push<ReceiptTransactionDraft>(
      context,
      MaterialPageRoute(builder: (_) => const ReceiptScannerPage()),
    );
    if (!mounted || draft == null) return;
    await _openNewTransactionPage(draft: draft);
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

  Future<void> _openFinanceHub() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: DuoColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Finanças',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                subtitle: Text('Acesse os principais recursos financeiros.'),
              ),
              _FinanceShortcut(
                icon: Icons.pie_chart_rounded,
                label: 'Orçamentos',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openBudgetsPage();
                },
              ),
              _FinanceShortcut(
                icon: Icons.savings_rounded,
                label: 'Metas',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openSavingsGoalsPage();
                },
              ),
              _FinanceShortcut(
                icon: Icons.credit_card_rounded,
                label: 'Cartões',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openCreditCardsPage();
                },
              ),
              _FinanceShortcut(
                icon: Icons.insights_rounded,
                label: 'Relatórios',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openMonthlyReportPage();
                },
              ),
              _FinanceShortcut(
                icon: Icons.calendar_month_rounded,
                label: 'Calendário',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openFinancialCalendarPage();
                },
              ),
              _FinanceShortcut(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Carteiras',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openWalletSelector();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showQuickCreateMenu() async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final result = await showMenu<String>(
      context: context,
      color: DuoColors.surface,
      elevation: 14,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: DuoColors.border),
      ),
      position: RelativeRect.fromLTRB(
        16,
        overlay.size.height - 330,
        overlay.size.width - 180,
        86,
      ),
      items: const [
        PopupMenuItem(
          value: 'transaction',
          child: _QuickCreateMenuItem(
            emoji: '💸',
            label: 'Nova transação',
          ),
        ),
        PopupMenuItem(
          value: 'income',
          child: _QuickCreateMenuItem(emoji: '💰', label: 'Receita'),
        ),
        PopupMenuItem(
          value: 'scan',
          child: _QuickCreateMenuItem(emoji: '🧾', label: 'Escanear compra'),
        ),
        PopupMenuItem(
          value: 'goal',
          child: _QuickCreateMenuItem(emoji: '🎯', label: 'Nova meta'),
        ),
        PopupMenuItem(
          value: 'task',
          child: _QuickCreateMenuItem(emoji: '✅', label: 'Nova tarefa'),
        ),
      ],
    );

    if (!mounted || result == null) return;

    switch (result) {
      case 'transaction':
      case 'income':
        await _openNewTransactionPage();
      case 'scan':
        await _openReceiptScanner();
      case 'goal':
        await _openSavingsGoalsPage();
      case 'task':
        await _openHouseholdRoutinesPage();
    }
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

        return Scaffold(
          backgroundColor: DuoColors.background,
          extendBody: true,
          bottomNavigationBar: _OrbitBottomNavigation(
            onHome: () {},
            onFinance: _openFinanceHub,
            onCreate: wallet == null ? null : _showQuickCreateMenu,
            onRoutines: _openHouseholdRoutinesPage,
            onAi: _openInsightsPage,
          ),
          body: controller.isLoading
              ? const _PremiumLoadingState()
              : SafeArea(
                  bottom: false,
                  child: RefreshIndicator(
                    color: DuoColors.success,
                    backgroundColor: DuoColors.surface,
                    onRefresh: _loadHome,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 124),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _OrbitHeader(
                            photoUrl: controller.userPhotoUrl,
                            onNotifications: () => _showMessage(
                              'Você não tem novas notificações.',
                            ),
                          ),
                          const SizedBox(height: 22),
                          _GreetingBlock(
                            greeting: _greeting,
                            userName: controller.userName,
                            emoji: _greetingEmoji,
                            subtitle: _questionCopy,
                          ),
                          const SizedBox(height: 22),
                          BalanceCard(
                            balance: wallet?.balance ?? 0,
                            income: controller.totalIncome,
                            expense: controller.totalExpense,
                          ),
                          if (wallet != null) ...[
                            const SizedBox(height: 14),
                            OrbitMonthSummary(
                              summary: orbitController.summary,
                              isLoading: orbitController.isLoading,
                              onBudgetTap: _openBudgetsPage,
                              onGoalTap: _openSavingsGoalsPage,
                              onInvoiceTap: _openCreditCardsPage,
                            ),
                            const SizedBox(height: 22),
                            _SectionTitle(
                              icon: Icons.bolt_rounded,
                              title: 'Insights da IA',
                              actionLabel: 'Ver tudo',
                              onAction: _openInsightsPage,
                            ),
                            const SizedBox(height: 10),
                            OrbitInsightCard(
                              wallet: wallet,
                              onTap: _openInsightsPage,
                            ),
                          ],
                          const SizedBox(height: 24),
                          _SectionTitle(
                            title: 'Últimas movimentações',
                            actionLabel: wallet == null ? null : 'Ver todas',
                            onAction: wallet == null ? null : _openHistoryPage,
                          ),
                          const SizedBox(height: 10),
                          TransactionsPreview(
                            transactions: controller.transactions,
                            onViewAll: wallet == null ? null : _openHistoryPage,
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

class _OrbitHeader extends StatelessWidget {
  final String? photoUrl;
  final VoidCallback onNotifications;

  const _OrbitHeader({
    required this.photoUrl,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: DuoColors.surfaceLight,
          backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
          child: hasPhoto
              ? null
              : const Icon(Icons.person_rounded, color: DuoColors.textSecondary),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'O',
                      style: TextStyle(color: DuoColors.success),
                    ),
                    TextSpan(
                      text: 'rbit',
                      style: TextStyle(color: DuoColors.textPrimary),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.9,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Organize. Planeje. Conquiste.',
                style: TextStyle(
                  color: DuoColors.textSecondary,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notificações',
              onPressed: onNotifications,
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: DuoColors.textPrimary,
                size: 27,
              ),
            ),
            const Positioned(
              right: 9,
              top: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: DuoColors.success,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 7, height: 7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GreetingBlock extends StatelessWidget {
  final String greeting;
  final String userName;
  final String emoji;
  final String subtitle;

  const _GreetingBlock({
    required this.greeting,
    required this.userName,
    required this.emoji,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $userName! $emoji',
          style: const TextStyle(
            color: DuoColors.textPrimary,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: DuoColors.textSecondary,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: DuoColors.primaryLight, size: 24),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
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
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _OrbitBottomNavigation extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onFinance;
  final VoidCallback? onCreate;
  final VoidCallback onRoutines;
  final VoidCallback onAi;

  const _OrbitBottomNavigation({
    required this.onHome,
    required this.onFinance,
    required this.onCreate,
    required this.onRoutines,
    required this.onAi,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: const Color(0xFF11141D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: DuoColors.border),
          boxShadow: DuoColors.softShadow,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Início',
                    active: true,
                    onTap: onHome,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.credit_card_rounded,
                    label: 'Finanças',
                    onTap: onFinance,
                  ),
                ),
                const Expanded(child: SizedBox()),
                Expanded(
                  child: _NavItem(
                    icon: Icons.task_alt_rounded,
                    label: 'Rotinas',
                    onTap: onRoutines,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.auto_awesome_rounded,
                    label: 'IA',
                    onTap: onAi,
                  ),
                ),
              ],
            ),
            Positioned(
              top: -10,
              child: _CreateButton(onTap: onCreate),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? DuoColors.success : DuoColors.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (active) ...[
              const SizedBox(height: 3),
              Container(
                width: 24,
                height: 2,
                decoration: BoxDecoration(
                  color: DuoColors.success,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _CreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: onTap == null ? DuoColors.textHint : const Color(0xFF3EEA72),
        shape: BoxShape.circle,
        boxShadow: onTap == null ? null : DuoColors.successGlow,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Icon(
            Icons.add_rounded,
            color: Color(0xFF071109),
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _QuickCreateMenuItem extends StatelessWidget {
  final String emoji;
  final String label;

  const _QuickCreateMenuItem({
    required this.emoji,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: DuoColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FinanceShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FinanceShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: DuoColors.primaryLight),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _PremiumLoadingState extends StatelessWidget {
  const _PremiumLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: DuoColors.success),
    );
  }
}
