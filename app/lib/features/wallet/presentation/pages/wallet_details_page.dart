import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../../home/data/models/credit_card_model.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../home/data/repositories/credit_card_repository.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';

class WalletDetailsPage extends StatefulWidget {
  final WalletModel wallet;

  const WalletDetailsPage({super.key, required this.wallet});

  @override
  State<WalletDetailsPage> createState() => _WalletDetailsPageState();
}

class _WalletDetailsPageState extends State<WalletDetailsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _transactionRepository = TransactionRepository();
  final _cardRepository = CreditCardRepository();

  List<TransactionModel> _transactions = const [];
  List<CreditCardModel> _cards = const [];
  bool _loading = true;
  bool _valuesVisible = true;

  WalletModel get wallet => widget.wallet;
  final _money = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<dynamic>([
        _transactionRepository.getTransactionsByWallet(
          wallet.id,
          wallet: wallet,
        ),
        _cardRepository.getCards(),
      ]);
      if (!mounted) return;
      setState(() {
        _transactions = (results[0] as List<TransactionModel>)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        _cards = (results[1] as List<CreditCardModel>)
            .where((card) => card.walletId == wallet.id)
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<TransactionModel> get _currentMonthTransactions {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
  }

  List<TransactionModel> get _upcomingTransactions {
    final now = DateTime.now();
    return _transactions.where((t) => t.date.isAfter(now)).take(3).toList();
  }

  double get _monthIncome => _currentMonthTransactions
      .where((t) => t.type == 'income')
      .fold(0, (sum, t) => sum + t.value);

  double get _monthExpense => _currentMonthTransactions
      .where((t) => t.type == 'expense')
      .fold(0, (sum, t) => sum + t.value);

  double get _forecastBalance {
    final now = DateTime.now();
    var forecast = wallet.balance;
    for (final transaction in _transactions.where((t) => t.date.isAfter(now))) {
      forecast += transaction.type == 'income'
          ? transaction.value
          : -transaction.value;
    }
    return forecast;
  }

  String _visibleMoney(double value) =>
      _valuesVisible ? _money.format(value) : 'R\$ ••••••';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _WalletHeader(
              wallet: wallet,
              onBack: () => Navigator.pop(context),
            ),
            _WalletTabs(controller: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(
                    wallet: wallet,
                    loading: _loading,
                    valuesVisible: _valuesVisible,
                    balance: _visibleMoney(wallet.balance),
                    forecastBalance: _visibleMoney(_forecastBalance),
                    monthIncome: _monthIncome,
                    monthExpense: _monthExpense,
                    upcoming: _upcomingTransactions,
                    cards: _cards,
                    money: _money,
                    onToggleVisibility: () =>
                        setState(() => _valuesVisible = !_valuesVisible),
                    onStatement: () => _tabController.animateTo(1),
                    onManageCards: () => _showMessage(
                      'Gerencie seus cartões pela área de Cartões.',
                    ),
                    onAction: _handleAction,
                  ),
                  _TransactionsTab(
                    transactions: _transactions,
                    money: _money,
                  ),
                  _StatisticsTab(
                    income: _monthIncome,
                    expense: _monthExpense,
                    money: _money,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _WalletBottomBar(
        onFinance: () {},
        onAdd: () => _showMessage('Use + na Home para adicionar.'),
        onHome: () => Navigator.pop(context),
      ),
    );
  }

  void _handleAction(String action) {
    if (action == 'Extrato') {
      _tabController.animateTo(1);
      return;
    }
    _showMessage('$action fica disponível pelo fluxo financeiro principal.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}

class _WalletHeader extends StatelessWidget {
  final WalletModel wallet;
  final VoidCallback onBack;

  const _WalletHeader({required this.wallet, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          _CircleIcon(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: DuoColors.primaryGradient,
            ),
            alignment: Alignment.center,
            child: Text(
              wallet.name.trim().isEmpty
                  ? 'D'
                  : wallet.name.trim().substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Carteira',
                  style: TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  wallet.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const _CircleIcon(icon: Icons.bar_chart_rounded),
          const SizedBox(width: 8),
          const _CircleIcon(icon: Icons.settings_outlined),
        ],
      ),
    );
  }
}

class _WalletTabs extends StatelessWidget {
  final TabController controller;
  const _WalletTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10121A),
        border: Border.all(color: DuoColors.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: DuoColors.primary.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DuoColors.primary.withValues(alpha: .22)),
        ),
        labelColor: DuoColors.primaryLight,
        unselectedLabelColor: DuoColors.textHint,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        tabs: const [
          Tab(text: 'Visão geral'),
          Tab(text: 'Transações'),
          Tab(text: 'Estatísticas'),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final WalletModel wallet;
  final bool loading;
  final bool valuesVisible;
  final String balance;
  final String forecastBalance;
  final double monthIncome;
  final double monthExpense;
  final List<TransactionModel> upcoming;
  final List<CreditCardModel> cards;
  final NumberFormat money;
  final VoidCallback onToggleVisibility;
  final VoidCallback onStatement;
  final VoidCallback onManageCards;
  final ValueChanged<String> onAction;

  const _OverviewTab({
    required this.wallet,
    required this.loading,
    required this.valuesVisible,
    required this.balance,
    required this.forecastBalance,
    required this.monthIncome,
    required this.monthExpense,
    required this.upcoming,
    required this.cards,
    required this.money,
    required this.onToggleVisibility,
    required this.onStatement,
    required this.onManageCards,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final total = monthIncome + monthExpense;
    final incomeRatio = total == 0 ? .5 : monthIncome / total;
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM', 'pt_BR').format(now);

    return RefreshIndicator(
      color: DuoColors.primary,
      onRefresh: () async {},
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
        children: [
          _HeroBalanceCard(
            balance: balance,
            forecast: forecastBalance,
            valuesVisible: valuesVisible,
            onToggleVisibility: onToggleVisibility,
          ),
          const SizedBox(height: 12),
          _ActionsRow(onAction: onAction),
          const SizedBox(height: 12),
          _MonthSummaryCard(
            monthLabel: monthLabel,
            income: monthIncome,
            expense: monthExpense,
            ratio: incomeRatio,
            money: money,
          ),
          const SizedBox(height: 12),
          _UpcomingCard(transactions: upcoming, money: money),
          const SizedBox(height: 12),
          _LinkedCardsCard(
            cards: cards,
            money: money,
            onManage: onManageCards,
          ),
          const SizedBox(height: 12),
          _WalletShortcuts(onStatement: onStatement),
          if (loading) ...[
            const SizedBox(height: 18),
            const Center(
              child: CircularProgressIndicator(color: DuoColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  final String balance;
  final String forecast;
  final bool valuesVisible;
  final VoidCallback onToggleVisibility;

  const _HeroBalanceCard({
    required this.balance,
    required this.forecast,
    required this.valuesVisible,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF201735), Color(0xFF11131D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DuoColors.primary.withValues(alpha: .18)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Saldo disponível',
                          style: TextStyle(
                            color: DuoColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: onToggleVisibility,
                          child: Icon(
                            valuesVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: DuoColors.textHint,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      balance,
                      style: const TextStyle(
                        color: DuoColors.textPrimary,
                        fontSize: 27,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '+ saldo realizado no período',
                      style: TextStyle(
                        color: DuoColors.success,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 84, color: DuoColors.divider),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo previsto',
                      style: TextStyle(
                        color: DuoColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      forecast,
                      style: const TextStyle(
                        color: DuoColors.primaryLight,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Até ${DateFormat('dd/MM').format(DateTime(DateTime.now().year, DateTime.now().month + 1, 0))}',
                      style: const TextStyle(
                        color: DuoColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DuoColors.primaryLight,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final ValueChanged<String> onAction;
  const _ActionsRow({required this.onAction});

  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.swap_horiz_rounded, 'Transferir'),
      (Icons.qr_code_2_rounded, 'Pix'),
      (Icons.south_rounded, 'Depositar'),
      (Icons.description_outlined, 'Extrato'),
      (Icons.more_horiz_rounded, 'Mais'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions
          .map(
            (action) => _ActionButton(
              icon: action.$1,
              label: action.$2,
              onTap: () => onAction(action.$2),
            ),
          )
          .toList(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: DuoColors.primary.withValues(alpha: .12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DuoColors.primary.withValues(alpha: .18),
                ),
              ),
              child: Icon(icon, color: DuoColors.primaryLight, size: 21),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(
                color: DuoColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  final String monthLabel;
  final double income;
  final double expense;
  final double ratio;
  final NumberFormat money;

  const _MonthSummaryCard({
    required this.monthLabel,
    required this.income,
    required this.expense,
    required this.ratio,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Resumo do mês',
                style: _Styles.sectionTitle,
              ),
              const SizedBox(width: 6),
              Text(
                '• ${toBeginningOfSentenceCase(monthLabel)}',
                style: const TextStyle(
                  color: DuoColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DuoColors.border),
                ),
                child: const Text(
                  'Este mês',
                  style: TextStyle(
                    color: DuoColors.primaryLight,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _SummaryMetric('Entradas', money.format(income), DuoColors.success)),
              Expanded(child: _SummaryMetric('Saídas', '- ${money.format(expense)}', const Color(0xFFFF6333))),
              Expanded(child: _SummaryMetric('Saldo do mês', money.format(balance), DuoColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Row(
              children: [
                Expanded(
                  flex: (ratio * 100).round().clamp(1, 99),
                  child: Container(height: 7, color: DuoColors.success),
                ),
                Expanded(
                  flex: ((1 - ratio) * 100).round().clamp(1, 99),
                  child: Container(height: 7, color: const Color(0xFFFF6333)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${(ratio * 100).round()}% entradas',
                style: const TextStyle(color: DuoColors.success, fontSize: 10),
              ),
              const Spacer(),
              Text(
                '${((1 - ratio) * 100).round()}% saídas',
                style: const TextStyle(color: Color(0xFFFF6333), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryMetric(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: DuoColors.textSecondary, fontSize: 10)),
      const SizedBox(height: 5),
      Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    ],
  );
}

class _UpcomingCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  final NumberFormat money;
  const _UpcomingCard({required this.transactions, required this.money});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 16, color: DuoColors.primaryLight),
              SizedBox(width: 7),
              Text('Próximas movimentações', style: _Styles.sectionTitle),
              Spacer(),
              Text('Ver calendário', style: TextStyle(color: DuoColors.primaryLight, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nenhuma movimentação futura.', style: TextStyle(color: DuoColors.textHint, fontSize: 11)),
            )
          else
            for (var i = 0; i < transactions.length; i++) ...[
              _MovementRow(transaction: transactions[i], money: money),
              if (i != transactions.length - 1)
                const Divider(height: 1, color: DuoColors.divider),
            ],
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  final TransactionModel transaction;
  final NumberFormat money;
  const _MovementRow({required this.transaction, required this.money});

  @override
  Widget build(BuildContext context) {
    final income = transaction.type == 'income';
    final days = transaction.date.difference(DateTime.now()).inDays.abs();
    final color = income ? DuoColors.success : const Color(0xFF7AB5FF);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color.withValues(alpha: .18), shape: BoxShape.circle),
            child: Icon(income ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DuoColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${money.format(transaction.value)} • em $days dias', style: const TextStyle(color: DuoColors.textSecondary, fontSize: 9)),
              ],
            ),
          ),
          Text('${income ? '+' : '-'} ${money.format(transaction.value)}', style: TextStyle(color: income ? DuoColors.success : DuoColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LinkedCardsCard extends StatelessWidget {
  final List<CreditCardModel> cards;
  final NumberFormat money;
  final VoidCallback onManage;
  const _LinkedCardsCard({required this.cards, required this.money, required this.onManage});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              const Text('Cartões vinculados', style: _Styles.sectionTitle),
              const Spacer(),
              InkWell(onTap: onManage, child: const Text('Gerenciar', style: TextStyle(color: DuoColors.primaryLight, fontSize: 10))),
            ],
          ),
          const SizedBox(height: 10),
          if (cards.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nenhum cartão vinculado.', style: TextStyle(color: DuoColors.textHint, fontSize: 11)),
            )
          else
            for (final card in cards.take(2))
              Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF151725),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DuoColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF9D2E)]),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(card.name, style: const TextStyle(color: DuoColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(card.lastFourDigits == null ? 'Final não informado' : 'Final ${card.lastFourDigits}', style: const TextStyle(color: DuoColors.textSecondary, fontSize: 9)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Fatura atual', style: TextStyle(color: DuoColors.textSecondary, fontSize: 9)),
                        Text(money.format(card.usedLimit), style: const TextStyle(color: Color(0xFFFF6333), fontSize: 11, fontWeight: FontWeight.w700)),
                        Text('Vence dia ${card.dueDay}', style: const TextStyle(color: DuoColors.primaryLight, fontSize: 8)),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, color: DuoColors.textHint, size: 18),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _WalletShortcuts extends StatelessWidget {
  final VoidCallback onStatement;
  const _WalletShortcuts({required this.onStatement});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.track_changes_rounded, 'Metas conectadas', 'Ver metas'),
      (Icons.savings_outlined, 'Cofrinhos', 'Ver cofrinhos'),
      (Icons.pie_chart_outline_rounded, 'Investimentos', 'Acompanhar'),
      (Icons.category_outlined, 'Categorias', 'Ver gastos'),
    ];
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Atalhos da carteira', style: _Styles.sectionTitle),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: i == 3 ? onStatement : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: DuoColors.primary.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(items[i].$1, color: DuoColors.primaryLight, size: 18),
                          ),
                          const SizedBox(height: 5),
                          Text(items[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: DuoColors.textPrimary, fontSize: 8)),
                          Text(items[i].$3, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: DuoColors.textSecondary, fontSize: 7)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  final List<TransactionModel> transactions;
  final NumberFormat money;
  const _TransactionsTab({required this.transactions, required this.money});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(child: Text('Nenhuma transação.', style: TextStyle(color: DuoColors.textSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: transactions.length,
      separatorBuilder: (_, _) => const Divider(color: DuoColors.divider),
      itemBuilder: (_, index) {
        final transaction = transactions[index];
        final income = transaction.type == 'income';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: (income ? DuoColors.success : DuoColors.primary).withValues(alpha: .16),
            child: Icon(income ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: income ? DuoColors.success : DuoColors.primaryLight),
          ),
          title: Text(transaction.description, style: const TextStyle(color: DuoColors.textPrimary, fontSize: 13)),
          subtitle: Text(DateFormat('dd/MM/yyyy').format(transaction.date), style: const TextStyle(color: DuoColors.textSecondary, fontSize: 10)),
          trailing: Text('${income ? '+' : '-'} ${money.format(transaction.value)}', style: TextStyle(color: income ? DuoColors.success : DuoColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
        );
      },
    );
  }
}

class _StatisticsTab extends StatelessWidget {
  final double income;
  final double expense;
  final NumberFormat money;
  const _StatisticsTab({required this.income, required this.expense, required this.money});

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    final ratio = total == 0 ? 0.0 : income / total;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Estatísticas do mês', style: TextStyle(color: DuoColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Entradas: ${money.format(income)}', style: const TextStyle(color: DuoColors.success)),
              const SizedBox(height: 10),
              Text('Saídas: ${money.format(expense)}', style: const TextStyle(color: Color(0xFFFF6333))),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: ratio, minHeight: 8, backgroundColor: const Color(0xFFFF6333), valueColor: const AlwaysStoppedAnimation(DuoColors.success)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF11131C),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: DuoColors.border),
    ),
    child: child,
  );
}

class _WalletBottomBar extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onFinance;
  final VoidCallback onAdd;
  const _WalletBottomBar({required this.onHome, required this.onFinance, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.paddingOf(context).bottom + 7),
      decoration: const BoxDecoration(
        color: Color(0xFF0E1018),
        border: Border(top: BorderSide(color: DuoColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomItem(icon: Icons.home_outlined, label: 'Início', onTap: onHome),
          _BottomItem(icon: Icons.account_balance_wallet_rounded, label: 'Finanças', active: true, onTap: onFinance),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: DuoColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: DuoColors.primaryGlow,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 29),
            ),
          ),
          const _BottomItem(icon: Icons.check_box_outlined, label: 'Rotinas'),
          const _BottomItem(icon: Icons.auto_awesome_outlined, label: 'IA'),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _BottomItem({required this.icon, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      width: 58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? DuoColors.primaryLight : DuoColors.textHint, size: 20),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: active ? DuoColors.primaryLight : DuoColors.textHint, fontSize: 9)),
        ],
      ),
    ),
  );
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleIcon({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF11131C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DuoColors.border),
      ),
      child: Icon(icon, color: DuoColors.primaryLight, size: 18),
    ),
  );
}

class _Styles {
  static const sectionTitle = TextStyle(
    color: DuoColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
}
