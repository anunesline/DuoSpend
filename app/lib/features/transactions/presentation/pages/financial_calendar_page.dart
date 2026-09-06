import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/calendar/financial_calendar_entry.dart';
import '../controllers/financial_calendar_controller.dart';

class FinancialCalendarPage extends StatefulWidget {
  final WalletModel wallet;
  final List<TransactionModel> transactions;

  const FinancialCalendarPage({
    super.key,
    required this.wallet,
    required this.transactions,
  });

  @override
  State<FinancialCalendarPage> createState() =>
      _FinancialCalendarPageState();
}

class _FinancialCalendarPageState extends State<FinancialCalendarPage> {
  late final FinancialCalendarController controller;
  bool _showValues = true;

  @override
  void initState() {
    super.initState();
    controller = FinancialCalendarController();
    controller.load(
      wallet: widget.wallet,
      transactions: widget.transactions,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String _formatMoney(double value) {
    if (!_showValues) return 'R\$ ••••';
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(value);
  }

  String _monthLabel(DateTime month) {
    final label = DateFormat('MMMM yyyy', 'pt_BR').format(month);
    return '${label[0].toUpperCase()}${label.substring(1)}';
  }

  String _selectedDayLabel(DateTime day) {
    final label = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(day);
    return '${label[0].toUpperCase()}${label.substring(1)}';
  }

  String _entryLabel(FinancialCalendarEntry entry) {
    switch (entry.kind) {
      case FinancialCalendarEntryKind.installment:
        final transaction = entry.transaction;
        if (transaction?.installmentNumber != null &&
            transaction?.installmentCount != null) {
          return 'Parcela ${transaction!.installmentNumber}/'
              '${transaction.installmentCount}';
        }
        return 'Compromisso';
      case FinancialCalendarEntryKind.recurring:
        return 'Recorrência';
      case FinancialCalendarEntryKind.creditCardInvoice:
        return 'Fatura';
      case FinancialCalendarEntryKind.transaction:
        return entry.isIncome ? 'Receita' : 'Despesa';
    }
  }

  Color _entryColor(FinancialCalendarEntry entry) {
    switch (entry.kind) {
      case FinancialCalendarEntryKind.creditCardInvoice:
        return const Color(0xFFFFA726);
      case FinancialCalendarEntryKind.recurring:
        return const Color(0xFF9B6CFF);
      case FinancialCalendarEntryKind.installment:
        return const Color(0xFF4AA3FF);
      case FinancialCalendarEntryKind.transaction:
        return entry.isIncome ? DuoColors.success : DuoColors.error;
    }
  }

  IconData _entryIcon(FinancialCalendarEntry entry) {
    switch (entry.kind) {
      case FinancialCalendarEntryKind.creditCardInvoice:
        return Icons.credit_card_rounded;
      case FinancialCalendarEntryKind.recurring:
        return Icons.event_repeat_rounded;
      case FinancialCalendarEntryKind.installment:
        return Icons.receipt_long_rounded;
      case FinancialCalendarEntryKind.transaction:
        return entry.isIncome
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;
    }
  }

  Future<void> _settleEntry(FinancialCalendarEntry entry) async {
    final isIncome = entry.isIncome;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isIncome ? 'Confirmar recebimento' : 'Confirmar pagamento'),
        content: Text(
          isIncome
              ? 'O valor será creditado na carteira vinculada.'
              : 'O valor será debitado da carteira vinculada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isIncome ? 'Recebi' : 'Paguei'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final settled = await controller.settleEntry(
      entry: entry,
      transactionWallet: widget.wallet,
    );

    if (!mounted) return;

    final message = settled
        ? (isIncome ? 'Recebimento confirmado.' : 'Pagamento confirmado.')
        : controller.errorMessage ?? 'Não foi possível confirmar.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selectedDay = controller.selectedDay ?? DateTime.now();
        final visibleEntries = controller.visibleEntries;
        final dayNet = visibleEntries.fold<double>(
          0,
          (total, entry) => total + (entry.isIncome ? entry.value : -entry.value),
        );

        return Scaffold(
          backgroundColor: DuoColors.background,
          appBar: AppBar(
            backgroundColor: DuoColors.background,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.menu_rounded),
            ),
            titleSpacing: 4,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calendário',
                  style: TextStyle(
                    color: DuoColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Planeje, acompanhe e organize suas finanças',
                  style: TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Filtros',
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton.filled(
                  tooltip: 'Nova movimentação',
                  onPressed: () {},
                  style: IconButton.styleFrom(
                    backgroundColor: DuoColors.primary.withValues(alpha: .22),
                    foregroundColor: DuoColors.primaryLight,
                  ),
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
            ],
          ),
          body: controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: DuoColors.primary),
                )
              : RefreshIndicator(
                  color: DuoColors.primary,
                  onRefresh: () => controller.load(
                    wallet: widget.wallet,
                    transactions: widget.transactions,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
                    children: [
                      _ProjectionCard(
                        currentBalance: controller.projection.currentBalance,
                        projectedBalance: controller.projection.projectedBalance,
                        income: controller.projection.projectedIncome,
                        expense: controller.projection.projectedExpense,
                        formatMoney: _formatMoney,
                        showValues: _showValues,
                        onToggleValues: () {
                          setState(() => _showValues = !_showValues);
                        },
                      ),
                      const SizedBox(height: 10),
                      _CalendarPanel(
                        monthLabel: _monthLabel(controller.selectedMonth),
                        month: controller.selectedMonth,
                        entries: controller.monthEntries,
                        selectedDay: controller.selectedDay,
                        entryColor: _entryColor,
                        onPrevious: () => controller.previousMonth(
                          wallet: widget.wallet,
                        ),
                        onNext: () => controller.nextMonth(
                          wallet: widget.wallet,
                        ),
                        onDaySelected: controller.selectDay,
                      ),
                      const SizedBox(height: 10),
                      _DayPanel(
                        title: _selectedDayLabel(selectedDay),
                        entries: visibleEntries,
                        dayNet: dayNet,
                        formatMoney: _formatMoney,
                        entryLabel: _entryLabel,
                        entryColor: _entryColor,
                        entryIcon: _entryIcon,
                        isSettling: controller.isSettling,
                        onSettle: _settleEntry,
                        errorMessage: controller.errorMessage,
                        onShowMonth: controller.selectedDay == null
                            ? null
                            : controller.clearDaySelection,
                      ),
                      const SizedBox(height: 10),
                      const _Legend(),
                    ],
                  ),
                ),
          bottomNavigationBar: const _CalendarBottomNav(),
        );
      },
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  final double currentBalance;
  final double projectedBalance;
  final double income;
  final double expense;
  final String Function(double) formatMoney;
  final bool showValues;
  final VoidCallback onToggleValues;

  const _ProjectionCard({
    required this.currentBalance,
    required this.projectedBalance,
    required this.income,
    required this.expense,
    required this.formatMoney,
    required this.showValues,
    required this.onToggleValues,
  });

  @override
  Widget build(BuildContext context) {
    final difference = projectedBalance - currentBalance;
    final positive = difference >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: DuoColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DuoColors.border),
        boxShadow: DuoColors.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Saldo previsto',
                      style: TextStyle(
                        color: DuoColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: onToggleValues,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Icon(
                          showValues
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 13,
                          color: DuoColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  formatMoney(projectedBalance),
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'até o fim do mês',
                  style: const TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (positive ? DuoColors.success : DuoColors.error)
                        .withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${positive ? '↑' : '↓'} ${formatMoney(difference.abs())} desde hoje',
                    style: TextStyle(
                      color: positive ? DuoColors.success : DuoColors.error,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 145,
            height: 82,
            child: CustomPaint(
              painter: _ProjectionTrendPainter(
                positive: positive,
                magnitude: (income + expense).abs(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectionTrendPainter extends CustomPainter {
  final bool positive;
  final double magnitude;

  const _ProjectionTrendPainter({
    required this.positive,
    required this.magnitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = DuoColors.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          DuoColors.primary.withValues(alpha: .2),
          DuoColors.primary.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final mid = size.height * .55;
    final amplitude = magnitude <= 0 ? 6.0 : 14.0;
    final path = Path()..moveTo(0, mid + (positive ? amplitude : -amplitude));
    path.cubicTo(
      size.width * .22,
      mid + 12,
      size.width * .36,
      mid - 2,
      size.width * .50,
      mid + 1,
    );
    path.cubicTo(
      size.width * .66,
      mid + 7,
      size.width * .78,
      mid - 14,
      size.width,
      mid - (positive ? amplitude : -amplitude),
    );
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, fill);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _ProjectionTrendPainter oldDelegate) {
    return oldDelegate.positive != positive || oldDelegate.magnitude != magnitude;
  }
}

class _CalendarPanel extends StatelessWidget {
  final String monthLabel;
  final DateTime month;
  final List<FinancialCalendarEntry> entries;
  final DateTime? selectedDay;
  final Color Function(FinancialCalendarEntry) entryColor;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDaySelected;

  const _CalendarPanel({
    required this.monthLabel,
    required this.month,
    required this.entries,
    required this.selectedDay,
    required this.entryColor,
    required this.onPrevious,
    required this.onNext,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
      decoration: BoxDecoration(
        color: DuoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DuoColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _RoundArrow(icon: Icons.chevron_left_rounded, onTap: onPrevious),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              _RoundArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
            ],
          ),
          const SizedBox(height: 8),
          _CalendarGrid(
            month: month,
            entries: entries,
            selectedDay: selectedDay,
            entryColor: entryColor,
            onDaySelected: onDaySelected,
          ),
        ],
      ),
    );
  }
}

class _RoundArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: DuoColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 18, color: DuoColors.textSecondary),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final List<FinancialCalendarEntry> entries;
  final DateTime? selectedDay;
  final Color Function(FinancialCalendarEntry) entryColor;
  final ValueChanged<DateTime> onDaySelected;

  const _CalendarGrid({
    required this.month,
    required this.entries,
    required this.selectedDay,
    required this.entryColor,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    const weekDays = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = firstDay.weekday - 1;
    final previousMonthDays = DateTime(month.year, month.month, 0).day;
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;

    return Column(
      children: [
        Row(
          children: weekDays
              .map(
                (day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: DuoColors.textHint,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < totalCells ~/ 7; row++)
          Row(
            children: List.generate(7, (column) {
              final index = row * 7 + column;
              final relativeDay = index - leading + 1;
              final isCurrentMonth = relativeDay >= 1 && relativeDay <= daysInMonth;
              final displayDay = relativeDay < 1
                  ? previousMonthDays + relativeDay
                  : relativeDay > daysInMonth
                      ? relativeDay - daysInMonth
                      : relativeDay;
              final date = relativeDay < 1
                  ? DateTime(month.year, month.month - 1, displayDay)
                  : relativeDay > daysInMonth
                      ? DateTime(month.year, month.month + 1, displayDay)
                      : DateTime(month.year, month.month, displayDay);
              final dayEntries = entries.where(
                (entry) =>
                    entry.date.year == date.year &&
                    entry.date.month == date.month &&
                    entry.date.day == date.day,
              );
              final colors = <Color>[];
              for (final entry in dayEntries) {
                final color = entryColor(entry);
                if (!colors.contains(color) && colors.length < 4) colors.add(color);
              }
              final selected = selectedDay?.year == date.year &&
                  selectedDay?.month == date.month &&
                  selectedDay?.day == date.day;

              return Expanded(
                child: InkWell(
                  onTap: isCurrentMonth ? () => onDaySelected(date) : null,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 42,
                    margin: const EdgeInsets.all(.5),
                    decoration: BoxDecoration(
                      color: selected
                          ? DuoColors.primary.withValues(alpha: .55)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$displayDay',
                          style: TextStyle(
                            color: isCurrentMonth
                                ? DuoColors.textPrimary
                                : DuoColors.textHint.withValues(alpha: .45),
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < colors.length; i++) ...[
                              if (i > 0) const SizedBox(width: 2),
                              _CalendarDot(color: colors[i]),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _CalendarDot extends StatelessWidget {
  final Color color;

  const _CalendarDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DayPanel extends StatelessWidget {
  final String title;
  final List<FinancialCalendarEntry> entries;
  final double dayNet;
  final String Function(double) formatMoney;
  final String Function(FinancialCalendarEntry) entryLabel;
  final Color Function(FinancialCalendarEntry) entryColor;
  final IconData Function(FinancialCalendarEntry) entryIcon;
  final bool isSettling;
  final Future<void> Function(FinancialCalendarEntry) onSettle;
  final String? errorMessage;
  final VoidCallback? onShowMonth;

  const _DayPanel({
    required this.title,
    required this.entries,
    required this.dayNet,
    required this.formatMoney,
    required this.entryLabel,
    required this.entryColor,
    required this.entryIcon,
    required this.isSettling,
    required this.onSettle,
    required this.errorMessage,
    required this.onShowMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DuoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DuoColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: DuoColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${entries.length} ${entries.length == 1 ? 'item' : 'itens'} · ${formatMoney(dayNet.abs())} previstos',
                  style: const TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: DuoColors.divider),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: DuoColors.error),
              ),
            )
          else if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Nenhuma movimentação financeira neste dia.',
                style: TextStyle(color: DuoColors.textSecondary, fontSize: 11),
              ),
            )
          else
            for (var i = 0; i < entries.length; i++) ...[
              _EntryRow(
                entry: entries[i],
                label: entryLabel(entries[i]),
                color: entryColor(entries[i]),
                icon: entryIcon(entries[i]),
                formattedValue: formatMoney(entries[i].value),
                isSettling: isSettling,
                onSettle: entries[i].transaction?.isFinanciallyPending == true
                    ? () => onSettle(entries[i])
                    : null,
              ),
              if (i != entries.length - 1)
                const Divider(height: 1, indent: 52, color: DuoColors.divider),
            ],
          if (onShowMonth != null) ...[
            const Divider(height: 1, color: DuoColors.divider),
            TextButton(
              onPressed: onShowMonth,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ver todos os itens do mês'),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final FinancialCalendarEntry entry;
  final String label;
  final Color color;
  final IconData icon;
  final String formattedValue;
  final bool isSettling;
  final VoidCallback? onSettle;

  const _EntryRow({
    required this.entry,
    required this.label,
    required this.color,
    required this.icon,
    required this.formattedValue,
    required this.isSettling,
    required this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSettle == null || isSettling ? null : onSettle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 34,
              child: Text(
                DateFormat('HH:mm').format(entry.date),
                style: const TextStyle(
                  color: DuoColors.textHint,
                  fontSize: 8,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DuoColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.isProjected ? 'Previsto' : 'Movimentação confirmada',
                    style: const TextStyle(
                      color: DuoColors.textSecondary,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.isIncome ? '+' : '-'} $formattedValue',
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              color: DuoColors.textHint,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Receitas', DuoColors.success),
      ('Despesas', DuoColors.error),
      ('Faturas', Color(0xFFFFA726)),
      ('Recorrências', Color(0xFF9B6CFF)),
      ('Compromissos', Color(0xFF4AA3FF)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DuoColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DuoColors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 6,
        spacing: 8,
        children: [
          for (final item in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CalendarDot(color: item.$2),
                const SizedBox(width: 4),
                Text(
                  item.$1,
                  style: const TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CalendarBottomNav extends StatelessWidget {
  const _CalendarBottomNav();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: DuoColors.surface,
          border: Border(top: BorderSide(color: DuoColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const _NavItem(icon: Icons.home_outlined, label: 'Início'),
            const _NavItem(icon: Icons.swap_horiz_rounded, label: 'Transações'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DuoColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: DuoColors.primary.withValues(alpha: .35),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
            ),
            const _NavItem(
              icon: Icons.calendar_month_rounded,
              label: 'Calendário',
              selected: true,
            ),
            const _NavItem(icon: Icons.bar_chart_rounded, label: 'Relatórios'),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? DuoColors.primaryLight : DuoColors.textHint;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
