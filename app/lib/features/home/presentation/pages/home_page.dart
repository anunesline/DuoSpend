import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/context/wallet_context.dart';
import '../../../../core/services/auth/auth_service.dart';
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
import '../../../settings/presentation/pages/orbit_settings_page.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../data/models/partner_invite_model.dart';
import '../../data/repositories/partner_invite_repository.dart';
import '../../../household_routines/domain/models/household_task.dart';
import '../../../transactions/presentation/pages/balance_settlement_page.dart';
import '../../domain/services/orbit_home_overview_builder.dart';
import '../widgets/orbit_home_chrome.dart';
import '../widgets/orbit_home_content.dart';
import '../widgets/orbit_home_primitives.dart';
import 'partner_invites_page.dart';
import '../controllers/home_controller.dart';
import '../controllers/orbit_dashboard_controller.dart';

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

  bool _valuesVisible = true;
  int _refreshVersion = 0;
  final Set<String> _completingTasks = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = HomeController(walletContext: widget.walletContext);
    orbitController = OrbitDashboardController(
      taskRepository: widget.householdRoutinesController.taskRepository,
      userRepository: widget.householdRoutinesController.userRepository,
    );
    transactionController = TransactionController();
    _loadHome();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Bom dia';
    if (hour >= 12 && hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Future<void> _loadHome() async {
    if (!mounted) return;
    final version = ++_refreshVersion;
    orbitController.clear();
    await controller.loadHome();
    if (!mounted || version != _refreshVersion) return;
    await _loadOrbitSummary();
  }

  Future<void> _loadOrbitSummary() async {
    if (!mounted ||
        controller.isLoadingTransactions ||
        controller.errorMessage != null) {
      return;
    }
    final wallet = controller.wallet;
    final userId = controller.user?.uid;
    if (wallet == null || userId == null) {
      orbitController.clear();
      return;
    }
    await orbitController.load(
      wallet: wallet,
      transactions: controller.transactions,
      currentUserId: userId,
    );
  }

  Future<void> _selectWallet(String walletId) async {
    final version = ++_refreshVersion;
    orbitController.clear();
    await controller.selectWalletById(walletId);
    if (!mounted || version != _refreshVersion) return;
    await _loadOrbitSummary();
  }

  Future<void> _openProfileMenu() async {
    final wallet = controller.wallet;
    final shared = wallet?.isShared ?? false;
    final overview = orbitController.overview;
    final partnerId = shared
        ? wallet?.memberIds.where((id) => id != controller.user?.uid).firstOrNull
        : null;
    final partner = overview?.profiles[partnerId];
    final action = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => _OrbitProfilePage(
          name: controller.user?.displayName?.trim().isNotEmpty == true
              ? controller.user!.displayName!.trim()
              : controller.userName,
          email: controller.user?.email ?? '',
          photoUrl: controller.userPhotoUrl,
          partnerName: partnerId == null
              ? null
              : overview?.memberName(partnerId) ?? 'Seu parceiro',
          partnerPhotoUrl: partner?.photoUrl,
          connected: controller.connectedSharedWallet != null,
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'profile-updated':
        await controller.loadHome();
        if (mounted) setState(() {});
      case 'signed-out':
        return;
      case 'couple':
        var wallet = controller.connectedSharedWallet;
        if (wallet == null || !wallet.canInvitePartner) {
          wallet = controller.sharedWallets
              .where((item) => item.canInvitePartner)
              .firstOrNull;
        }
        if (wallet == null) {
          wallet = await controller.createSharedWallet();
        }
        if (!mounted || wallet == null) {
          if (mounted) {
            _showMessage(
              controller.errorMessage ??
                  'Não foi possível preparar o Orbit a Dois.',
            );
          }
          return;
        }
        await _selectWallet(wallet.id);
        if (mounted) await _invitePartner();
      case 'notifications':
        await _openPendingItems();
      case 'share':
        _showMessage('O compartilhamento será ativado com o link oficial do Orbit.');
      case 'appearance':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrbitSettingsPage(
              sharedWalletId: controller.connectedSharedWallet?.id,
              sharedMemberIds: controller.connectedSharedWallet?.memberIds ?? const [],
            ),
          ),
        );
        if (mounted) await _loadHome();
      default:
        break;
    }
  }

  Future<void> _openCoupleSettings() async {
    await controller.loadHome();
    if (!mounted) return;

    final sharedWallet = controller.connectedSharedWallet;
    final currentUserId = controller.user?.uid ?? '';
    final partnerId = sharedWallet?.memberIds
        .where((id) => id != currentUserId)
        .firstOrNull;

    String? partnerName;
    String? partnerPhotoUrl;
    if (partnerId != null) {
      final profiles =
          await UserRepository().getUserProfileSummaries([partnerId]);
      final profile = profiles[partnerId];
      partnerName = profile?.displayName ?? 'Seu parceiro';
      partnerPhotoUrl = profile?.photoUrl;
    }

    final inviteRepository = PartnerInviteRepository();
    final sentInvites = await inviteRepository.getSentInvites();
    final pendingSentInvite = sentInvites
        .where((invite) => invite.isPending && !invite.isExpired)
        .where((invite) {
          if (sharedWallet != null) return invite.walletId == sharedWallet.id;
          return true;
        })
        .firstOrNull;
    final receivedInvites = sharedWallet == null
        ? await inviteRepository.getReceivedInvites()
        : const <PartnerInviteModel>[];

    if (!mounted) return;
    final action = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => _OrbitCouplePage(
          connected: sharedWallet != null,
          userName: controller.user?.displayName?.trim().isNotEmpty == true
              ? controller.user!.displayName!.trim()
              : controller.userName,
          userPhotoUrl: controller.userPhotoUrl,
          partnerName: partnerName,
          partnerPhotoUrl: partnerPhotoUrl,
          pendingInviteEmail: pendingSentInvite?.invitedEmail,
          receivedInviteCount: receivedInvites.length,
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'invite') {
      var wallet = controller.wallet;
      if (wallet == null || !wallet.isShared || !wallet.canInvitePartner) {
        wallet = controller.sharedWallets
            .where((item) => item.canInvitePartner)
            .firstOrNull;
      }
      if (wallet == null) {
        wallet = await controller.createSharedWallet();
      }
      if (!mounted) return;
      if (wallet == null) {
        _showMessage(
          controller.errorMessage ?? 'Não foi possível preparar o Orbit a Dois.',
        );
        return;
      }
      await _selectWallet(wallet.id);
      if (mounted) await _invitePartner();
      if (mounted) await _openCoupleSettings();
      return;
    }

    if (action == 'received') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PartnerInvitesPage()),
      );
      if (mounted) {
        await _loadHome();
        await _openCoupleSettings();
      }
      return;
    }

    if (action == 'cancel-invite' && pendingSentInvite != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cancelar convite?'),
          content: Text(
            'O convite enviado para ${pendingSentInvite.invitedEmail} deixará de ficar disponível.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Cancelar convite'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await inviteRepository.cancelInvite(pendingSentInvite);
        if (mounted) {
          _showMessage('Convite cancelado.');
          await _openCoupleSettings();
        }
      }
      return;
    }

    if (action == 'disconnect' && sharedWallet != null && partnerId != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sair do Orbit a Dois?'),
          content: const Text(
            'A conexão entre vocês será encerrada. Sua conta individual continuará ativa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Encerrar conexão'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      await FirebaseFirestore.instance
          .collection('wallets')
          .doc(sharedWallet.id)
          .update({
        'memberIds': FieldValue.arrayRemove([
          sharedWallet.isOwner(currentUserId) ? partnerId : currentUserId,
        ]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      await _loadHome();
      _showMessage('Orbit a Dois desconectado.');
      return;
    }

    if (action == 'manage') {
      _showMessage('Conectado com ${partnerName ?? 'seu parceiro'}.');
    }
  }

  Future<void> _switchScope(bool shared) async {
    if (controller.isLoading) return;
    if (controller.wallet?.isShared == shared) return;
    final candidates = shared
        ? controller.sharedWallets
        : controller.individualWallets;
    if (candidates.isNotEmpty) {
      final target = shared
          ? controller.connectedSharedWallet ?? candidates.first
          : candidates.first;
      await _selectWallet(target.id);
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: OrbitHomeTokens.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                shared ? 'Seu espaço compartilhado' : 'Seu espaço individual',
                style: const TextStyle(
                  color: OrbitHomeTokens.text,
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                shared
                    ? 'Crie uma carteira compartilhada ou aceite um convite para organizar a vida a dois.'
                    : 'Crie uma carteira individual para acompanhar suas finanças.',
                style: const TextStyle(
                  color: OrbitHomeTokens.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(context, 'create'),
                child: Text(
                  shared
                      ? 'Criar carteira compartilhada'
                      : 'Criar carteira individual',
                ),
              ),
              if (shared)
                TextButton(
                  onPressed: () => Navigator.pop(context, 'invites'),
                  child: const Text('Ver convites recebidos'),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'invites') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PartnerInvitesPage()),
      );
    } else {
      final created = shared
          ? await controller.createSharedWallet()
          : await controller.createIndividualWallet(
              name: 'Carteira individual',
            );
      if (created == null) {
        _showMessage(
          controller.errorMessage ?? 'Não foi possível criar a carteira.',
        );
      }
    }
    if (mounted) await _loadHome();
  }

  Future<void> _invitePartner() async {
    var email = '';
    final submitted = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convidar para a carteira'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-mail'),
          onChanged: (value) => email = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, email),
            child: const Text('Enviar convite'),
          ),
        ],
      ),
    );
    if (!mounted || submitted == null) return;
    final invite = await controller.sendPartnerInvite(invitedEmail: submitted);
    _showMessage(
      invite == null
          ? controller.errorMessage ?? 'Não foi possível enviar o convite.'
          : 'Convite enviado.',
    );
  }

  Future<void> _openSelectedWallet() async {
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

  Future<void> _openSettlements() async {
    final wallet = controller.wallet;
    if (wallet == null || !wallet.isShared) return;
    final data = orbitController.overview;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BalanceSettlementPage(
          walletId: wallet.id,
          wallet: wallet,
          memberNames: {
            for (final id in wallet.memberIds)
              id: data?.memberName(id) ?? 'Outro membro',
          },
        ),
      ),
    );
    if (mounted) await _loadHome();
  }

  Future<void> _completeTask(HouseholdTask task) async {
    final wallet = controller.wallet;
    final userId = controller.user?.uid;
    if (wallet == null ||
        userId == null ||
        !task.isPending ||
        _completingTasks.contains(task.id) ||
        task.scopeId != OrbitHomeOverviewBuilder.taskScope(wallet, userId)) {
      return;
    }
    setState(() => _completingTasks.add(task.id));
    await widget.householdRoutinesController.completeTask(
      task.id,
      completedByUserId: userId,
    );
    if (!mounted) return;
    setState(() => _completingTasks.remove(task.id));
    final error = widget.householdRoutinesController.errorMessage;
    if (error != null) _showMessage(error);
    await _loadOrbitSummary();
  }

  Future<void> _openPendingItems() async {
    final data = orbitController.overview;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: OrbitHomeTokens.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ListTile(
                  title: Text('Suas pendências'),
                  subtitle: Text(
                    'Acompanhe os próximos passos deste contexto.',
                  ),
                ),
                if (data == null)
                  const ListTile(
                    title: Text(
                      'Atualize a Home para consultar as pendências.',
                    ),
                  ),
                if (data != null && !data.hasPendingItems)
                  const ListTile(
                    title: Text('Nenhuma pendência carregada neste contexto.'),
                  ),
                if ((data?.pendingConfirmationCount ?? 0) > 0)
                  ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: Text(
                      '${data!.pendingConfirmationCount} despesas para confirmar',
                    ),
                    onTap: () => Navigator.pop(context, 'history'),
                  ),
                if (data != null &&
                    data.settlements.any(
                      (item) =>
                          item.isAwaitingConfirmation &&
                          item.toMemberId == data.currentUserId,
                    ))
                  ListTile(
                    leading: const Icon(Icons.swap_horiz_rounded),
                    title: const Text('Acertos aguardando recebimento'),
                    onTap: () => Navigator.pop(context, 'settlements'),
                  ),
                if ((data?.overdueTaskCount ?? 0) > 0)
                  ListTile(
                    leading: const Icon(Icons.task_alt_rounded),
                    title: Text('${data!.overdueTaskCount} rotinas atrasadas'),
                    onTap: () => Navigator.pop(context, 'routines'),
                  ),
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded),
                  title: const Text('Convites recebidos'),
                  onTap: () => Navigator.pop(context, 'invites'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'history':
        await _openHistoryPage();
      case 'settlements':
        await _openSettlements();
      case 'routines':
        await _openHouseholdRoutinesPage();
      case 'invites':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PartnerInvitesPage()),
        );
        if (mounted) await _loadHome();
      default:
        break;
    }
  }

  Future<void> _openCreditCardsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreditCardsPage(
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

    final sharedWallet = controller.wallet?.isShared == true
        ? controller.wallet
        : controller.connectedSharedWallet;
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
    if (mounted) await _loadOrbitSummary();
  }

  Future<void> _openFinanceHub() async {
    final shortcutScrollController = ScrollController();
    try {
      await showModalBottomSheet<bool>(
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            'Acesse os principais recursos financeiros.',
                          ),
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

  }

  Future<void> _showQuickCreateMenu() async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
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
    _refreshVersion++;
    _scrollController.dispose();
    transactionController.dispose();
    orbitController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: OrbitHomeTokens.background,
    ),
    child: ListenableBuilder(
      listenable: Listenable.merge([controller, orbitController]),
      builder: (context, _) {
        final wallet = controller.wallet;
        final shared = wallet?.isShared ?? false;
        final loaded = orbitController.overview;
        final data = loaded?.wallet.id == wallet?.id ? loaded : null;
        final loading =
            controller.isLoading ||
            controller.isLoadingTransactions ||
            orbitController.isLoading;
        final error = controller.errorMessage ?? orbitController.errorMessage;
        final partnerId = shared
            ? wallet?.memberIds
                  .where((id) => id != controller.user?.uid)
                  .firstOrNull
            : null;
        final partner = data?.profiles[partnerId];
        final user = data?.profiles[controller.user?.uid];
        final top = MediaQuery.paddingOf(context).top;
        return Scaffold(
          backgroundColor: OrbitHomeTokens.background,
          extendBody: true,
          bottomNavigationBar: OrbitHomeNavigation(
            onHome: () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
            onFinance: _openFinanceHub,
            onRoutines: _openHouseholdRoutinesPage,
            onAi: _openInsightsPage,
            onCreate: wallet == null || controller.isLoading
                ? null
                : _showQuickCreateMenu,
          ),
          body: Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: OrbitHomeBackdrop(),
              ),
              RefreshIndicator(
                onRefresh: _loadHome,
                color: OrbitHomeTokens.green,
                backgroundColor: OrbitHomeTokens.surface,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    top + 4,
                    16,
                    96 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OrbitHomeHeader(
                            name: controller.userName,
                            photoUrl: controller.userPhotoUrl ?? user?.photoUrl,
                            partnerName: partnerId == null
                                ? null
                                : data?.memberName(partnerId) ?? 'Outro membro',
                            partnerPhotoUrl: partner?.photoUrl,
                            valuesVisible: _valuesVisible,
                            hasPendingItems: data?.hasPendingItems ?? false,
                            onPrivacy: () => setState(
                              () => _valuesVisible = !_valuesVisible,
                            ),
                            onNotifications: _openPendingItems,
                            onProfile: _openProfileMenu,
                            onWallets: _openWalletSelector,
                          ),
                          const SizedBox(height: 6),
                          OrbitHomeScopeSelector(
                            shared: shared,
                            onSolo: () => _switchScope(false),
                            onShared: () => _switchScope(true),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(2, 12, 2, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shared
                                      ? '$_greeting, nós! 💜'
                                      : 'Olá, ${controller.userName}! 👋',
                                  style: const TextStyle(
                                    color: OrbitHomeTokens.text,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  shared
                                      ? 'Tudo que importa para vocês,\nem um só lugar.'
                                      : 'Que tal deixar o dia mais leve e\nas finanças no controle?',
                                  style: const TextStyle(
                                    color: OrbitHomeTokens.text,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 70),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: OrbitHomeTokens.green,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else if (error != null)
                            OrbitHomeMessage(
                              message: '$error Toque para tentar novamente.',
                              onTap: _loadHome,
                            )
                          else if (wallet == null)
                            OrbitHomeMessage(
                              message:
                                  'Crie sua primeira carteira para começar.',
                              onTap: () => _switchScope(false),
                              icon: Icons.account_balance_wallet_outlined,
                            )
                          else if (data != null) ...[
                            if (shared && controller.canInvitePartner) ...[
                              OrbitHomeMessage(
                                message:
                                    'Convide alguém para organizar a vida com você.',
                                onTap: _invitePartner,
                                icon: Icons.person_add_alt_1_rounded,
                              ),
                              const SizedBox(height: 12),
                            ],
                            OrbitHomeContent(
                              data: data,
                              valuesVisible: _valuesVisible,
                              onWallet: _openSelectedWallet,
                              onBudget: _openBudgetsPage,
                              onCalendar: _openFinancialCalendarPage,
                              onGoals: _openSavingsGoalsPage,
                              onInsights: _openInsightsPage,
                              onRoutines: _openHouseholdRoutinesPage,
                              onSettlements: _openSettlements,
                              onContribution: _openMonthlyReportPage,
                              onHistory: _openHistoryPage,
                              onRetry: _loadHome,
                              onCompleteTask: _completeTask,
                              completingTasks: _completingTasks,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

// Existing budget navigation is kept local to its route. The new Home chrome
// does not restyle another screen as a side effect of this reconstruction.
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
          child: const Icon(
            Icons.add_rounded,
            color: Color(0xFF071109),
            size: 28,
          ),
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
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              style: const TextStyle(
                color: DuoColors.orbitTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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


class _OrbitProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final String? partnerName;
  final String? partnerPhotoUrl;
  final bool connected;

  const _OrbitProfilePage({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.partnerName,
    required this.partnerPhotoUrl,
    required this.connected,
  });

  @override
  State<_OrbitProfilePage> createState() => _OrbitProfilePageState();
}

class _OrbitProfilePageState extends State<_OrbitProfilePage> {
  final AuthService _authService = AuthService();
  bool _busy = false;
  late String _name;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
  }

  Future<void> _editProfile() async {
    var draftName = _name;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar perfil'),
        content: TextFormField(
          initialValue: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome'),
          onChanged: (value) => draftName = value,
          onFieldSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, draftName), child: const Text('Salvar')),
        ],
      ),
    );
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty || normalized == _name) return;
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Usuário não autenticado');
      await user.updateDisplayName(normalized);
      await user.reload();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'name': normalized, 'displayName': normalized},
        SetOptions(merge: true),
      );
      if (!mounted) return;
      setState(() => _name = normalized);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível atualizar o perfil.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _privacy() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const _OrbitInfoPage(
      title: 'Privacidade e segurança',
      icon: Icons.lock_outline_rounded,
      children: [
        _OrbitInfoItem(title: 'Sua conta', body: 'O acesso ao Orbit usa a autenticação da sua conta Google.'),
        _OrbitInfoItem(title: 'Seus dados', body: 'Seus dados financeiros e pessoais ficam vinculados à sua conta autenticada.'),
        _OrbitInfoItem(title: 'Orbit a Dois', body: 'O compartilhamento com outra pessoa só acontece após convite e aceite.'),
      ],
    )));
  }

  Future<void> _help() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'indisponível';
    await Navigator.push(context, MaterialPageRoute(builder: (_) => _OrbitInfoPage(
      title: 'Ajuda e suporte',
      icon: Icons.help_outline_rounded,
      children: [
        const _OrbitInfoItem(title: 'Precisa de ajuda?', body: 'Use esta área para consultar informações da sua conta e identificar o acesso em um atendimento.'),
        _OrbitInfoItem(title: 'E-mail da conta', body: widget.email.isEmpty ? 'Não informado' : widget.email),
        _OrbitInfoItem(title: 'ID de diagnóstico', body: uid),
      ],
    )));
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Você precisará entrar novamente para acessar o Orbit.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sair')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _OrbitSettingsScaffold(
    child: AbsorbPointer(
      absorbing: _busy,
      child: Column(
        children: [
          const SizedBox(height: 8),
          OrbitHomeAvatar(name: _name, photoUrl: widget.photoUrl, size: 76),
          const SizedBox(height: 14),
          Text(_name, style: const TextStyle(color: OrbitHomeTokens.text, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(widget.email.isEmpty ? 'Sua conta Orbit' : widget.email, style: const TextStyle(color: OrbitHomeTokens.muted, fontSize: 13)),
          const SizedBox(height: 18),
          OutlinedButton(onPressed: _editProfile, child: const Text('Editar perfil')),
          const SizedBox(height: 22),
          _OrbitMenuCard(children: [
            _OrbitMenuTile(icon: Icons.favorite_border_rounded, title: 'Orbit a Dois', subtitle: widget.connected ? 'Gerencie sua conexão' : 'Convide alguém para compartilhar sua jornada', accent: true, onTap: () => Navigator.pop(context, 'couple')),
          ]),
          const SizedBox(height: 12),
          _OrbitMenuCard(children: [
            _OrbitMenuTile(icon: Icons.notifications_none_rounded, title: 'Notificações', onTap: () => Navigator.pop(context, 'notifications')),
            _OrbitMenuTile(icon: Icons.settings_outlined, title: 'Configurações', onTap: () => Navigator.pop(context, 'appearance')),
            _OrbitMenuTile(icon: Icons.lock_outline_rounded, title: 'Privacidade e segurança', onTap: _privacy),
            _OrbitMenuTile(icon: Icons.help_outline_rounded, title: 'Ajuda e suporte', onTap: _help),
          ]),
          const SizedBox(height: 12),
          _OrbitMenuCard(children: [
            _OrbitMenuTile(icon: Icons.logout_rounded, title: 'Sair da conta', danger: true, onTap: _signOut),
          ]),
        ],
      ),
    ),
  );
}

class _OrbitInfoPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _OrbitInfoPage({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) => _OrbitSettingsScaffold(
    title: title,
    child: Column(children: [
      const SizedBox(height: 8),
      CircleAvatar(radius: 30, backgroundColor: DuoColors.orbitAccent.withValues(alpha: .12), child: Icon(icon, color: DuoColors.orbitAccent, size: 30)),
      const SizedBox(height: 22),
      _OrbitMenuCard(children: children),
    ]),
  );
}

class _OrbitInfoItem extends StatelessWidget {
  final String title;
  final String body;
  const _OrbitInfoItem({required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    child: Align(alignment: Alignment.centerLeft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: OrbitHomeTokens.text, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 5),
      SelectableText(body, style: const TextStyle(color: OrbitHomeTokens.muted, fontSize: 13, height: 1.4)),
    ])),
  );
}

class _OrbitCouplePage extends StatelessWidget {
  final bool connected;
  final String userName;
  final String? userPhotoUrl;
  final String? partnerName;
  final String? partnerPhotoUrl;
  final String? pendingInviteEmail;
  final int receivedInviteCount;

  const _OrbitCouplePage({
    required this.connected,
    required this.userName,
    required this.userPhotoUrl,
    required this.partnerName,
    required this.partnerPhotoUrl,
    required this.pendingInviteEmail,
    required this.receivedInviteCount,
  });

  @override
  Widget build(BuildContext context) => _OrbitSettingsScaffold(
    title: connected ? 'Orbit a Dois' : null,
    child: connected ? _connected(context) : _solo(context),
  );

  Widget _solo(BuildContext context) {
    final pendingEmail = pendingInviteEmail?.trim();
    final hasPendingInvite = pendingEmail != null && pendingEmail.isNotEmpty;

    return Column(
      children: [
        const SizedBox(height: 34),
        const _OrbitCoupleArt(),
        const SizedBox(height: 26),
        const Text(
          'Orbit a Dois',
          style: TextStyle(
            color: OrbitHomeTokens.text,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Mais organização, juntos.',
          style: TextStyle(color: OrbitHomeTokens.muted, fontSize: 15),
        ),
        const SizedBox(height: 28),
        const _OrbitBenefit(
          icon: Icons.account_balance_wallet_outlined,
          text: 'Finanças compartilhadas\nou individuais',
        ),
        const _OrbitBenefit(
          icon: Icons.auto_awesome_rounded,
          text: 'Metas e sonhos em conjunto',
        ),
        const _OrbitBenefit(
          icon: Icons.people_outline_rounded,
          text: 'Rotinas da casa mais leves',
        ),
        const _OrbitBenefit(
          icon: Icons.settings_suggest_outlined,
          text: 'Visão completa, com o mesmo\nestilo visual que você já ama',
        ),
        const SizedBox(height: 28),
        if (hasPendingInvite)
          _OrbitMenuCard(
            children: [
              _OrbitInfoItem(
                title: 'Convite enviado',
                body: 'Aguardando $pendingEmail aceitar o convite.',
              ),
              _OrbitMenuTile(
                icon: Icons.close_rounded,
                title: 'Cancelar convite',
                danger: true,
                onTap: () => Navigator.pop(context, 'cancel-invite'),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, 'invite'),
              child: const Text('Convidar alguém'),
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, 'received'),
            icon: const Icon(Icons.mail_outline_rounded),
            label: Text(
              receivedInviteCount > 0
                  ? 'Convites recebidos ($receivedInviteCount)'
                  : 'Ver convites recebidos',
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          '“Juntos, o hoje faz mais sentido\ne o amanhã vai mais longe.”',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: OrbitHomeTokens.purple,
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _connected(BuildContext context) => Column(
    children: [
      const SizedBox(height: 24),
      SizedBox(
        height: 84,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(-24, 0),
              child: OrbitHomeAvatar(
                name: userName,
                photoUrl: userPhotoUrl,
                size: 72,
              ),
            ),
            Transform.translate(
              offset: const Offset(24, 0),
              child: OrbitHomeAvatar(
                name: partnerName ?? 'Parceiro',
                photoUrl: partnerPhotoUrl,
                size: 72,
              ),
            ),
            const Positioned(
              bottom: 0,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: OrbitHomeTokens.purple,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const _OrbitConnectedBadge(),
      const SizedBox(height: 12),
      Text(
        'Você e ${partnerName ?? 'seu parceiro'}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: OrbitHomeTokens.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Mais organização, juntos.',
        style: TextStyle(color: OrbitHomeTokens.muted),
      ),
      const SizedBox(height: 26),
      _OrbitMenuCard(
        children: [
          _OrbitMenuTile(
            icon: Icons.manage_accounts_outlined,
            title: 'Gerenciar conexão',
            subtitle: 'Veja com quem seu Orbit está conectado',
            onTap: () => Navigator.pop(context, 'manage'),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _OrbitMenuCard(
        children: [
          _OrbitMenuTile(
            icon: Icons.logout_rounded,
            title: 'Sair do Orbit a Dois',
            subtitle: 'Sua conta individual continuará ativa',
            danger: true,
            onTap: () => Navigator.pop(context, 'disconnect'),
          ),
        ],
      ),
      const SizedBox(height: 28),
      const Text(
        '“Dois contextos. Uma vida mais organizada.”',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: OrbitHomeTokens.purple,
          fontStyle: FontStyle.italic,
        ),
      ),
    ],
  );
}

class _OrbitSettingsScaffold extends StatelessWidget {
  final Widget child;
  final String? title;
  const _OrbitSettingsScaffold({required this.child, this.title});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: OrbitHomeTokens.background,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: OrbitHomeTokens.text,
      elevation: 0,
      centerTitle: true,
      title: title == null ? null : Text(title!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    ),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: child)),
      ),
    ),
  );
}

class _OrbitMenuCard extends StatelessWidget {
  final List<Widget> children;
  const _OrbitMenuCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: OrbitHomeTokens.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: OrbitHomeTokens.border)),
    child: Column(children: [for (var i = 0; i < children.length; i++) ...[children[i], if (i != children.length - 1) const Divider(height: 1, indent: 58, color: OrbitHomeTokens.border)]]),
  );
}

class _OrbitMenuTile extends StatelessWidget {
  final IconData icon; final String title; final String? subtitle; final VoidCallback onTap; final bool accent; final bool danger;
  const _OrbitMenuTile({required this.icon, required this.title, required this.onTap, this.subtitle, this.accent = false, this.danger = false});
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    minLeadingWidth: 34,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: (accent ? OrbitHomeTokens.purple : OrbitHomeTokens.surface).withValues(alpha: accent ? .18 : 1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: danger ? Colors.redAccent : accent ? OrbitHomeTokens.purple : OrbitHomeTokens.text, size: 21)),
    title: Text(title, style: TextStyle(color: danger ? Colors.redAccent : OrbitHomeTokens.text, fontWeight: FontWeight.w500)),
    subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(color: OrbitHomeTokens.muted, fontSize: 12)),
    trailing: danger ? null : const Icon(Icons.chevron_right_rounded, color: OrbitHomeTokens.muted),
  );
}

class _OrbitBenefit extends StatelessWidget {
  final IconData icon; final String text;
  const _OrbitBenefit({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: OrbitHomeTokens.purple.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: OrbitHomeTokens.purple)), const SizedBox(width: 14), Expanded(child: Text(text, style: const TextStyle(color: OrbitHomeTokens.text, height: 1.35)))]),
  );
}

class _OrbitCoupleArt extends StatelessWidget {
  const _OrbitCoupleArt();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 120,
    child: Stack(alignment: Alignment.center, children: [
      Transform.translate(offset: const Offset(-28, -6), child: Container(width: 88, height: 88, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: OrbitHomeTokens.purple, width: 2), boxShadow: [BoxShadow(color: OrbitHomeTokens.purple.withValues(alpha: .25), blurRadius: 28)]))),
      Transform.translate(offset: const Offset(28, 8), child: Container(width: 88, height: 88, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: OrbitHomeTokens.purple, width: 2), boxShadow: [BoxShadow(color: OrbitHomeTokens.purple.withValues(alpha: .25), blurRadius: 28)]))),
      const Icon(Icons.favorite_border_rounded, color: OrbitHomeTokens.purple, size: 30),
    ]),
  );
}

class _OrbitConnectedBadge extends StatelessWidget {
  const _OrbitConnectedBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(color: OrbitHomeTokens.green.withValues(alpha: .14), borderRadius: BorderRadius.circular(20), border: Border.all(color: OrbitHomeTokens.green.withValues(alpha: .45))),
    child: const Text('●  Conectados', style: TextStyle(color: OrbitHomeTokens.green, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}



