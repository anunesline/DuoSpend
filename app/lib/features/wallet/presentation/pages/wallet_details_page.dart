import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../financial_intelligence/presentation/pages/insights_page.dart';
import '../../../goals/presentation/pages/savings_goals_page.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../reports/presentation/pages/category_report_page.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/domain/calendar/financial_calendar_entry.dart';
import '../../../transactions/presentation/pages/financial_calendar_page.dart';
import '../../../transactions/presentation/pages/transaction_detail_page.dart';
import '../controllers/wallet_details_controller.dart';
import 'credit_cards_page.dart';

// Palette and geometry are local to this reference, not inherited from the Home.
const _background = Color(0xFF07080F);
const _surface = Color(0xFF0E101A);
const _border = Color(0xFF242333);
const _purple = Color(0xFFAC76F6);
const _muted = Color(0xFFAAA8B3);
const _green = Color(0xFF42C94B);
const _orange = Color(0xFFFF591E);
const _white = Color(0xFFF6F5F8);
const _title = TextStyle(
  fontSize: 12,
  color: _white,
  fontWeight: FontWeight.w500,
);

class WalletDetailsPage extends StatefulWidget {
  final WalletModel wallet;
  final List<WalletModel> individualWallets;
  final String? currentUserId;
  final Future<void> Function()? onAdd;
  final Future<void> Function()? onRoutines;
  final WalletDetailsController? controller;

  const WalletDetailsPage({
    super.key,
    required this.wallet,
    this.individualWallets = const [],
    this.currentUserId,
    this.onAdd,
    this.onRoutines,
    this.controller,
  });

  @override
  State<WalletDetailsPage> createState() => _WalletDetailsPageState();
}

class _WalletDetailsPageState extends State<WalletDetailsPage>
    with SingleTickerProviderStateMixin {
  late final WalletDetailsController _controller;
  late final TabController _tabs;
  final _formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  WalletModel get wallet => _controller.data.wallet;
  String _money(double value) =>
      _controller.valuesVisible ? _formatter.format(value) : 'R\$ ••••';
  String _signed(double value) => _controller.valuesVisible
      ? '${value < 0 ? '−' : '+'} ${_money(value.abs())}'
      : 'R\$ ••••';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _controller =
        widget.controller ?? WalletDetailsController(wallet: widget.wallet);
    _controller.load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) await _controller.load();
  }

  Future<void> _run(Future<void> Function()? action, String name) async {
    if (action == null) {
      _unavailable(name);
      return;
    }
    await action();
    if (mounted) await _controller.load();
  }

  void _unavailable(String name) =>
      _message('$name ainda não está disponível nesta carteira.');

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _calendar() => _open(
    FinancialCalendarPage(
      wallet: wallet,
      transactions: _controller.data.transactions,
    ),
  );

  void _cards() =>
      _open(CreditCardsPage(individualWallets: widget.individualWallets));

  void _goals() {
    final userId = widget.currentUserId;
    if (userId == null || userId.isEmpty) {
      _message('Entre na sua conta para acessar as metas.');
      return;
    }
    _open(
      SavingsGoalsPage(
        contextWallet: wallet,
        individualWallets: widget.individualWallets,
        currentUserId: userId,
      ),
    );
  }

  void _details(TransactionModel transaction) =>
      _open(TransactionDetailPage(transaction: transaction));

  Future<void> _choosePeriod() async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in [
              (0, 'Este mês'),
              (1, 'Mês passado'),
              (2, 'Escolher período'),
            ])
              ListTile(
                title: Text(option.$2),
                onTap: () => Navigator.pop(context, option.$1),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice < 2) {
      final now = _controller.today;
      final month = DateTime(now.year, now.month - choice);
      _controller.selectPeriod(month, DateTime(month.year, month.month + 1, 0));
      return;
    }
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
      initialDateRange: DateTimeRange(
        start: _controller.periodStart,
        end: _controller.periodEnd,
      ),
      helpText: 'Escolher período',
      saveText: 'Aplicar',
    );
    if (mounted && range != null)
      _controller.selectPeriod(range.start, range.end);
  }

  String get _periodButton {
    final now = _controller.today;
    final start = _controller.periodStart;
    final end = _controller.periodEnd;
    final isMonth =
        start.day == 1 && end == DateTime(start.year, start.month + 1, 0);
    if (isMonth && start == DateTime(now.year, now.month)) return 'Este mês';
    if (isMonth && start == DateTime(now.year, now.month - 1))
      return 'Mês passado';
    return 'Período';
  }

  String get _periodLabel {
    final start = _controller.periodStart;
    final end = _controller.periodEnd;
    if (start.day == 1 && end == DateTime(start.year, start.month + 1, 0)) {
      return toBeginningOfSentenceCase(
        DateFormat("MMMM 'de' yyyy", 'pt_BR').format(start),
      );
    }
    return '${DateFormat('dd/MM/yy').format(start)} – ${DateFormat('dd/MM/yy').format(end)}';
  }

  Future<void> _settings() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: _surface,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informações da carteira', style: _title),
            const SizedBox(height: 16),
            Text(wallet.name),
            const SizedBox(height: 8),
            Text(
              wallet.isShared
                  ? 'Carteira compartilhada'
                  : 'Carteira individual',
              style: const TextStyle(color: _muted),
            ),
            const SizedBox(height: 8),
            Text(
              '${wallet.memberCount} participante(s)',
              style: const TextStyle(color: _muted),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _more() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: _surface,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in <(IconData, String, VoidCallback)>[
            (Icons.description_outlined, 'Extrato', () => _tabs.animateTo(1)),
            (Icons.calendar_month_outlined, 'Calendário', _calendar),
            (Icons.credit_card_outlined, 'Cartões', _cards),
            (Icons.track_changes, 'Metas', _goals),
          ])
            ListTile(
              leading: Icon(item.$1, color: _purple),
              title: Text(item.$2),
              onTap: () {
                Navigator.pop(sheetContext);
                item.$3();
              },
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: _background,
      textTheme: ThemeData.dark().textTheme.copyWith(
        bodyMedium: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          height: 1.2,
          letterSpacing: 0,
          color: _white,
        ),
      ),
      colorScheme: const ColorScheme.dark(primary: _purple, surface: _surface),
      dividerColor: _border,
    ),
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(),
              _tabBar(),
              Expanded(
                child: _controller.loading
                    ? const Center(
                        child: CircularProgressIndicator(color: _purple),
                      )
                    : _controller.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _controller.error!,
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: _controller.load,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : TabBarView(
                        controller: _tabs,
                        children: [_overview(), _transactions(), _statistics()],
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _bottomBar(),
      ),
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    child: Row(
      children: [
        _IconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Voltar',
          onTap: () => Navigator.pop(context),
          round: true,
        ),
        const SizedBox(width: 10),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF231735),
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: Text(
            wallet.name.trim().isEmpty
                ? 'C'
                : wallet.name.trim().characters.first.toUpperCase(),
            style: const TextStyle(
              fontSize: 17,
              color: _purple,
              fontWeight: FontWeight.w600,
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
                  fontSize: 16,
                  color: _white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                wallet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: _white),
              ),
            ],
          ),
        ),
        _IconButton(
          icon: Icons.bar_chart_rounded,
          label: 'Estatísticas',
          onTap: () => _tabs.animateTo(2),
        ),
        const SizedBox(width: 8),
        _IconButton(
          icon: Icons.settings_outlined,
          label: 'Informações da carteira',
          onTap: _settings,
        ),
      ],
    ),
  );

  Widget _tabBar() => Container(
    height: 36,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 11),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _border),
    ),
    child: TabBar(
      controller: _tabs,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      labelPadding: EdgeInsets.zero,
      indicator: BoxDecoration(
        color: const Color(0xFF201C30),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF39304F)),
      ),
      labelColor: const Color(0xFFD0ADFF),
      unselectedLabelColor: _muted,
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      tabs: const [
        Tab(text: 'Visão geral'),
        Tab(text: 'Transações'),
        Tab(text: 'Estatísticas'),
      ],
    ),
  );

  Widget _overview() => RefreshIndicator(
    onRefresh: _controller.load,
    child: ListView(
      key: const PageStorageKey('wallet-overview'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        _balanceCard(),
        const SizedBox(height: 11),
        _summary(),
        const SizedBox(height: 11),
        _upcoming(),
        const SizedBox(height: 11),
        _linkedCards(),
        const SizedBox(height: 11),
        _shortcuts(),
      ],
    ),
  );

  Widget _balanceCard() => _Surface(
    padding: EdgeInsets.zero,
    glow: true,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Saldo disponível',
                              style: TextStyle(fontSize: 11, color: _white),
                            ),
                          ),
                          SizedBox(
                            width: 28,
                            height: 26,
                            child: IconButton(
                              tooltip: _controller.valuesVisible
                                  ? 'Ocultar valores'
                                  : 'Mostrar valores',
                              padding: EdgeInsets.zero,
                              onPressed: _controller.toggleVisibility,
                              icon: Icon(
                                _controller.valuesVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 17,
                                color: _white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      _Amount(_money(wallet.balance), size: 27),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _signed(_controller.currentMonthChange),
                            style: TextStyle(
                              fontSize: 11,
                              color: _controller.currentMonthChange < 0
                                  ? _orange
                                  : _green,
                            ),
                          ),
                          const Text(
                            'neste mês',
                            style: TextStyle(fontSize: 10, color: _muted),
                          ),
                          Icon(
                            _controller.currentMonthChange < 0
                                ? Icons.south_east
                                : Icons.north_east,
                            size: 12,
                            color: _controller.currentMonthChange < 0
                                ? _orange
                                : _green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  color: const Color(0xFF30293F),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Saldo previsto',
                              style: TextStyle(fontSize: 10, color: _white),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Tooltip(
                            message: 'Saldo atual mais movimentações pendentes e faturas até o fim do mês. Projeções seguem o calendário financeiro.',
                            child: const Icon(
                              Icons.info_outline,
                              size: 11,
                              color: Color(0xFFD9C0EF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      _Amount(
                        _money(_controller.forecast.projectedBalance),
                        size: 21,
                        color: _purple,
                      ),
                      const SizedBox(height: 7),
                      InkWell(
                        onTap: _calendar,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Até ${DateFormat("d 'de' MMMM", 'pt_BR').format(_controller.monthEnd)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _muted,
                                ),
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF49325E),
                                ),
                              ),
                              child: const Icon(
                                Icons.chevron_right,
                                color: _purple,
                                size: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: _border),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 13, 10, 11),
          child: Row(
            children: [
              for (final action in <(IconData, String, VoidCallback)>[
                (
                  Icons.sync_alt,
                  'Transferir',
                  () => _unavailable('Transferência bancária'),
                ),
                (Icons.qr_code, 'Pix', () => _unavailable('Pix bancário')),
                (
                  Icons.save_alt,
                  'Depositar',
                  () => _unavailable('Depósito bancário'),
                ),
                (
                  Icons.description_outlined,
                  'Extrato',
                  () => _tabs.animateTo(1),
                ),
                (Icons.more_horiz, 'Mais', _more),
              ])
                Expanded(
                  child: InkWell(
                    onTap: action.$3,
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF231C37),
                            border: Border.all(color: const Color(0xFF3F2D58)),
                          ),
                          child: Icon(action.$1, size: 23, color: _purple),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          action.$2,
                          style: const TextStyle(fontSize: 10, color: _white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _periodControl() => InkWell(
    onTap: _choosePeriod,
    borderRadius: BorderRadius.circular(9),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF342642)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _periodButton,
            style: const TextStyle(fontSize: 10, color: _purple),
          ),
          const SizedBox(width: 7),
          const Icon(Icons.keyboard_arrow_down, color: _purple, size: 15),
        ],
      ),
    ),
  );

  Widget _summary() {
    final income = _controller.income;
    final expense = _controller.expense;
    final showValues = _controller.valuesVisible;
    final incomePercent = (_controller.incomeRatio * 100).round();
    final expensePercent = income + expense == 0 ? 0 : 100 - incomePercent;
    final start = _controller.periodStart;
    final isMonth =
        start.day == 1 &&
        _controller.periodEnd == DateTime(start.year, start.month + 1, 0);
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 3,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isMonth ? 'Resumo do mês' : 'Resumo do período',
                      style: _title,
                    ),
                    Text(
                      '• $_periodLabel',
                      style: const TextStyle(fontSize: 10, color: _muted),
                    ),
                    const Tooltip(
                      message: 'Entradas e saídas que já movimentaram o saldo no período.',
                      child: Icon(Icons.info_outline, color: _muted, size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              _periodControl(),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _metric('Entradas', _money(income), _green)),
                const VerticalDivider(width: 26, color: _border),
                Expanded(
                  child: _metric(
                    'Saídas',
                    showValues ? '− ${_money(expense)}' : _money(expense),
                    _orange,
                  ),
                ),
                const VerticalDivider(width: 26, color: _border),
                Expanded(
                  child: _metric(
                    isMonth ? 'Saldo do mês' : 'Saldo do período',
                    _money(income - expense),
                    _white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 9,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF201C2E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: showValues && income + expense > 0
                ? Row(
                    children: [
                      if (income > 0)
                        Expanded(
                          flex: (_controller.incomeRatio * 10000).round().clamp(
                            1,
                            10000,
                          ),
                          child: Container(color: _green),
                        ),
                      if (expense > 0)
                        Expanded(
                          flex: (_controller.expenseRatio * 10000)
                              .round()
                              .clamp(1, 10000),
                          child: Container(color: _orange),
                        ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${showValues ? '$incomePercent%' : '••'} entradas',
                style: const TextStyle(fontSize: 10, color: _green),
              ),
              Text(
                '${showValues ? '$expensePercent%' : '••'} saídas',
                style: const TextStyle(fontSize: 10, color: _orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 10, color: color == _white ? _muted : color),
      ),
      const SizedBox(height: 6),
      _Amount(value, size: 14, color: color),
    ],
  );

  String _due(DateTime date, {bool income = false}) {
    final days = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(_controller.today).inDays;
    if (days < 0) return 'Venceu há ${-days} dia${days == -1 ? '' : 's'}';
    final verb = income ? 'Recebe' : 'Vence';
    if (days == 0) return '$verb hoje';
    if (days == 1) return '$verb amanhã';
    return '$verb em $days dias';
  }

  Widget _sectionHeader(
    String title,
    String action,
    VoidCallback onTap, {
    IconData? icon,
  }) => Row(
    children: [
      if (icon != null) ...[
        Icon(icon, color: _purple, size: 15),
        const SizedBox(width: 7),
      ],
      Expanded(child: Text(title, style: _title)),
      const SizedBox(width: 4),
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            action,
            style: const TextStyle(fontSize: 10, color: _purple),
          ),
        ),
      ),
    ],
  );

  Widget _upcoming() {
    final entries = _controller.upcoming;
    return _Surface(
      child: Column(
        children: [
          _sectionHeader(
            'Próximas movimentações',
            'Ver calendário',
            _calendar,
            icon: Icons.calendar_month_outlined,
          ),
          const SizedBox(height: 4),
          if (entries.isEmpty)
            _empty('Nenhuma movimentação prevista nos próximos 12 meses.'),
          for (var i = 0; i < entries.length; i++) ...[
            _movement(entries[i]),
            if (i < entries.length - 1)
              const Divider(height: 1, color: _border),
          ],
        ],
      ),
    );
  }

  Widget _movement(FinancialCalendarEntry entry) {
    final invoice = entry.kind == FinancialCalendarEntryKind.creditCardInvoice;
    final color = invoice
        ? const Color(0xFFD58B17)
        : entry.isIncome
        ? _green
        : const Color(0xFF70AFE9);
    var name = entry.title;
    if (invoice) {
      for (final card in _controller.data.cards) {
        if (card.id == entry.referenceId) name = card.name;
      }
    }
    return InkWell(
      onTap: invoice
          ? _cards
          : entry.transaction != null
          ? () => _details(entry.transaction!)
          : _calendar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: .95),
                    color.withValues(alpha: .6),
                  ],
                ),
              ),
              child: Icon(
                invoice
                    ? Icons.credit_card
                    : entry.isIncome
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 20,
                color: Color.lerp(color, Colors.white, .5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: _white),
                  ),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Valor: ${_money(entry.value)} • '),
                        TextSpan(
                          text: _due(entry.date, income: entry.isIncome),
                          style: const TextStyle(color: Color(0xFFC49BF5)),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 9, color: _muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: _Amount(
                  _signed(entry.signedValue),
                  size: 12,
                  color: entry.isIncome ? _green : _white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkedCards() => _Surface(
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: _sectionHeader('Cartões vinculados', 'Gerenciar', _cards),
        ),
        const SizedBox(height: 8),
        if (_controller.data.cards.isEmpty) _empty('Nenhum cartão vinculado.'),
        for (final card in _controller.data.cards)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              onTap: _cards,
              borderRadius: BorderRadius.circular(12),
              child: _Surface(
                padding: const EdgeInsets.all(10),
                glow: true,
                child: Row(
                  children: [
                    Container(
                      width: 57,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3F2A5B), Color(0xFF201B35)],
                        ),
                      ),
                      child: const Icon(
                        Icons.credit_card,
                        color: _purple,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.name,
                            style: const TextStyle(fontSize: 11, color: _white),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            card.lastFourDigits == null
                                ? 'Final não informado'
                                : 'Final ${card.lastFourDigits}',
                            style: const TextStyle(fontSize: 9, color: _muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(flex: 2, child: _invoiceInfo(card.id)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: _muted, size: 18),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _invoiceInfo(String cardId) {
    final invoice = _controller.currentInvoice(cardId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fatura atual',
          style: TextStyle(fontSize: 9, color: _muted),
        ),
        const SizedBox(height: 3),
        if (invoice == null)
          const Text(
            'Sem fatura em aberto',
            style: TextStyle(fontSize: 10, color: _muted),
          )
        else ...[
          _Amount(_money(invoice.total), size: 12, color: _orange),
          const SizedBox(height: 3),
          Text(
            _due(invoice.dueDate),
            style: const TextStyle(fontSize: 9, color: Color(0xFFC49BF5)),
          ),
        ],
      ],
    );
  }

  Widget _shortcuts() {
    final items = <(IconData, String, String, Color, VoidCallback)>[
      (
        Icons.track_changes,
        'Metas\nconectadas',
        '${_controller.activeGoalCount} metas',
        _purple,
        _goals,
      ),
      (
        Icons.savings_outlined,
        'Cofrinhos',
        'Indisponível',
        const Color(0xFF60A5F5),
        () => _unavailable('Cofrinhos'),
      ),
      (
        Icons.pie_chart_outline,
        'Investimentos',
        'Indisponível',
        _green,
        () => _unavailable('Investimentos'),
      ),
      (
        Icons.donut_large,
        'Categorias',
        'Ver gastos',
        const Color(0xFFE8AC35),
        () => _tabs.animateTo(2),
      ),
    ];
    return _Surface(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Atalhos da carteira', style: _title),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  constraints.maxWidth < 310 ||
                      MediaQuery.textScalerOf(context).scale(10) > 14
                  ? 2
                  : 4;
              final width =
                  (constraints.maxWidth - (columns - 1) * 5) / columns;
              return Wrap(
                spacing: 5,
                runSpacing: 6,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: width,
                      child: InkWell(
                        onTap: item.$5,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 53),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF191B26), Color(0xFF10121C)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 25,
                                height: 25,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: item.$4.withValues(alpha: .12),
                                ),
                                child: Icon(item.$1, color: item.$4, size: 21),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.$2,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: _white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.$3,
                                      style: const TextStyle(
                                        fontSize: 7.5,
                                        color: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _transactions() {
    final transactions = _controller.periodTransactions;
    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
        children: [
          Row(
            children: [
              Expanded(child: Text(_periodLabel, style: _title)),
              _periodControl(),
            ],
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty) _empty('Nenhuma transação neste período.'),
          for (final transaction in transactions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => _details(transaction),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF231C37),
                child: Icon(
                  transaction.type == 'income'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: transaction.type == 'income' ? _green : _purple,
                ),
              ),
              title: Text(
                transaction.description,
                style: const TextStyle(fontSize: 13, color: _white),
              ),
              subtitle: Text(
                '${DateFormat('dd/MM/yyyy').format(transaction.date)} • ${transaction.isFinanciallyPending
                    ? 'Pendente'
                    : transaction.isSettledByInvoice
                    ? 'Na fatura'
                    : 'Concluída'}',
                style: const TextStyle(fontSize: 10, color: _muted),
              ),
              trailing: Text(
                _signed(
                  transaction.type == 'income'
                      ? transaction.value
                      : -transaction.value,
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: transaction.type == 'income' ? _green : _white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statistics() {
    final report = _controller.categoryReport;
    final categories = report.expenseByCategory;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
      children: [
        _summary(),
        const SizedBox(height: 12),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gastos por categoria', style: _title),
              const SizedBox(height: 8),
              if (categories.isEmpty) _empty('Nenhuma despesa neste período.'),
              for (final category in categories)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    category.category,
                    style: const TextStyle(fontSize: 12, color: _white),
                  ),
                  trailing: Text(
                    _money(category.amount),
                    style: const TextStyle(color: _purple),
                  ),
                  onTap: () => _open(
                    CategoryReportPage(
                      category: category.category,
                      startDate: _controller.periodStart,
                      endDate: _controller.periodEnd,
                      transactions: report.transactions,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 11, color: _muted),
    ),
  );

  Widget _bottomBar() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: _background,
      border: Border.all(color: _border),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 9),
        child: Row(
          children: [
            _navItem(
              Icons.home_outlined,
              'Início',
              () => Navigator.pop(context),
            ),
            _navItem(
              Icons.account_balance_wallet,
              'Finanças',
              _more,
              active: true,
            ),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -6),
                child: Align(alignment: Alignment.topCenter, heightFactor: 1,
                  child: InkWell(
                    onTap: () => _run(widget.onAdd, 'Nova transação'),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          center: Alignment(-.4, -.5),
                          radius: 1.3,
                          colors: [Color(0xFFAC72EB), Color(0xFF622CAD)],
                        ),
                        border: Border.all(color: const Color(0xFFBC88F6)),
                        boxShadow: [
                          BoxShadow(
                            color: _purple.withValues(alpha: .16),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: const Tooltip(
                        message: 'Nova transação',
                        child: Icon(Icons.add, color: Colors.white, size: 34),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _navItem(
              Icons.check_box_outlined,
              'Rotinas',
              () => _run(widget.onRoutines, 'Rotinas'),
            ),
            _navItem(
              Icons.auto_awesome_outlined,
              'IA',
              () => _open(InsightsPage(wallet: wallet)),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _navItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
  }) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: active ? _purple : _muted),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: active ? _purple : _muted),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Amount extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  const _Amount(this.text, {required this.size, this.color = _white});

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      maxLines: 1,
      style: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w400,
      ),
    ),
  );
}

class _Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool glow;
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(13),
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: glow
            ? const [Color(0xFF191629), Color(0xFF0F101C)]
            : const [Color(0xFF10121C), Color(0xFF0D0F18)],
      ),
      border: Border.all(
        color: glow ? const Color(0xFF322740) : _border,
        width: .6,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool round;
  const _IconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.round = false,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(round ? 30 : 9),
      child: Container(
        width: round ? 32 : 28,
        height: round ? 32 : 28,
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D16),
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(round ? 30 : 9),
        ),
        child: Icon(icon, color: _purple, size: 19),
      ),
    ),
  );
}
