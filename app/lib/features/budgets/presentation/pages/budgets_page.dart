import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../domain/models/budget.dart';
import '../../domain/models/budget_consumption.dart';
import '../controllers/budgets_controller.dart';

class BudgetsPage extends StatefulWidget {
  final WalletModel wallet;
  final List<TransactionModel> transactions;
  final String currentUserId;

  const BudgetsPage({
    super.key,
    required this.wallet,
    required this.transactions,
    required this.currentUserId,
  });

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  late final BudgetsController controller;
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  final money = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    controller = BudgetsController(
      wallet: widget.wallet,
      currentUserId: widget.currentUserId,
      transactions: widget.transactions,
    )..load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _changeMonth() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Escolha o mês',
    );
    if (chosen != null && mounted) {
      setState(() => selectedMonth = DateTime(chosen.year, chosen.month));
    }
  }

  Future<void> _showEditor([Budget? budget]) async {
    if (!controller.canManage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Somente o proprietário pode alterar orçamentos compartilhados.',
          ),
        ),
      );
      return;
    }

    final category = TextEditingController(text: budget?.category ?? '');
    final limit = TextEditingController(
      text: budget?.limitAmount.toStringAsFixed(2).replaceAll('.', ',') ?? '',
    );
    DateTime month = budget?.month ?? selectedMonth;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: DuoColors.surface,
          title: Text(budget == null ? 'Novo orçamento' : 'Editar orçamento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: category,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    hintText: 'Ex.: Mercado',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Limite mensal',
                    prefixText: 'R\$ ',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mês'),
                  subtitle: Text(
                    DateFormat('MMMM yyyy', 'pt_BR').format(month),
                  ),
                  trailing: const Icon(Icons.calendar_month_rounded),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: month,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (date != null) {
                      setDialogState(
                        () => month = DateTime(date.year, date.month),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      category.dispose();
      limit.dispose();
      return;
    }

    final parsed = double.tryParse(
      limit.text.trim().replaceAll('.', '').replaceAll(',', '.'),
    );

    final result = budget == null
        ? await controller.create(
            category: category.text,
            month: month,
            limitAmount: parsed ?? 0,
          )
        : await controller.update(
            budget,
            category: category.text,
            month: month,
            limitAmount: parsed ?? 0,
          );

    category.dispose();
    limit.dispose();

    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Não foi possível salvar o orçamento.',
          ),
        ),
      );
    }
  }

  Color _color(BudgetHealth health) => switch (health) {
        BudgetHealth.healthy => DuoColors.success,
        BudgetHealth.attention => DuoColors.warning,
        BudgetHealth.exceeded => DuoColors.error,
      };

  String _label(BudgetHealth health) => switch (health) {
        BudgetHealth.healthy => 'Dentro do planejado',
        BudgetHealth.attention => 'Atenção',
        BudgetHealth.exceeded => 'Limite ultrapassado',
      };

  IconData _categoryIcon(String category) {
    final value = category.toLowerCase();
    if (value.contains('mercado') || value.contains('aliment')) {
      return Icons.shopping_cart_outlined;
    }
    if (value.contains('casa') || value.contains('moradia')) {
      return Icons.home_outlined;
    }
    if (value.contains('transporte')) return Icons.directions_car_outlined;
    if (value.contains('lazer')) return Icons.movie_outlined;
    if (value.contains('saúde') || value.contains('saude')) {
      return Icons.favorite_border_rounded;
    }
    if (value.contains('pet')) return Icons.pets_outlined;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final budgets = controller.forMonth(selectedMonth);
          final limit = budgets.fold<double>(
            0,
            (total, item) => total + item.budget.limitAmount,
          );
          final spent = budgets.fold<double>(
            0,
            (total, item) => total + item.spentAmount,
          );
          final remaining = limit - spent;
          final progress = limit == 0
              ? 0.0
              : (spent / limit).clamp(0.0, 1.0).toDouble();
          final monthLabel = DateFormat(
            'MMMM yyyy',
            'pt_BR',
          ).format(selectedMonth);

          return Scaffold(
            backgroundColor: DuoColors.background,
            appBar: AppBar(
              backgroundColor: DuoColors.background,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 4,
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orçamentos',
                    style: TextStyle(
                      color: DuoColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Planeje antes de gastar',
                    style: TextStyle(
                      color: DuoColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: _changeMonth,
                  icon: const Icon(Icons.calendar_month_rounded),
                  color: DuoColors.primaryLight,
                  tooltip: 'Escolher mês',
                ),
              ],
            ),
            body: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: DuoColors.primary,
                    ),
                  )
                : RefreshIndicator(
                    color: DuoColors.primary,
                    backgroundColor: DuoColors.surface,
                    onRefresh: controller.load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                      children: [
                        _MonthSwitcher(
                          label: monthLabel,
                          onTap: _changeMonth,
                        ),
                        const SizedBox(height: 16),
                        _BudgetOverview(
                          limit: limit,
                          spent: spent,
                          remaining: remaining,
                          progress: progress,
                          money: money,
                          budgetCount: budgets.length,
                        ),
                        if (!controller.canManage && widget.wallet.isShared)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'Você pode acompanhar os limites, mas somente o proprietário da carteira pode alterá-los.',
                              style: TextStyle(
                                color: DuoColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Por categoria',
                                style: TextStyle(
                                  color: DuoColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (controller.canManage)
                              TextButton.icon(
                                onPressed: controller.isProcessing
                                    ? null
                                    : () => _showEditor(),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Adicionar'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (budgets.isEmpty)
                          _EmptyBudgetState(
                            canManage: controller.canManage,
                            onCreate: () => _showEditor(),
                          )
                        else
                          for (final item in budgets) ...[
                            _BudgetCard(
                              consumption: item,
                              money: money,
                              color: _color(item.health),
                              label: _label(item.health),
                              icon: _categoryIcon(item.budget.category),
                              canManage: controller.canManage,
                              onEdit: () => _showEditor(item.budget),
                              onPause: () => controller.changeStatus(
                                item.budget,
                                item.budget.isPaused
                                    ? BudgetStatus.active
                                    : BudgetStatus.paused,
                              ),
                              onArchive: () => controller.changeStatus(
                                item.budget,
                                BudgetStatus.archived,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        if (controller.budgets
                            .where((item) => item.isArchived)
                            .isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Arquivados',
                            style: TextStyle(
                              color: DuoColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final item in controller.budgets
                              .where((item) => item.isArchived))
                            _ArchivedBudgetTile(
                              budget: item,
                              canManage: controller.canManage,
                              onRestore: () => controller.changeStatus(
                                item,
                                BudgetStatus.active,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
          );
        },
      );
}

class _MonthSwitcher extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MonthSwitcher({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: DuoColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DuoColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: DuoColors.primaryLight,
              size: 17,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label[0].toUpperCase() + label.substring(1),
                style: const TextStyle(
                  color: DuoColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: DuoColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetOverview extends StatelessWidget {
  final double limit;
  final double spent;
  final double remaining;
  final double progress;
  final NumberFormat money;
  final int budgetCount;

  const _BudgetOverview({
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.progress,
    required this.money,
    required this.budgetCount,
  });

  @override
  Widget build(BuildContext context) {
    final isExceeded = remaining < 0;
    final accent = isExceeded ? DuoColors.error : DuoColors.primaryLight;

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
          const Row(
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                color: DuoColors.primaryLight,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Visão do mês',
                style: TextStyle(
                  color: DuoColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gasto até agora',
                      style: TextStyle(
                        color: DuoColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      money.format(spent),
                      style: const TextStyle(
                        color: DuoColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'de ${money.format(limit)}',
                style: const TextStyle(
                  color: DuoColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: DuoColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${(progress * 100).round()}% utilizado',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                isExceeded
                    ? '${money.format(-remaining)} acima do limite'
                    : '${money.format(remaining)} disponíveis',
                style: TextStyle(
                  color: isExceeded ? DuoColors.error : DuoColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: DuoColors.divider),
          const SizedBox(height: 12),
          Text(
            budgetCount == 1
                ? '1 categoria planejada'
                : '$budgetCount categorias planejadas',
            style: const TextStyle(
              color: DuoColors.textHint,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetConsumption consumption;
  final NumberFormat money;
  final Color color;
  final String label;
  final IconData icon;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onPause;
  final VoidCallback onArchive;

  const _BudgetCard({
    required this.consumption,
    required this.money,
    required this.color,
    required this.label,
    required this.icon,
    required this.canManage,
    required this.onEdit,
    required this.onPause,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final budget = consumption.budget;
    final progress = consumption.percentage.clamp(0.0, 1.0).toDouble();
    final remaining = consumption.remainingAmount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DuoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DuoColors.border),
        boxShadow: DuoColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.category,
                      style: const TextStyle(
                        color: DuoColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      budget.isPaused ? 'Pausado' : label,
                      style: TextStyle(
                        color: budget.isPaused ? DuoColors.textHint : color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${consumption.percentage.round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  color: DuoColors.surface,
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: DuoColors.textHint,
                  ),
                  onSelected: (action) {
                    if (action == 'edit') onEdit();
                    if (action == 'pause') onPause();
                    if (action == 'archive') onArchive();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(
                      value: 'pause',
                      child: Text(budget.isPaused ? 'Retomar' : 'Pausar'),
                    ),
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Arquivar'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: DuoColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  money.format(consumption.spentAmount),
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Limite ${money.format(budget.limitAmount)}',
                style: const TextStyle(
                  color: DuoColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            remaining >= 0
                ? '${money.format(remaining)} restantes'
                : '${money.format(-remaining)} acima do limite',
            style: TextStyle(
              color: remaining >= 0 ? DuoColors.textSecondary : DuoColors.error,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBudgetState extends StatelessWidget {
  final bool canManage;
  final VoidCallback onCreate;

  const _EmptyBudgetState({required this.canManage, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: DuoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DuoColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.pie_chart_outline_rounded,
            color: DuoColors.textHint,
            size: 38,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum orçamento neste mês',
            style: TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Defina limites por categoria para acompanhar seus gastos com mais clareza.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          if (canManage) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar orçamento'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArchivedBudgetTile extends StatelessWidget {
  final Budget budget;
  final bool canManage;
  final VoidCallback onRestore;

  const _ArchivedBudgetTile({
    required this.budget,
    required this.canManage,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: DuoColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DuoColors.border),
      ),
      child: ListTile(
        title: Text(
          budget.category,
          style: const TextStyle(
            color: DuoColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${DateFormat('MM/yyyy').format(budget.month)} · Arquivado',
          style: const TextStyle(color: DuoColors.textSecondary),
        ),
        trailing: canManage
            ? IconButton(
                icon: const Icon(
                  Icons.unarchive_rounded,
                  color: DuoColors.primaryLight,
                ),
                onPressed: onRestore,
              )
            : null,
      ),
    );
  }
}
