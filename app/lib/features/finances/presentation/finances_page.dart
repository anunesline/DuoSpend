import 'package:flutter/material.dart';

import '../../home/presentation/widgets/orbit_home_chrome.dart';
import '../data/financial_accounts_repository.dart';
import 'accounts_page.dart';
import 'finance_widgets.dart';

class FinancesPage extends StatefulWidget {
  final String userName;
  final String? photoUrl;
  final bool valuesVisible;
  final VoidCallback onHome;
  final Future<void> Function() onCreate,
      onRoutines,
      onAi,
      onCards,
      onBills,
      onBudgets,
      onTransactions,
      onReports,
      onGoals,
      onAccountsChanged;
  final bool hasWallet;
  final VoidCallback onProfile, onNotifications;
  final bool hasPendingItems;
  final FinancialAccountsRepository? repository;
  const FinancesPage({
    super.key,
    required this.userName,
    this.photoUrl,
    required this.valuesVisible,
    required this.onHome,
    required this.onCreate,
    required this.onRoutines,
    required this.onAi,
    required this.onCards,
    required this.onBills,
    required this.onBudgets,
    required this.onTransactions,
    required this.onReports,
    required this.onGoals,
    required this.onAccountsChanged,
    required this.hasWallet,
    required this.onProfile,
    required this.onNotifications,
    required this.hasPendingItems,
    this.repository,
  });
  @override
  State<FinancesPage> createState() => _FinancesPageState();
}

class _FinancesPageState extends State<FinancesPage> {
  late final FinancialAccountsRepository _repository =
      widget.repository ?? FinancialAccountsRepository();
  late bool _visible = widget.valuesVisible;
  late bool _hasWallet = widget.hasWallet;

  Widget _navigation(BuildContext pageContext) => OrbitHomeNavigation(
    financeActive: true,
    onHome: widget.onHome,
    onFinance: () =>
        Navigator.of(pageContext)
            .popUntil((route) => route == ModalRoute.of(context)),
    onRoutines: widget.onRoutines,
    onAi: widget.onAi,
    onCreate: widget.onCreate,
  );

  Future<void> _accounts() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountsPage(
          repository: _repository,
          navigationBuilder: _navigation,
          valuesVisible: _visible,
        ),
      ),
    );
    if (!mounted) return;
    await widget.onAccountsChanged();
    try {
      final accounts = await _repository.loadAccounts();
      if (mounted)
        setState(() => _hasWallet = accounts.any((a) => !a.isArchived));
    } catch (_) {
      /* The account page exposes its own retry state. */
    }
  }

  Future<void> _open(
    String title,
    Future<void> Function() action, {
    bool needsWallet = true,
  }) async {
    if (needsWallet && !_hasWallet) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FinanceScaffold(
            title: title,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const OrbitHomeMessage(
                    message: 'Adicione uma conta ou carteira para começar.',
                  ),
                  const SizedBox(height: 12),
                  FinanceButton(
                    label: 'Contas e carteiras',
                    onPressed: () async {
                      Navigator.pop(context);
                      await _accounts();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }
    await action();
  }

  @override
  Widget build(BuildContext context) {
    final entries = <(String, String, IconData, Color, VoidCallback)>[
      (
        'Contas e carteiras',
        'Onde o seu dinheiro está',
        Icons.account_balance_outlined,
        OrbitHomeTokens.purple,
        _accounts,
      ),
      (
        'Cartões',
        'Acompanhe seus cartões e faturas',
        Icons.credit_card_rounded,
        OrbitHomeTokens.purple,
        () => _open('Cartões', widget.onCards, needsWallet: false),
      ),
      (
        'Contas a pagar',
        'Boletos, assinaturas e despesas fixas',
        Icons.receipt_long_outlined,
        OrbitHomeTokens.amber,
        () => _open('Contas a pagar', widget.onBills),
      ),
      (
        'Orçamentos',
        'Planeje e acompanhe seus gastos',
        Icons.calendar_month_outlined,
        OrbitHomeTokens.cyan,
        () => _open('Orçamentos', widget.onBudgets),
      ),
      (
        'Transações',
        'Veja todo o seu histórico',
        Icons.sync_alt_rounded,
        OrbitHomeTokens.purple,
        () => _open('Transações', widget.onTransactions),
      ),
      (
        'Relatórios',
        'Entenda seus hábitos',
        Icons.insert_chart_outlined,
        OrbitHomeTokens.cyan,
        () => _open('Relatórios', widget.onReports),
      ),
      (
        'Metas',
        'Conquiste seus objetivos',
        Icons.emoji_objects_outlined,
        OrbitHomeTokens.purple,
        () => _open('Metas', widget.onGoals),
      ),
    ];
    return FinanceScaffold(
      title: 'Finanças',
      showAppBar: false,
      navigation: _navigation(context),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.paddingOf(context).top + 10,
          16,
          20,
        ),
        children: [
          OrbitHomeHeader(
            name: widget.userName,
            photoUrl: widget.photoUrl,
            valuesVisible: _visible,
            hasPendingItems: widget.hasPendingItems,
            onPrivacy: () => setState(() => _visible = !_visible),
            onNotifications: widget.onNotifications,
            onProfile: widget.onProfile,
            onWallets: _accounts,
          ),
          const SizedBox(height: 16),
          const Text(
            'Finanças',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: OrbitHomeTokens.text,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tudo do seu dinheiro em um só lugar.',
            style: TextStyle(color: OrbitHomeTokens.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: OrbitHomeTokens.gap),
              child: FinanceEntry(
                icon: entry.$3,
                color: entry.$4,
                title: entry.$1,
                subtitle: entry.$2,
                onTap: entry.$5,
              ),
            ),
        ],
      ),
    );
  }
}
