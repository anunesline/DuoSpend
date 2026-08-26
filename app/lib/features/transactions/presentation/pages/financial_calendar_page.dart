import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../../../core/design_system/duo_page_scaffold.dart';
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
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(value);
  }

  String _monthLabel(DateTime month) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return '${months[month.month - 1]} ${month.year}';
  }

  Future<void> _settleEntry(FinancialCalendarEntry entry) async {
    final isIncome = entry.isIncome;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final settled = await controller.settleEntry(
      entry: entry,
      transactionWallet: widget.wallet,
    );

    if (!mounted) {
      return;
    }

    final message = settled
        ? (isIncome ? 'Recebimento confirmado.' : 'Pagamento confirmado.')
        : controller.errorMessage ?? 'Não foi possível confirmar.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        return 'Parcela';
      case FinancialCalendarEntryKind.recurring:
        return 'Recorrente';
      case FinancialCalendarEntryKind.creditCardInvoice:
        return 'Fatura';
      case FinancialCalendarEntryKind.transaction:
        return entry.isProjected ? 'Agendada' : 'Realizada';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return DuoPageScaffold(
          title: 'Calendário',
          eyebrow: 'Planejamento financeiro',
          scrollable: false,
          padding: EdgeInsets.zero,
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => controller.load(
                    wallet: widget.wallet,
                    transactions: widget.transactions,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _ProjectionCard(
                        currentBalance: _formatMoney(
                          controller.projection.currentBalance,
                        ),
                        projectedBalance: _formatMoney(
                          controller.projection.projectedBalance,
                        ),
                        income: _formatMoney(
                          controller.projection.projectedIncome,
                        ),
                        expense: _formatMoney(
                          controller.projection.projectedExpense,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _MonthHeader(
                        label: _monthLabel(controller.selectedMonth),
                        onPrevious: () => controller.previousMonth(
                          wallet: widget.wallet,
                        ),
                        onNext: () => controller.nextMonth(
                          wallet: widget.wallet,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CalendarGrid(
                        month: controller.selectedMonth,
                        entries: controller.monthEntries,
                        selectedDay: controller.selectedDay,
                        onDaySelected: controller.selectDay,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Movimentações',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: DuoColors.textPrimary,
                              ),
                            ),
                          ),
                          if (controller.selectedDay != null)
                            TextButton(
                              onPressed:
                                  controller.clearDaySelection,
                              child: const Text('Ver mês'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (controller.errorMessage != null)
                        _MessageCard(message: controller.errorMessage!)
                      else if (controller.visibleEntries.isEmpty)
                        const _MessageCard(
                          message:
                              'Nenhuma movimentação financeira neste período.',
                        )
                      else
                        ...controller.visibleEntries.map(
                          (entry) => _EntryTile(
                            entry: entry,
                            label: _entryLabel(entry),
                            formattedValue: _formatMoney(entry.value),
                            isSettling: controller.isSettling,
                            onSettle: entry.transaction
                                        ?.isFinanciallyPending ==
                                    true
                                ? () => _settleEntry(entry)
                                : null,
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

class _ProjectionCard extends StatelessWidget {
  final String currentBalance;
  final String projectedBalance;
  final String income;
  final String expense;

  const _ProjectionCard({
    required this.currentBalance,
    required this.projectedBalance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DuoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DuoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo previsto',
            style: TextStyle(
              color: DuoColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            projectedBalance,
            style: const TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Saldo atual: $currentBalance',
            style: const TextStyle(color: DuoColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ProjectionValue(
                  label: 'A receber',
                  value: income,
                  color: DuoColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProjectionValue(
                  label: 'A pagar',
                  value: expense,
                  color: DuoColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectionValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProjectionValue({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: DuoColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DuoColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final List<FinancialCalendarEntry> entries;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const _CalendarGrid({
    required this.month,
    required this.entries,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    const weekDays = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmptyDays = firstDay.weekday - 1;
    final totalCells = leadingEmptyDays + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DuoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DuoColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: weekDays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: DuoColors.textHint,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 8),
          for (var row = 0; row < rowCount; row++)
            Row(
              children: List.generate(7, (column) {
                final cellIndex = row * 7 + column;
                final dayNumber = cellIndex - leadingEmptyDays + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 46));
                }

                final day = DateTime(month.year, month.month, dayNumber);
                final dayEntries = entries.where(
                  (entry) =>
                      entry.date.year == day.year &&
                      entry.date.month == day.month &&
                      entry.date.day == day.day,
                );
                final hasIncome =
                    dayEntries.any((entry) => entry.isIncome);
                final hasExpense =
                    dayEntries.any((entry) => entry.isExpense);
                final isSelected = selectedDay?.year == day.year &&
                    selectedDay?.month == day.month &&
                    selectedDay?.day == day.day;
                final now = DateTime.now();
                final isToday = now.year == day.year &&
                    now.month == day.month &&
                    now.day == day.day;

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onDaySelected(day),
                    child: Container(
                      height: 46,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DuoColors.primary.withValues(alpha: .22)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isToday
                            ? Border.all(color: DuoColors.primaryLight)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNumber',
                            style: const TextStyle(
                              color: DuoColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (hasIncome)
                                const _CalendarDot(color: DuoColors.success),
                              if (hasIncome && hasExpense)
                                const SizedBox(width: 3),
                              if (hasExpense)
                                const _CalendarDot(color: DuoColors.error),
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
      ),
    );
  }
}

class _CalendarDot extends StatelessWidget {
  final Color color;

  const _CalendarDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final FinancialCalendarEntry entry;
  final String label;
  final String formattedValue;
  final bool isSettling;
  final VoidCallback? onSettle;

  const _EntryTile({
    required this.entry,
    required this.label,
    required this.formattedValue,
    required this.isSettling,
    this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final color = entry.isIncome ? DuoColors.success : DuoColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DuoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DuoColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              entry.isIncome
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateFormat('dd/MM').format(entry.date)} • $label',
                  style: const TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (onSettle != null) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: isSettling ? null : onSettle,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      entry.isIncome
                          ? Icons.check_circle_outline_rounded
                          : Icons.payments_outlined,
                      size: 17,
                    ),
                    label: Text(
                      entry.isIncome
                          ? 'Marcar como recebido'
                          : 'Marcar como pago',
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${entry.isIncome ? '+' : '-'} $formattedValue',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DuoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DuoColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: DuoColors.textSecondary),
      ),
    );
  }
}
