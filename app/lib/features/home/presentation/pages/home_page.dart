import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
import '../../domain/models/orbit_dashboard_summary.dart';
import '../controllers/home_controller.dart';
import '../controllers/orbit_dashboard_controller.dart';
import '../widgets/orbit_insight_card.dart';

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
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
    final shortcutScrollController = ScrollController();
    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: DuoColors.surface,
        showDragHandle: true,
        builder: (sheetContext) => LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: constraints.maxHeight,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const ListTile(
                      title: Text(
                        'Finanças',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('Acesse os principais recursos financeiros.'),
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: shortcutScrollController,
                        thumbVisibility: true,
                        thickness: 3,
                        radius: const Radius.circular(99),
                        child: ListView(
                          controller: shortcutScrollController,
                          padding: EdgeInsets.zero,
                          children: [
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
                      icon: Icons.history_rounded,
                      label: 'Histórico',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openHistoryPage();
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
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      shortcutScrollController.dispose();
    }
  }

  Future<void> _showQuickCreateMenu() async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final bottomGap = MediaQuery.paddingOf(context).bottom + 72;

    final result = await showMenu<String>(
      context: context,
      color: DuoColors.orbitSurface,
      elevation: 18,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: DuoColors.orbitBorder),
      ),
      position: RelativeRect.fromLTRB(
        16,
        overlay.size.height - bottomGap - 290,
        16,
        bottomGap,
      ),
      items: const [
        PopupMenuItem(
          value: 'transaction',
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _QuickCreateMenuItem(
            icon: Icons.receipt_long_rounded,
            label: 'Nova transação',
          ),
        ),
        PopupMenuItem(
          value: 'income',
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _QuickCreateMenuItem(
            icon: Icons.trending_up_rounded,
            label: 'Receita',
          ),
        ),
        PopupMenuItem(
          value: 'scan',
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _QuickCreateMenuItem(
            icon: Icons.document_scanner_outlined,
            label: 'Escanear compra',
          ),
        ),
        PopupMenuItem(
          value: 'goal',
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _QuickCreateMenuItem(
            icon: Icons.savings_outlined,
            label: 'Nova meta',
          ),
        ),
        PopupMenuItem(
          value: 'task',
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _QuickCreateMenuItem(
            icon: Icons.task_alt_rounded,
            label: 'Nova tarefa',
          ),
        ),
      ],
    );

    if (!mounted || result == null) return;
    if (result == 'transaction' || result == 'income') {
      await _openNewTransactionPage();
    } else if (result == 'scan') {
      await _openReceiptScanner();
    } else if (result == 'goal') {
      await _openSavingsGoalsPage();
    } else if (result == 'task') {
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
        final summary = orbitController.summary;

        return Scaffold(
          backgroundColor: DuoColors.orbitBackground,
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
              : Stack(
                  children: [
                    const Positioned.fill(child: _OrbitBackdrop()),
                    SafeArea(
                      bottom: false,
                      child: RefreshIndicator(
                        color: const Color(0xFF9EEA8A),
                        backgroundColor: const Color(0xFF111622),
                        onRefresh: _loadHome,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _OrbitHeader(
                                photoUrl: controller.userPhotoUrl,
                                onNotifications: () => _showMessage(
                                  'Você não tem novas notificações.',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: _GreetingBlock(
                                  greeting: _greeting,
                                  userName: controller.userName,
                                  emoji: _greetingEmoji,
                                  subtitle: _questionCopy,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _BalanceCard(
                                balance: wallet?.balance ?? 0,
                                income: controller.totalIncome,
                                expense: controller.totalExpense,
                              ),
                              const SizedBox(height: 12),
                              _BudgetCard(
                                budget: summary.budget,
                                isLoading: orbitController.isLoading,
                                onTap: _openBudgetsPage,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InvoiceCard(
                                      invoice: summary.invoice,
                                      onTap: _openFinancialCalendarPage,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _GoalCard(
                                      goal: summary.goal,
                                      onTap: _openSavingsGoalsPage,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _SectionTitle(
                                title: 'Insights da IA',
                                actionLabel: wallet == null ? null : 'Ver tudo',
                                onAction: wallet == null ? null : _openInsightsPage,
                              ),
                              const SizedBox(height: 12),
                              if (wallet != null)
                                OrbitInsightCard(
                                  wallet: wallet,
                                  onTap: _openInsightsPage,
                                )
                              else
                                const _EmptyInsightCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

String _money(double value) => NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(value);

class _OrbitHeader extends StatelessWidget {
  final String? photoUrl;
  final VoidCallback onNotifications;

  const _OrbitHeader({required this.photoUrl, required this.onNotifications});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: DuoColors.orbitBorder,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              backgroundColor: DuoColors.orbitSurface,
              backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
              child: hasPhoto
                  ? null
                  : const Icon(
                      Icons.person_rounded,
                      size: 19,
                      color: DuoColors.orbitTextSecondary,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _OrbitMark(),
                    SizedBox(width: 6),
                    Text(
                      'Orbit',
                      style: TextStyle(
                        color: DuoColors.orbitTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3),
                Text(
                  'Organize. Planeje. Conquiste.',
                  style: TextStyle(
                    color: DuoColors.orbitTextSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .3,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onNotifications,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: DuoColors.orbitTextPrimary,
                  size: 22,
                ),
              ),
              const Positioned(
                right: 3,
                top: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: DuoColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 8, height: 8),
                ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitMark extends StatelessWidget {
  const _OrbitMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA782FF), Color(0xFF72B9FF), DuoColors.success],
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: DuoColors.orbitBackground,
          shape: BoxShape.circle,
        ),
      ),
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
            color: DuoColors.orbitTextPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: DuoColors.orbitTextSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _OrbitCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const _OrbitCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xE8111622),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DuoColors.orbitBorder),
            boxShadow: DuoColors.orbitCardShadow,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final monthResult = income - expense;
    return _OrbitCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 56,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo disponível',
                      style: TextStyle(
                        color: DuoColors.orbitTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _money(balance),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DuoColors.orbitTextPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.visibility_outlined,
                          color: DuoColors.orbitTextSecondary,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          monthResult >= 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: monthResult >= 0
                              ? DuoColors.success
                              : const Color(0xFFFF8A8A),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Resultado do mês ${_money(monthResult.abs())}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: monthResult >= 0
                                  ? DuoColors.success
                                  : const Color(0xFFFF8A8A),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 12),
              color: DuoColors.orbitBorder,
            ),
            Expanded(
              flex: 44,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo previsto',
                      style: TextStyle(
                        color: DuoColors.orbitTextSecondary,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _money(balance),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DuoColors.orbitTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _ProgressBar(
                      progress: .72,
                      color: DuoColors.success,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final OrbitBudgetSummary? budget;
  final bool isLoading;
  final VoidCallback onTap;

  const _BudgetCard({
    required this.budget,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final current = budget;
    final progress = current?.progress ?? 0;
    final percentage = (progress * 100).round();
    final month = DateFormat('MMMM', 'pt_BR').format(DateTime.now());

    return _OrbitCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _IconTile(
            icon: Icons.pie_chart_rounded,
            color: DuoColors.orbitAccent,
            size: 36,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Orçamento de $month',
                  style: const TextStyle(
                    color: DuoColors.orbitTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoading
                      ? 'Carregando...'
                      : current == null
                          ? 'Nenhum orçamento ativo'
                          : '${_money(current.spentAmount)} de ${_money(current.limitAmount)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DuoColors.orbitTextSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _ProgressBar(
                  progress: progress,
                  color: DuoColors.orbitAccent,
                  height: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$percentage%',
            style: const TextStyle(
              color: DuoColors.success,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final OrbitInvoiceSummary? invoice;
  final VoidCallback onTap;

  const _InvoiceCard({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final current = invoice;
    final today = DateTime.now();
    final days = current == null
        ? null
        : DateUtils.dateOnly(current.dueDate)
            .difference(DateUtils.dateOnly(today))
            .inDays;
    final countLabel = current?.invoiceCount.toString() ?? '—';
    final title = current == null
        ? 'Nenhuma conta próxima'
        : current.invoiceCount == 1
            ? 'conta a vencer'
            : 'contas a vencer';
    final detail = current == null
        ? 'Calendário em dia'
        : days == 0
            ? 'Hoje: ${_money(current.total)}'
            : days == 1
                ? 'Amanhã: ${_money(current.total)}'
                : 'Em ${days ?? 0} dias: ${_money(current.total)}';

    return _OrbitCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF38BDF8),
            size: 32,
            borderRadius: 8,
          ),
          const SizedBox(height: 10),
          Text(
            countLabel,
            style: const TextStyle(
              color: DuoColors.orbitTextPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DuoColors.orbitTextSecondary,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DuoColors.orbitTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final OrbitGoalSummary? goal;
  final VoidCallback onTap;

  const _GoalCard({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final current = goal;
    final progress = current?.progress ?? 0;
    return _OrbitCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(
            icon: Icons.track_changes_rounded,
            color: DuoColors.success,
            size: 32,
            borderRadius: 8,
          ),
          const SizedBox(height: 10),
          Text(
            current == null ? 'Sem meta ativa' : 'Meta em andamento',
            style: const TextStyle(
              color: DuoColors.orbitTextSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            current?.name ?? 'Nenhuma meta ativa',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DuoColors.orbitTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            current == null ? '—' : '${(progress * 100).round()}% concluído',
            style: const TextStyle(
              color: DuoColors.orbitTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _ProgressBar(progress: progress, color: DuoColors.success, height: 5),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double borderRadius;
  final double? iconSize;

  const _IconTile({
    required this.icon,
    required this.color,
    this.size = 34,
    this.borderRadius = 10,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(icon, color: color, size: iconSize ?? (size == 32 ? 18 : 20)),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color color;

  final double height;

  const _ProgressBar({
    required this.progress,
    required this.color,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: DuoColors.orbitBorder,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _IconTile(
          icon: Icons.bolt_rounded,
          color: DuoColors.orbitAccent,
          size: 28,
          borderRadius: 8,
          iconSize: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: DuoColors.orbitTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: DuoColors.orbitAccent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyInsightCard extends StatelessWidget {
  const _EmptyInsightCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 76,
      child: _OrbitCard(
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFCC66)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Conecte uma carteira para receber insights financeiros.',
                style: TextStyle(
                  color: Color(0xFF98A2B3),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitBackdrop extends StatelessWidget {
  const _OrbitBackdrop();

  @override
  Widget build(BuildContext context) {
    final heroHeight = MediaQuery.sizeOf(context).height * .35;
    return IgnorePointer(
      child: Stack(
        children: [
          Container(color: DuoColors.orbitBackground),
          Positioned(
            top: 0,
            left: -40,
            right: -20,
            height: heroHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(.15, -.15),
                  radius: .95,
                  colors: [
                    const Color(0xFFD24D3A).withValues(alpha: .17),
                    const Color(0xFF8F467A).withValues(alpha: .08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, DuoColors.orbitBackground],
                ),
              ),
            ),
          ),
          Positioned(
            top: heroHeight * .45,
            left: 0,
            right: 0,
            height: heroHeight * .55,
            child: CustomPaint(painter: _OrbitHorizonPainter()),
          ),
        ],
      ),
    );
  }
}

class _OrbitHorizonPainter extends CustomPainter {
  const _OrbitHorizonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x1FD9694E), Color(0x03080B12)],
      ).createShader(Offset.zero & size);
    final path = Path()
      ..moveTo(0, size.height * .64)
      ..lineTo(size.width * .14, size.height * .52)
      ..lineTo(size.width * .28, size.height * .61)
      ..lineTo(size.width * .46, size.height * .43)
      ..lineTo(size.width * .61, size.height * .58)
      ..lineTo(size.width * .76, size.height * .48)
      ..lineTo(size.width, size.height * .63)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      top: false,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: DuoColors.orbitSurface.withValues(alpha: .92),
              border: const Border(top: BorderSide(color: DuoColors.orbitBorder)),
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
                        icon: Icons.account_balance_wallet_rounded,
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
                Positioned(top: -16, child: _CreateButton(onTap: onCreate)),
              ],
            ),
          ),
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
    final color = active ? DuoColors.success : DuoColors.orbitTextSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: active
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: active ? DuoColors.success.withValues(alpha: .14) : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
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
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: onTap == null ? const Color(0xFF566070) : DuoColors.success,
        shape: BoxShape.circle,
        boxShadow: onTap == null
            ? null
            : const [
                BoxShadow(
                  color: Color(0x553DDC97),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Icon(Icons.add_rounded, color: Color(0xFF071109), size: 28),
        ),
      ),
    );
  }
}

class _QuickCreateMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickCreateMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: DuoColors.orbitAccent.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: DuoColors.orbitAccent, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: DuoColors.orbitTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
      child: CircularProgressIndicator(color: Color(0xFF9EEA8A)),
    );
  }
}
