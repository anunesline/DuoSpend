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
import '../../../wallet/presentation/pages/wallet_details_page.dart';
import '../../domain/models/orbit_dashboard_summary.dart';
import '../controllers/home_controller.dart';
import '../controllers/orbit_dashboard_controller.dart';
import 'partner_invites_page.dart';
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
  bool _hasUnreadNotifications = false;

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

  Future<void> _openProfileMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: DuoColors.orbitSurface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Configurações',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                subtitle: Text('Conta, casal e preferências do Orbit.'),
              ),
              ListTile(
                leading: const Icon(Icons.group_add_rounded),
                title: const Text('Usar como casal'),
                subtitle: const Text('Envie ou acompanhe convites do parceiro.'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openCoupleSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Compartilhar Orbit'),
                subtitle: const Text('Disponível quando o app for publicado.'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMessage(
                    'O compartilhamento será ativado com o link oficial do Orbit.',
                  );
                },
              ),
              const ListTile(
                enabled: false,
                leading: Icon(Icons.contrast_rounded),
                title: Text('Aparência'),
                subtitle: Text('Tema claro em preparação.'),
              ),
              ListTile(
                leading: const Icon(Icons.restart_alt_rounded),
                title: const Text('Zerar app'),
                subtitle: const Text('Recurso protegido em preparação.'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMessage(
                    'O reset completo será habilitado quando puder apagar os dados com segurança.',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCoupleSettings() async {
    final emailController = TextEditingController();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: DuoColors.orbitSurface,
        showDragHandle: true,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text(
                    'Orbit a dois',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Convide seu parceiro ou veja convites recebidos.',
                  ),
                ),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail do parceiro',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      var selectedWallet = controller.wallet;
                      if (selectedWallet == null ||
                          !selectedWallet.isShared ||
                          !selectedWallet.canInvitePartner) {
                        selectedWallet = await controller.createSharedWallet();
                      }
                      if (!mounted || !sheetContext.mounted) return;
                      if (selectedWallet == null) {
                        _showMessage(
                          controller.errorMessage ??
                              'Não foi possível preparar o modo casal.',
                        );
                        return;
                      }
                      controller.selectWallet(selectedWallet);
                      final invite = await controller.sendPartnerInvite(
                        invitedEmail: emailController.text,
                      );
                      if (!mounted || !sheetContext.mounted) return;
                      if (invite == null) {
                        _showMessage(
                          controller.errorMessage ??
                              'Não foi possível enviar o convite.',
                        );
                        return;
                      }
                      Navigator.pop(sheetContext);
                      _showMessage('Convite enviado com sucesso.');
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Enviar convite'),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.mark_email_unread_rounded),
                  title: const Text('Convites recebidos'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PartnerInvitesPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      emailController.dispose();
    }
  }

  Future<void> _openNotifications() async {
    if (_hasUnreadNotifications) {
      setState(() => _hasUnreadNotifications = false);
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PartnerInvitesPage()),
    );
    if (mounted) await _loadHome();
  }

  Future<void> _openCreditCardsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditCardsPage(
          individualWallets: controller.individualWallets,
          onNewTransaction: () => _openNewTransactionPage(),
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

    if (selectedId != null) {
      await _selectWallet(selectedId!);
      if (!mounted) return;
      final wallet = controller.wallet;
      if (wallet == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => WalletDetailsPage(
            wallet: wallet,
            individualWallets: controller.individualWallets,
            currentUserId: controller.user?.uid,
            onAdd: () => _openNewTransactionPage(),
            onRoutines: _openHouseholdRoutinesPage,
          ),
        ),
      );
      if (mounted) await _loadHome();
    }
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

    final changed = await Navigator.push<bool>(
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
    if (changed == true) {
      await controller.refreshSelectedWallet();
    }
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

    final destination = await Navigator.push<BudgetDestination>(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetsPage(
          wallet: wallet,
          transactions: controller.transactions,
          currentUserId: userId,
          scopeWallets: [
            ...controller.individualWallets,
            ...controller.sharedWallets,
          ],
          navigationBuilder: (navigate) => SizedBox(
            height: 84 + MediaQuery.paddingOf(context).bottom,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _OrbitBottomNavigation(
                    financeActive: true,
                    onHome: () => navigate(BudgetDestination.home),
                    onFinance: () => navigate(BudgetDestination.finance),
                    onRoutines: () => navigate(BudgetDestination.routines),
                    onAi: () => navigate(BudgetDestination.ai),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.paddingOf(context).bottom + 20,
                  child: Center(
                    child: _CreateButton(
                      onTap: () => navigate(BudgetDestination.create),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (destination) {
      case BudgetDestination.finance:
        await _openFinanceHub();
      case BudgetDestination.create:
        await _showQuickCreateMenu();
      case BudgetDestination.routines:
        await _openHouseholdRoutinesPage();
      case BudgetDestination.ai:
        await _openInsightsPage();
      case BudgetDestination.home:
      case null:
        break;
    }
    if (mounted) await _loadHome();
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
    await controller.refreshSelectedWallet();
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
    var openWalletSelector = false;
    try {
      openWalletSelector = await showModalBottomSheet<bool>(
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
      ) ??
          false;
    } finally {
      shortcutScrollController.dispose();
    }

    if (openWalletSelector && mounted) {
      await _openWalletSelector();
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
        borderRadius: BorderRadius.circular(24),
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
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: _QuickCreateMenuItem(
            icon: Icons.receipt_long_rounded,
            label: 'Nova transação',
            color: DuoColors.success,
          ),
        ),
        PopupMenuItem(
          value: 'income',
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: _QuickCreateMenuItem(
            icon: Icons.trending_up_rounded,
            label: 'Receita',
            color: Color(0xFFFFD34D),
          ),
        ),
        PopupMenuItem(
          value: 'scan',
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: _QuickCreateMenuItem(
            icon: Icons.document_scanner_outlined,
            label: 'Escanear compra',
            color: Color(0xFF38BDF8),
          ),
        ),
        PopupMenuItem(
          value: 'goal',
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: _QuickCreateMenuItem(
            icon: Icons.savings_outlined,
            label: 'Nova meta',
            color: Color(0xFFFF6B6B),
          ),
        ),
        PopupMenuItem(
          value: 'task',
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: _QuickCreateMenuItem(
            icon: Icons.task_alt_rounded,
            label: 'Nova tarefa',
            color: Color(0xFFFFD34D),
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
        final size = MediaQuery.sizeOf(context);
        final isTablet = size.width >= 600;
        final horizontalPadding = isTablet ? 24.0 : 20.0;

        return Scaffold(
          backgroundColor: DuoColors.orbitBackground,
          extendBody: true,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: DuoColors.orbitBackground),
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _OrbitBackdrop(),
                ),
                RefreshIndicator(
                  color: DuoColors.success,
                  backgroundColor: DuoColors.orbitSurface,
                  onRefresh: _loadHome,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            48,
                            horizontalPadding,
                            16,
                          ),
                          child: _OrbitHeader(
                            photoUrl: controller.userPhotoUrl,
                            hasUnreadNotifications: _hasUnreadNotifications,
                            onProfile: _openProfileMenu,
                            onNotifications: _openNotifications,
                          ),
                        ),
                        if (controller.isLoading)
                          const SizedBox(
                            height: 360,
                            child: _PremiumLoadingState(),
                          )
                        else ...[
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              24,
                              horizontalPadding,
                              0,
                            ),
                            child: _GreetingBlock(
                              greeting: _greeting,
                              userName: controller.userName,
                              emoji: _greetingEmoji,
                              subtitle: _questionCopy,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: _BalanceCard(
                              balance: wallet?.balance ?? 0,
                              income: controller.totalIncome,
                              expense: controller.totalExpense,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: _BudgetCard(
                              budget: summary.budget,
                              isLoading: orbitController.isLoading,
                              onTap: _openBudgetsPage,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: Row(
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
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: _SectionTitle(
                              title: 'Insights da IA',
                              actionLabel: wallet == null ? null : 'Ver tudo',
                              onAction:
                                  wallet == null ? null : _openInsightsPage,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: wallet != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: OrbitInsightCard(
                                      wallet: wallet,
                                      onTap: _openInsightsPage,
                                    ),
                                  )
                                : const _EmptyInsightCard(),
                          ),
                          const SizedBox(height: 120),
                        ],
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _OrbitBottomNavigation(
                    onHome: () {},
                    onFinance: _openFinanceHub,
                    onRoutines: _openHouseholdRoutinesPage,
                    onAi: _openInsightsPage,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.paddingOf(context).bottom + 32,
                  child: Center(
                    child: _CreateButton(
                      onTap: wallet == null ? null : _showQuickCreateMenu,
                    ),
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

String _money(double value) => NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(value);

class _OrbitHeader extends StatelessWidget {
  final String? photoUrl;
  final bool hasUnreadNotifications;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  const _OrbitHeader({
    required this.photoUrl,
    required this.hasUnreadNotifications,
    required this.onProfile,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          InkWell(
            onTap: onProfile,
            customBorder: const CircleBorder(),
            child: Container(
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
              if (hasUnreadNotifications)
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
  final double borderRadius;

  const _OrbitCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xE8111622),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: DuoColors.orbitBorder),
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
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 56,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo disponível',
                      style: TextStyle(
                        color: DuoColors.orbitTextSecondary,
                        fontSize: 11,
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
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 40, color: DuoColors.orbitBorder),
              const SizedBox(width: 12),
              Expanded(
                flex: 44,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo previsto',
                      style: TextStyle(
                        color: DuoColors.orbitTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _money(balance),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DuoColors.orbitTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
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
          const SizedBox(height: 12),
          const _ProgressBar(progress: .72, color: DuoColors.success),
        ],
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
      borderRadius: 24,
      child: Row(
        children: [
          _IconTile(
            icon: Icons.pie_chart_rounded,
            color: DuoColors.orbitAccent,
            size: 36,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Orçamento de $month',
                    style: const TextStyle(
                      color: DuoColors.orbitTextSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isLoading
                            ? 'Carregando...'
                            : current == null
                                ? 'Nenhum orçamento ativo'
                                : '${_money(current.spentAmount)} de ${_money(current.limitAmount)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DuoColors.orbitTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: DuoColors.orbitTextSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                _ProgressBar(
                  progress: progress,
                  color: DuoColors.orbitAccent,
                  height: 5,
                ),
              ],
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
      borderRadius: 24,
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
      borderRadius: 24,
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
        borderRadius: 24,
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

  static const _heroImageUrl =
      'https://dimg.dreamflow.cloud/v1/image/dark%20landscape%20with%20distant%20mountains%20and%20sunset%20glow';

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: 320,
        width: double.infinity,
        child: Opacity(
          opacity: .4,
          child: Image.network(
            _heroImageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
      ),
    );
  }
}

class _OrbitBottomNavigation extends StatelessWidget {
  final bool financeActive;
  final VoidCallback onHome;
  final VoidCallback onFinance;
  final VoidCallback onRoutines;
  final VoidCallback onAi;

  const _OrbitBottomNavigation({
    this.financeActive = false,
    required this.onHome,
    required this.onFinance,
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
              border: const Border(
                top: BorderSide(color: DuoColors.orbitBorder),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Início',
                    active: !financeActive,
                    onTap: onHome,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Finanças',
                    active: financeActive,
                    activeColor: DuoColors.orbitAccent,
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
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.activeColor = DuoColors.success,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : DuoColors.orbitTextSecondary;
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
              color: active ? activeColor.withValues(alpha: .14) : null,
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
      width: 64,
      height: 64,
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
  final Color color;

  const _QuickCreateMenuItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
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
      ),
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
