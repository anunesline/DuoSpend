import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../domain/models/financial_report.dart';
import '../../domain/services/financial_report_service.dart';

class MonthlyReportPage extends StatefulWidget {
  final WalletModel wallet;
  final List<TransactionModel> transactions;

  const MonthlyReportPage({
    super.key,
    required this.wallet,
    required this.transactions,
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

  final FinancialReportService _reportService =
      const FinancialReportService();

  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  FinancialReport get _report {
    return _reportService.buildMonthly(
      transactions: widget.transactions,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );
  }

  String get _monthLabel {
    final label = DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth);

    return '${label[0].toUpperCase()}${label.substring(1)}';
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
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
    final report = _report;

    return Scaffold(
      backgroundColor: DuoColors.background,
      appBar: AppBar(
        backgroundColor: DuoColors.background,
        foregroundColor: DuoColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Relatório mensal',
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
            const SizedBox(height: 20),
            _BalanceSummaryCard(
              report: report,
              formatMoney: _formatMoney,
            ),
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
                    for (var index = 0;
                        index < report.expenseByCategory.length;
                        index++) ...[
                      _CategoryRow(
                        item: report.expenseByCategory[index],
                        color: _categoryColors[
                            index % _categoryColors.length],
                        formattedAmount: _formatMoney(
                          report.expenseByCategory[index].amount,
                        ),
                      ),
                      if (index != report.expenseByCategory.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(
                            height: 1,
                            color: DuoColors.divider,
                          ),
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
                    for (var index = 0;
                        index < report.transactions.length;
                        index++) ...[
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

class _BalanceSummaryCard extends StatelessWidget {
  final FinancialReport report;
  final String Function(double) formatMoney;

  const _BalanceSummaryCard({
    required this.report,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = report.balance >= 0;
    final balanceColor =
        isPositive ? DuoColors.success : DuoColors.error;

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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

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
          style: const TextStyle(
            color: DuoColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final FinancialCategoryTotal item;
  final Color color;
  final String formattedAmount;

  const _CategoryRow({
    required this.item,
    required this.color,
    required this.formattedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (item.percentage / 100).clamp(0.0, 1.0);

    return Column(
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
              isIncome
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
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
