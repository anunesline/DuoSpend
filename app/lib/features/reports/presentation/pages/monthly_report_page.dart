import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../domain/models/financial_report.dart';
import '../../domain/services/financial_report_service.dart';
import 'category_report_page.dart';

const _reportMonthNames = [
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

String _reportMonthName(DateTime date, {bool abbreviated = false}) {
  final name = _reportMonthNames[date.month - 1];

  if (!abbreviated) {
    return name;
  }

  return name.substring(0, 3).toUpperCase();
}

class MonthlyReportPage extends StatefulWidget {
  final WalletModel wallet;
  final List<TransactionModel> transactions;
  final String? currentUserId;

  const MonthlyReportPage({
    super.key,
    required this.wallet,
    required this.transactions,
    this.currentUserId,
  });

  @override
  State<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  static const _categoryColors = [
    DuoColors.primaryLight,
    DuoColors.success,
    DuoColors.warning,
    Color(0xFF60A5FA),
    Color(0xFFF472B6),
    Color(0xFFFB923C),
  ];

  final FinancialReportService _reportService = const FinancialReportService();

  late DateTime _selectedMonth;

  DateTimeRange? _customPeriod;
  String? _selectedCategory;
  String? _selectedType;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  FinancialReport get _filteredReport {
    final customPeriod = _customPeriod;

    if (customPeriod != null) {
      return _reportService.build(
        transactions: widget.transactions,
        startDate: customPeriod.start,
        endDate: customPeriod.end,
        category: _selectedCategory,
        transactionType: _selectedType,
      );
    }

    return _reportService.buildMonthly(
      transactions: widget.transactions,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
      category: _selectedCategory,
      transactionType: _selectedType,
    );
  }

  FinancialReportComparison get _comparison {
    return _reportService.compareMonthly(
      transactions: widget.transactions,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
      category: _selectedCategory,
      transactionType: _selectedType,
    );
  }

  List<MonthlyFinancialPoint> get _evolution {
    return _reportService.buildMonthlyEvolution(
      transactions: widget.transactions,
      endYear: _selectedMonth.year,
      endMonth: _selectedMonth.month,
      category: _selectedCategory,
      transactionType: _selectedType,
    );
  }

  List<String> get _availableCategories {
    final categories =
        widget.transactions
            .map((transaction) => transaction.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return List.unmodifiable(categories);
  }

  int get _activeFilterCount {
    var count = 0;

    if (_customPeriod != null) {
      count++;
    }

    if (_selectedCategory != null) {
      count++;
    }

    if (_selectedType != null) {
      count++;
    }

    return count;
  }

  String get _monthLabel {
    final customPeriod = _customPeriod;

    if (customPeriod != null) {
      return '${DateFormat('dd/MM/yyyy').format(customPeriod.start)}'
          ' – '
          '${DateFormat('dd/MM/yyyy').format(customPeriod.end)}';
    }

    final month = _reportMonthName(_selectedMonth);
    final label = '$month ${_selectedMonth.year}';

    return '${label[0].toUpperCase()}${label.substring(1)}';
  }

  void _changeMonth(int offset) {
    setState(() {
      _customPeriod = null;
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
  }

  Future<void> _showFilters() async {
    var draftPeriod = _customPeriod;
    var draftCategory = _selectedCategory;
    var draftType = _selectedType;

    final shouldApply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final periodLabel = draftPeriod == null
                ? 'Mês selecionado'
                : '${DateFormat('dd/MM/yyyy').format(draftPeriod!.start)}'
                      ' – '
                      '${DateFormat('dd/MM/yyyy').format(draftPeriod!.end)}';

            return AlertDialog(
              title: const Text('Filtrar relatório'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Período',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final pickedPeriod = await showDateRangePicker(
                          context: dialogContext,
                          initialDateRange: draftPeriod,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          helpText: 'Selecione o período',
                          cancelText: 'Cancelar',
                          confirmText: 'Aplicar',
                        );

                        if (pickedPeriod == null) {
                          return;
                        }

                        setDialogState(() {
                          draftPeriod = pickedPeriod;
                        });
                      },
                      icon: const Icon(Icons.date_range_rounded),
                      label: Text(periodLabel),
                    ),
                    if (draftPeriod != null)
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            draftPeriod = null;
                          });
                        },
                        child: const Text('Usar mês selecionado'),
                      ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: draftCategory ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Todas as categorias'),
                        ),
                        for (final category in _availableCategories)
                          DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          draftCategory = value == null || value.isEmpty
                              ? null
                              : value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: draftType ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '',
                          child: Text('Receitas e despesas'),
                        ),
                        DropdownMenuItem(
                          value: 'income',
                          child: Text('Somente receitas'),
                        ),
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Somente despesas'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          draftType = value == null || value.isEmpty
                              ? null
                              : value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      draftPeriod = null;
                      draftCategory = null;
                      draftType = null;
                    });
                  },
                  child: const Text('Limpar'),
                ),
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
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldApply != true || !mounted) {
      return;
    }

    setState(() {
      _customPeriod = draftPeriod;
      _selectedCategory = draftCategory;
      _selectedType = draftType;
    });
  }

  void _clearFilters() {
    setState(() {
      _customPeriod = null;
      _selectedCategory = null;
      _selectedType = null;
    });
  }

  Future<void> _openCategoryReport({
    required FinancialReport report,
    required FinancialCategoryTotal category,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryReportPage(
          category: category.category,
          startDate: report.startDate,
          endDate: report.endDate,
          transactions: report.transactions,
        ),
      ),
    );
  }

  String _formatMoney(double value) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final comparison = _comparison;
    final evolution = _evolution;
    final report = _filteredReport;
    final sharedReport = widget.wallet.isShared
        ? _reportService.buildSharedResponsibility(
            report: report,
            memberIds: widget.wallet.memberIds,
          )
        : null;

    return Scaffold(
      backgroundColor: DuoColors.background,
      appBar: AppBar(
        backgroundColor: DuoColors.background,
        foregroundColor: DuoColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Relatórios',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _WalletLabel(wallet: widget.wallet),
            const SizedBox(height: 18),
            _MonthSelector(
              label: _monthLabel,
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
            const SizedBox(height: 12),
            _FilterToolbar(
              activeFilterCount: _activeFilterCount,
              selectedCategory: _selectedCategory,
              selectedType: _selectedType,
              hasCustomPeriod: _customPeriod != null,
              onFilter: _showFilters,
              onClear: _clearFilters,
            ),
            const SizedBox(height: 20),
            _BalanceSummaryCard(report: report, formatMoney: _formatMoney),
            const SizedBox(height: 12),
            _ReportInsightCard(report: report, formatMoney: _formatMoney),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ValueCard(
                    label: 'Receitas',
                    value: _formatMoney(report.totalIncome),
                    icon: Icons.south_west_rounded,
                    color: DuoColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ValueCard(
                    label: 'Despesas',
                    value: _formatMoney(report.totalExpense),
                    icon: Icons.north_east_rounded,
                    color: DuoColors.error,
                  ),
                ),
              ],
            ),
            if (sharedReport != null) ...[
              const SizedBox(height: 20),
              _SharedResponsibilityCard(
                report: sharedReport,
                wallet: widget.wallet,
                currentUserId: widget.currentUserId,
                formatMoney: _formatMoney,
              ),
            ],
            if (_customPeriod == null) ...[
              const SizedBox(height: 20),
              _MonthlyComparisonCard(
                comparison: comparison,
                formatMoney: _formatMoney,
              ),
              const SizedBox(height: 20),
              _FinancialEvolutionCard(
                points: evolution,
                formatMoney: _formatMoney,
              ),
            ],
            const SizedBox(height: 28),
            const _SectionTitle(
              title: 'Gastos por categoria',
              subtitle: 'Distribuição das despesas liquidadas',
            ),
            const SizedBox(height: 14),
            if (report.expenseByCategory.isEmpty)
              const _EmptyCategories()
            else
              DuoCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < report.expenseByCategory.length;
                      index++
                    ) ...[
                      _CategoryRow(
                        item: report.expenseByCategory[index],
                        color: _categoryColors[index % _categoryColors.length],
                        formattedAmount: _formatMoney(
                          report.expenseByCategory[index].amount,
                        ),
                        onTap: () {
                          _openCategoryReport(
                            report: report,
                            category: report.expenseByCategory[index],
                          );
                        },
                      ),
                      if (index != report.expenseByCategory.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1, color: DuoColors.divider),
                        ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 28),
            _SectionTitle(
              title: 'Movimentações do mês',
              subtitle: report.transactions.isEmpty
                  ? 'Nenhuma movimentação liquidada'
                  : report.transactions.length == 1
                  ? '1 movimentação considerada'
                  : '${report.transactions.length} movimentações consideradas',
            ),
            const SizedBox(height: 14),
            if (report.transactions.isEmpty)
              const _EmptyTransactions()
            else
              DuoCard(
                borderRadius: 20,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < report.transactions.length;
                      index++
                    ) ...[
                      _TransactionRow(
                        transaction: report.transactions[index],
                        formattedValue: _formatMoney(
                          report.transactions[index].value,
                        ),
                      ),
                      if (index != report.transactions.length - 1)
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: DuoColors.divider,
                        ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WalletLabel extends StatelessWidget {
  final WalletModel wallet;

  const _WalletLabel({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          wallet.isShared
              ? Icons.groups_rounded
              : Icons.account_balance_wallet_rounded,
          size: 16,
          color: DuoColors.textSecondary,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            wallet.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            onPressed: onPrevious,
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: DuoColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DuoColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            onPressed: onNext,
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: DuoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterToolbar extends StatelessWidget {
  final int activeFilterCount;
  final String? selectedCategory;
  final String? selectedType;
  final bool hasCustomPeriod;
  final VoidCallback onFilter;
  final VoidCallback onClear;

  const _FilterToolbar({
    required this.activeFilterCount,
    required this.selectedCategory,
    required this.selectedType,
    required this.hasCustomPeriod,
    required this.onFilter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (hasCustomPeriod) 'Período personalizado',
      ?selectedCategory,
      if (selectedType == 'income') 'Receitas',
      if (selectedType == 'expense') 'Despesas',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onFilter,
                icon: const Icon(Icons.tune_rounded),
                label: Text(
                  activeFilterCount == 0
                      ? 'Filtros'
                      : 'Filtros ($activeFilterCount)',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DuoColors.primaryLight,
                  side: const BorderSide(color: DuoColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (activeFilterCount > 0) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Limpar filtros',
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_rounded),
                color: DuoColors.textSecondary,
              ),
            ],
          ],
        ),
        if (labels.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final label in labels)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DuoColors.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: DuoColors.border),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: DuoColors.primaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  final FinancialReport report;
  final String Function(double) formatMoney;

  const _BalanceSummaryCard({required this.report, required this.formatMoney});

  @override
  Widget build(BuildContext context) {
    final isPositive = report.balance >= 0;
    final balanceColor = isPositive ? DuoColors.success : DuoColors.error;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: DuoColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DuoColors.border),
        boxShadow: DuoColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resultado do mês',
            style: TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatMoney(report.balance),
            style: TextStyle(
              color: balanceColor,
              fontSize: 29,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPositive
                ? 'Você recebeu mais do que gastou.'
                : 'As despesas superaram as receitas.',
            style: const TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ValueCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportInsightCard extends StatelessWidget {
  final FinancialReport report;
  final String Function(double) formatMoney;
  const _ReportInsightCard({required this.report, required this.formatMoney});

  @override
  Widget build(BuildContext context) {
    final label = report.totalExpense <= 0
        ? 'Ainda não há despesas liquidadas neste período.'
        : report.balance >= 0
        ? 'Seu resultado está positivo em ${formatMoney(report.balance)}.'
        : 'O período fechou ${formatMoney(-report.balance)} abaixo das receitas.';
    return DuoCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(15),
      gradient: LinearGradient(
        colors: [DuoColors.primary.withValues(alpha: .20), DuoColors.surface],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: DuoColors.primary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: DuoColors.primaryLight,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insight Orbit',
                  style: TextStyle(
                    color: DuoColors.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _SharedResponsibilityCard extends StatelessWidget {
  final SharedFinancialReport report;
  final WalletModel wallet;
  final String? currentUserId;
  final String Function(double) formatMoney;

  const _SharedResponsibilityCard({
    required this.report,
    required this.wallet,
    required this.currentUserId,
    required this.formatMoney,
  });

  String _memberLabel(MemberFinancialSummary member) {
    if (member.memberId == currentUserId) {
      return 'Você';
    }

    if (member.memberId == wallet.ownerId) {
      return 'Responsável da carteira';
    }

    return 'Parceiro(a)';
  }

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.groups_rounded,
                color: DuoColors.primaryLight,
                size: 20,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Responsabilidade compartilhada',
                  style: TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Compara o que cada pessoa pagou com sua parte financeira.',
            style: TextStyle(color: DuoColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 18),
          if (report.isEmpty)
            const _SharedReportEmpty()
          else
            for (var index = 0; index < report.members.length; index++) ...[
              _MemberResponsibilityRow(
                label: _memberLabel(report.members[index]),
                member: report.members[index],
                formatMoney: formatMoney,
              ),
              if (index != report.members.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: DuoColors.divider),
                ),
            ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DuoColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: DuoColors.textHint,
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'O consumo por item não altera esta divisão. '
                    'Sem divisão financeira, a despesa pertence a quem pagou.',
                    style: TextStyle(
                      color: DuoColors.textSecondary,
                      fontSize: 10,
                      height: 1.35,
                    ),
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

class _MemberResponsibilityRow extends StatelessWidget {
  final String label;
  final MemberFinancialSummary member;
  final String Function(double) formatMoney;

  const _MemberResponsibilityRow({
    required this.label,
    required this.member,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    final net = member.netPosition;
    final netColor = net > 0
        ? DuoColors.success
        : net < 0
        ? DuoColors.error
        : DuoColors.textSecondary;
    final netLabel = net > 0
        ? 'Adiantou'
        : net < 0
        ? 'Ficou responsável'
        : 'Equilibrado';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: DuoColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MemberValue(
                label: 'Pagou',
                value: formatMoney(member.amountPaid),
              ),
            ),
            Expanded(
              child: _MemberValue(
                label: 'Responsabilidade',
                value: formatMoney(member.responsibility),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Icon(
              net == 0
                  ? Icons.check_circle_outline_rounded
                  : net > 0
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: netColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$netLabel: ${formatMoney(net.abs())}',
                style: TextStyle(
                  color: netColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MemberValue extends StatelessWidget {
  final String label;
  final String value;

  const _MemberValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: DuoColors.textHint,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SharedReportEmpty extends StatelessWidget {
  const _SharedReportEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Nenhuma despesa compartilhada neste período.',
        style: TextStyle(color: DuoColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _FinancialEvolutionCard extends StatelessWidget {
  final List<MonthlyFinancialPoint> points;
  final String Function(double) formatMoney;

  const _FinancialEvolutionCard({
    required this.points,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    var maximum = 0.0;

    for (final point in points) {
      if (point.income > maximum) {
        maximum = point.income;
      }

      if (point.expense > maximum) {
        maximum = point.expense;
      }
    }

    return DuoCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evolução financeira',
            style: TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Receitas e despesas dos últimos 6 meses',
            style: TextStyle(color: DuoColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              _LegendDot(label: 'Receitas', color: DuoColors.success),
              SizedBox(width: 16),
              _LegendDot(label: 'Despesas', color: DuoColors.error),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 142,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < points.length; index++)
                  Expanded(
                    child: _EvolutionMonthColumn(
                      point: points[index],
                      maximum: maximum,
                      isSelected: index == points.length - 1,
                      formatMoney: formatMoney,
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

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: DuoColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EvolutionMonthColumn extends StatelessWidget {
  final MonthlyFinancialPoint point;
  final double maximum;
  final bool isSelected;
  final String Function(double) formatMoney;

  const _EvolutionMonthColumn({
    required this.point,
    required this.maximum,
    required this.isSelected,
    required this.formatMoney,
  });

  double _heightFor(double value) {
    if (value <= 0 || maximum <= 0) {
      return 3;
    }

    return 6 + (value / maximum) * 82;
  }

  @override
  Widget build(BuildContext context) {
    final balanceColor = point.balance >= 0
        ? DuoColors.success
        : DuoColors.error;
    final monthLabel = _reportMonthName(point.month, abbreviated: true);

    return Tooltip(
      message: 'Resultado: ${formatMoney(point.balance)}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _EvolutionBar(
                  height: _heightFor(point.income),
                  color: DuoColors.success,
                ),
                const SizedBox(width: 3),
                _EvolutionBar(
                  height: _heightFor(point.expense),
                  color: DuoColors.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              point.balance == 0 ? 'R\$ 0' : formatMoney(point.balance),
              maxLines: 1,
              style: TextStyle(
                color: balanceColor,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            monthLabel,
            style: TextStyle(
              color: isSelected ? DuoColors.primaryLight : DuoColors.textHint,
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionBar extends StatelessWidget {
  final double height;
  final Color color;

  const _EvolutionBar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}

class _MonthlyComparisonCard extends StatelessWidget {
  final FinancialReportComparison comparison;
  final String Function(double) formatMoney;

  const _MonthlyComparisonCard({
    required this.comparison,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    final previousMonth = _reportMonthName(comparison.previous.startDate);

    return DuoCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparativo mensal',
            style: TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Em relação a $previousMonth',
            style: const TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 18),
          _ComparisonMetricRow(
            label: 'Receitas',
            metric: comparison.income,
            formatMoney: formatMoney,
            positiveWhenIncrease: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1, color: DuoColors.divider),
          ),
          _ComparisonMetricRow(
            label: 'Despesas',
            metric: comparison.expense,
            formatMoney: formatMoney,
            positiveWhenIncrease: false,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1, color: DuoColors.divider),
          ),
          _ComparisonMetricRow(
            label: 'Resultado',
            metric: comparison.balance,
            formatMoney: formatMoney,
            positiveWhenIncrease: true,
          ),
        ],
      ),
    );
  }
}

class _ComparisonMetricRow extends StatelessWidget {
  final String label;
  final FinancialMetricComparison metric;
  final String Function(double) formatMoney;
  final bool positiveWhenIncrease;

  const _ComparisonMetricRow({
    required this.label,
    required this.metric,
    required this.formatMoney,
    required this.positiveWhenIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive =
        metric.unchanged ||
        (metric.increased && positiveWhenIncrease) ||
        (metric.decreased && !positiveWhenIncrease);
    final color = metric.unchanged
        ? DuoColors.textSecondary
        : isPositive
        ? DuoColors.success
        : DuoColors.error;
    final icon = metric.unchanged
        ? Icons.remove_rounded
        : metric.increased
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final percentage = metric.percentageChange;
    final changeLabel = percentage == null
        ? 'Sem base anterior'
        : '${percentage.abs().toStringAsFixed(1).replaceAll('.', ',')}%';
    final differencePrefix = metric.difference > 0 ? '+' : '';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: DuoColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatMoney(metric.currentValue),
                style: const TextStyle(
                  color: DuoColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 17),
                const SizedBox(width: 4),
                Text(
                  changeLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$differencePrefix${formatMoney(metric.difference)}',
              style: const TextStyle(
                color: DuoColors.textHint,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: DuoColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: DuoColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final FinancialCategoryTotal item;
  final Color color;
  final String formattedAmount;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.item,
    required this.color,
    required this.formattedAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (item.percentage / 100).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DuoColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    formattedAmount,
                    style: const TextStyle(
                      color: DuoColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: DuoColors.textHint,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: DuoColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${item.percentage.toStringAsFixed(1).replaceAll('.', ',')}%',
                style: const TextStyle(
                  color: DuoColors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel transaction;
  final String formattedValue;

  const _TransactionRow({
    required this.transaction,
    required this.formattedValue,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? DuoColors.success : DuoColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${transaction.category} • '
                  '${DateFormat('dd/MM').format(transaction.date)}',
                  style: const TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${isIncome ? '+' : '-'} $formattedValue',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories();

  @override
  Widget build(BuildContext context) {
    return const _EmptyCard(
      icon: Icons.donut_large_rounded,
      title: 'Sem gastos neste mês',
      subtitle: 'As despesas liquidadas aparecerão por categoria.',
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return const _EmptyCard(
      icon: Icons.receipt_long_outlined,
      title: 'Nenhuma movimentação',
      subtitle: 'Selecione outro mês ou registre uma transação.',
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, color: DuoColors.textHint, size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
