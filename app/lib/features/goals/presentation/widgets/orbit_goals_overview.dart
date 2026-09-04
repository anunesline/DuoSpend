import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../domain/models/savings_goal.dart';
import '../../domain/models/savings_goal_movement.dart';
import 'goal_category_visuals.dart';

class OrbitGoalHeroCard extends StatelessWidget {
  final SavingsGoal goal;
  final String Function(double) formatMoney;
  final String Function(DateTime) formatDate;
  final List<SavingsGoalMovement>? movements;

  const OrbitGoalHeroCard({
    super.key,
    required this.goal,
    required this.formatMoney,
    required this.formatDate,
    required this.movements,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _goalAccent(goal);
    final deadline = goal.deadline;
    final days = deadline == null ? null : _daysUntil(deadline);
    return _OrbitSurface(
      borderColor: DuoColors.primary.withValues(alpha: .5),
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GoalIcon(goal: goal, accent: accent),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DuoColors.textPrimary,
                              fontSize: 18,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(goal: goal, accent: accent),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      goal.category.label,
                      style: const TextStyle(
                        color: DuoColors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (context, constraints) {
              final ring = _ProgressRing(goal: goal, accent: accent);
              final values = _GoalValues(
                goal: goal,
                days: days,
                formatMoney: formatMoney,
                formatDate: formatDate,
              );
              if (constraints.maxWidth < 285) {
                return Column(
                  children: [ring, const SizedBox(height: 14), values],
                );
              }
              return Row(
                children: [
                  ring,
                  const SizedBox(width: 18),
                  Expanded(child: values),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          OrbitGoalInsightCard(
            goal: goal,
            movements: movements,
            formatMoney: formatMoney,
            formatDate: formatDate,
          ),
        ],
      ),
    );
  }
}

class OrbitGoalInsightCard extends StatelessWidget {
  final SavingsGoal goal;
  final List<SavingsGoalMovement>? movements;
  final String Function(double) formatMoney;
  final String Function(DateTime) formatDate;

  const OrbitGoalInsightCard({
    super.key,
    required this.goal,
    required this.movements,
    required this.formatMoney,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final insight = _goalInsight(
      goal,
      movements: movements,
      formatMoney: formatMoney,
      formatDate: formatDate,
    );
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 21,
            color: DuoColors.primaryLight,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.title,
                style: const TextStyle(
                  color: DuoColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                insight.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DuoColors.textSecondary,
                  fontSize: 10.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Transform.rotate(
          angle: -.45,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  DuoColors.primaryLight.withValues(alpha: .24),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: DuoColors.primaryLight,
              size: 29,
            ),
          ),
        ),
      ],
    );
    return _OrbitSurface(
      radius: 14,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF171326), Color(0xFF10141C)],
      ),
      child: content,
    );
  }
}

class OrbitGoalMetrics extends StatelessWidget {
  final SavingsGoal goal;
  final List<SavingsGoalMovement>? movements;
  final String Function(double) formatMoney;

  const OrbitGoalMetrics({
    super.key,
    required this.goal,
    required this.movements,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    final contributions =
        movements?.where((item) => item.isContribution).length ?? 0;
    final withdrawals =
        movements?.where((item) => item.isWithdrawal).length ?? 0;
    final metrics = [
      (
        'Falta para a meta',
        formatMoney(goal.remainingAmount),
        DuoColors.primaryLight,
      ),
      (
        'Progresso real',
        '${goal.progressPercentage.toStringAsFixed(0)}%',
        DuoColors.success,
      ),
      (
        'Aportes registrados',
        movements == null ? '—' : '$contributions',
        DuoColors.success,
      ),
      (
        'Retiradas registradas',
        movements == null ? '—' : '$withdrawals',
        DuoColors.warning,
      ),
    ];
    return _OrbitSurface(
      radius: 14,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < metrics.length; index++) ...[
              Expanded(
                child: _MetricCell(
                  label: metrics[index].$1,
                  value: metrics[index].$2,
                  accent: metrics[index].$3,
                ),
              ),
              if (index != metrics.length - 1)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: DuoColors.divider,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class OrbitGoalProgressSection extends StatelessWidget {
  final SavingsGoal goal;
  final List<SavingsGoalMovement>? movements;
  final bool isLoading;
  final String Function(double) formatMoney;

  const OrbitGoalProgressSection({
    super.key,
    required this.goal,
    required this.movements,
    required this.isLoading,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Evolução da meta'),
        const SizedBox(height: 8),
        _OrbitSurface(
          radius: 14,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: SizedBox(
            height: (movements?.isEmpty ?? false) ? 108 : 158,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: DuoColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : _GoalChart(
                    goal: goal,
                    movements: movements ?? const [],
                    formatMoney: formatMoney,
                  ),
          ),
        ),
      ],
    );
  }
}

class OrbitGoalMovementsSection extends StatelessWidget {
  final List<SavingsGoalMovement>? movements;
  final bool isLoading;
  final String Function(double) formatMoney;
  final String Function(DateTime) formatDate;
  final VoidCallback onSeeAll;

  const OrbitGoalMovementsSection({
    super.key,
    required this.movements,
    required this.isLoading,
    required this.formatMoney,
    required this.formatDate,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final items = (movements ?? const <SavingsGoalMovement>[]).take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle(title: 'Últimos movimentos')),
            if (!isLoading && (movements?.isNotEmpty ?? false))
              TextButton(onPressed: onSeeAll, child: const Text('Ver todos')),
          ],
        ),
        const SizedBox(height: 5),
        _OrbitSurface(
          radius: 14,
          padding: EdgeInsets.zero,
          child: isLoading
              ? const SizedBox(
                  height: 72,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: DuoColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : items.isEmpty
              ? const _NeutralBlock(
                  icon: Icons.history_rounded,
                  title: 'Nenhuma movimentação ainda',
                  message: 'Seus aportes e retiradas aparecerão aqui.',
                )
              : Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _MovementTile(
                        movement: items[index],
                        formatMoney: formatMoney,
                        formatDate: formatDate,
                      ),
                      if (index != items.length - 1)
                        const Divider(
                          height: 1,
                          indent: 58,
                          color: DuoColors.divider,
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class OrbitGoalGuidanceSection extends StatelessWidget {
  final SavingsGoal goal;
  final List<SavingsGoalMovement>? movements;

  const OrbitGoalGuidanceSection({
    super.key,
    required this.goal,
    required this.movements,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_GuidanceItem>[
      if (goal.deadline == null)
        const _GuidanceItem(
          icon: Icons.calendar_month_rounded,
          title: 'Prazo opcional',
          message: 'Adicione uma data se quiser acompanhar os dias restantes.',
          accent: DuoColors.primaryLight,
        )
      else
        _GuidanceItem(
          icon: Icons.event_available_rounded,
          title: 'Prazo registrado',
          message: _deadlineGuidance(goal.deadline!),
          accent: DuoColors.primaryLight,
        ),
      if (movements == null || movements!.isEmpty)
        const _GuidanceItem(
          icon: Icons.add_rounded,
          title: 'Comece no seu ritmo',
          message:
              'Ao registrar aportes, o Orbit mostrará a evolução desta meta.',
          accent: DuoColors.success,
        )
      else
        const _GuidanceItem(
          icon: Icons.timeline_rounded,
          title: 'Histórico atualizado',
          message: 'A evolução acima considera somente aportes e retiradas registrados.',
          accent: DuoColors.success,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Dicas para alcançar mais rápido'),
        const SizedBox(height: 8),
        _OrbitSurface(
          radius: 14,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 290) {
                return Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _GuidanceTile(item: items[index]),
                      ),
                      if (index != items.length - 1)
                        const Divider(height: 18, color: DuoColors.divider),
                    ],
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _GuidanceTile(item: items[index]),
                        ),
                      ),
                      if (index != items.length - 1)
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: DuoColors.divider,
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class OrbitGoalActions extends StatelessWidget {
  final bool processing;
  final VoidCallback onHistory;
  final VoidCallback? onEdit;
  final VoidCallback? onWithdraw;
  final VoidCallback? onArchive;

  const OrbitGoalActions({
    super.key,
    required this.processing,
    required this.onHistory,
    this.onEdit,
    this.onWithdraw,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Ações da meta'),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            if (onWithdraw != null)
              _SmallAction(
                icon: Icons.remove_circle_outline_rounded,
                label: 'Retirar',
                onTap: processing ? null : onWithdraw,
              ),
            _SmallAction(
              icon: Icons.history_rounded,
              label: 'Histórico',
              onTap: processing ? null : onHistory,
            ),
            if (onEdit != null)
              _SmallAction(
                icon: Icons.edit_outlined,
                label: 'Editar',
                onTap: processing ? null : onEdit,
              ),
            if (onArchive != null)
              _SmallAction(
                icon: Icons.archive_outlined,
                label: 'Arquivar',
                onTap: processing ? null : onArchive,
              ),
          ],
        ),
      ],
    );
  }
}

class OrbitGoalsPortfolioOverview extends StatelessWidget {
  final List<SavingsGoal> goals;
  final String selectedGoalId;
  final String Function(double) formatMoney;
  final ValueChanged<String> onGoalSelected;
  final VoidCallback onSeeAll;

  const OrbitGoalsPortfolioOverview({
    super.key,
    required this.goals,
    required this.selectedGoalId,
    required this.formatMoney,
    required this.onGoalSelected,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final included = goals.where((goal) => !goal.isArchived).toList();
    final totalSaved = included.fold<double>(
      0,
      (total, goal) => total + goal.savedAmount,
    );
    final categoryTotals = <SavingsGoalCategory, double>{};
    for (final goal in included) {
      categoryTotals.update(
        goal.category,
        (value) => value + goal.savedAmount,
        ifAbsent: () => goal.savedAmount,
      );
    }
    final distribution =
        categoryTotals.entries.where((entry) => entry.value > 0).toList()
          ..sort((first, second) => second.value.compareTo(first.value));
    final activeGoals = included.where((goal) => goal.isActive).toList();
    final nearest = activeGoals.isEmpty
        ? null
        : ([...activeGoals]..sort(
                (first, second) => second.progress.compareTo(first.progress),
              ))
              .first;
    final averageProgress = included.isEmpty
        ? 0.0
        : included.fold<double>(0, (total, goal) => total + goal.progress) /
              included.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PortfolioGoalsList(
          goals: included,
          selectedGoalId: selectedGoalId,
          formatMoney: formatMoney,
          onGoalSelected: onGoalSelected,
          onSeeAll: onSeeAll,
        ),
        const SizedBox(height: 18),
        _CategoryDistribution(
          entries: distribution,
          totalSaved: totalSaved,
          formatMoney: formatMoney,
        ),
        const SizedBox(height: 18),
        _GoalsSummary(
          totalSaved: totalSaved,
          goalCount: included.length,
          nearestGoal: nearest,
          averageProgress: averageProgress,
          formatMoney: formatMoney,
        ),
      ],
    );
  }
}

class _PortfolioGoalsList extends StatelessWidget {
  final List<SavingsGoal> goals;
  final String selectedGoalId;
  final String Function(double) formatMoney;
  final ValueChanged<String> onGoalSelected;
  final VoidCallback onSeeAll;

  const _PortfolioGoalsList({
    required this.goals,
    required this.selectedGoalId,
    required this.formatMoney,
    required this.onGoalSelected,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return _OrbitSurface(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: DuoColors.primary.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: DuoColors.primaryLight,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Todas as suas metas',
                      style: TextStyle(
                        color: DuoColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Acompanhe cada sonho em um só lugar.',
                      style: TextStyle(
                        color: DuoColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (goals.isEmpty)
            const _NeutralBlock(
              icon: Icons.flag_outlined,
              title: 'Nenhuma meta para resumir',
              message: 'Crie uma meta para acompanhar seu progresso.',
            )
          else
            for (final goal in goals.take(5))
              _PortfolioGoalTile(
                goal: goal,
                selected: goal.id == selectedGoalId,
                formatMoney: formatMoney,
                onTap: () => onGoalSelected(goal.id),
              ),
          if (goals.isNotEmpty)
            TextButton.icon(
              onPressed: onSeeAll,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 15),
              label: const Text(
                'Ver todas as metas',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}

class _PortfolioGoalTile extends StatelessWidget {
  final SavingsGoal goal;
  final bool selected;
  final String Function(double) formatMoney;
  final VoidCallback onTap;

  const _PortfolioGoalTile({
    required this.goal,
    required this.selected,
    required this.formatMoney,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _goalAccent(goal);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? accent.withValues(alpha: .07)
            : DuoColors.surfaceLight.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: .45)
                    : DuoColors.divider,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(goal.category.icon, color: accent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: DuoColors.textPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${goal.progressPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${formatMoney(goal.savedAmount)} de ${formatMoney(goal.targetAmount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DuoColors.textSecondary,
                          fontSize: 9.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: goal.progress,
                          minHeight: 4,
                          backgroundColor: DuoColors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
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
    );
  }
}

class _CategoryDistribution extends StatelessWidget {
  final List<MapEntry<SavingsGoalCategory, double>> entries;
  final double totalSaved;
  final String Function(double) formatMoney;

  const _CategoryDistribution({
    required this.entries,
    required this.totalSaved,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    return _OrbitSurface(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Distribuição por categoria'),
          const SizedBox(height: 12),
          if (totalSaved <= 0 || entries.isEmpty)
            const _NeutralBlock(
              icon: Icons.donut_large_rounded,
              title: 'Distribuição ainda indisponível',
              message: 'Os valores aparecerão após o primeiro aporte.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final chart = SizedBox(
                  width: 116,
                  height: 116,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _CategoryDonutPainter(
                          entries: entries,
                          total: totalSaved,
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatMoney(totalSaved),
                                style: const TextStyle(
                                  color: DuoColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const Text(
                              'guardado',
                              style: TextStyle(
                                color: DuoColors.textSecondary,
                                fontSize: 8.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
                final legend = Column(
                  children: [
                    for (final entry in entries)
                      _CategoryLegendRow(
                        entry: entry,
                        total: totalSaved,
                        formatMoney: formatMoney,
                      ),
                  ],
                );
                if (constraints.maxWidth < 305) {
                  return Column(
                    children: [chart, const SizedBox(height: 12), legend],
                  );
                }
                return Row(
                  children: [
                    chart,
                    const SizedBox(width: 16),
                    Expanded(child: legend),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CategoryLegendRow extends StatelessWidget {
  final MapEntry<SavingsGoalCategory, double> entry;
  final double total;
  final String Function(double) formatMoney;

  const _CategoryLegendRow({
    required this.entry,
    required this.total,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total <= 0 ? 0 : entry.value / total * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: entry.key.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key.label,
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  formatMoney(entry.value),
                  style: const TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: entry.key.accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalsSummary extends StatelessWidget {
  final double totalSaved;
  final int goalCount;
  final SavingsGoal? nearestGoal;
  final double averageProgress;
  final String Function(double) formatMoney;

  const _GoalsSummary({
    required this.totalSaved,
    required this.goalCount,
    required this.nearestGoal,
    required this.averageProgress,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    return _OrbitSurface(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Resumo geral'),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Total guardado', value: formatMoney(totalSaved)),
          _SummaryRow(label: 'Total de metas', value: '$goalCount'),
          if (nearestGoal != null)
            _SummaryRow(label: 'Meta mais próxima', value: nearestGoal!.name),
          _SummaryRow(
            label: 'Conclusão média',
            value: '${(averageProgress * 100).toStringAsFixed(0)}%',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: DuoColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: DuoColors.textSecondary,
                fontSize: 10.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: DuoColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrbitGoalListCard extends StatelessWidget {
  final SavingsGoal goal;
  final String Function(double) formatMoney;
  final VoidCallback onTap;

  const OrbitGoalListCard({
    super.key,
    required this.goal,
    required this.formatMoney,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _goalAccent(goal);
    return _OrbitSurface(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    goal.isCompleted
                        ? Icons.emoji_events_rounded
                        : goal.category.icon,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: DuoColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${goal.progressPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${formatMoney(goal.savedAmount)} de ${formatMoney(goal.targetAmount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DuoColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: goal.progress,
                          minHeight: 5,
                          backgroundColor: DuoColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DuoColors.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OrbitGoalSelector extends StatelessWidget {
  final List<SavingsGoal> goals;
  final String selectedGoalId;
  final ValueChanged<String> onSelected;

  const OrbitGoalSelector({
    super.key,
    required this.goals,
    required this.selectedGoalId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: goals.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final goal = goals[index];
          final selected = goal.id == selectedGoalId;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => onSelected(goal.id),
            avatar: Icon(
              goal.isCompleted
                  ? Icons.emoji_events_rounded
                  : goal.category.icon,
              size: 15,
              color: selected ? DuoColors.textPrimary : DuoColors.textSecondary,
            ),
            label: Text(goal.name),
            selectedColor: DuoColors.primary.withValues(alpha: .35),
            backgroundColor: DuoColors.surface,
            side: BorderSide(
              color: selected
                  ? DuoColors.primaryLight.withValues(alpha: .5)
                  : DuoColors.border,
            ),
            labelStyle: TextStyle(
              color: selected ? DuoColors.textPrimary : DuoColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final SavingsGoal goal;
  final Color accent;
  const _ProgressRing({required this.goal, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: goal.progress,
            strokeWidth: 12,
            strokeCap: StrokeCap.round,
            backgroundColor: DuoColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${goal.progressPercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const Text(
                  'concluído',
                  style: TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 10,
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

class _GoalValues extends StatelessWidget {
  final SavingsGoal goal;
  final int? days;
  final String Function(double) formatMoney;
  final String Function(DateTime) formatDate;

  const _GoalValues({
    required this.goal,
    required this.days,
    required this.formatMoney,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final deadline = goal.deadline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatMoney(goal.savedAmount),
          style: const TextStyle(
            color: DuoColors.textPrimary,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'de ${formatMoney(goal.targetAmount)}',
          style: const TextStyle(color: DuoColors.textSecondary, fontSize: 12),
        ),
        if (deadline != null) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 15,
                  color: DuoColors.textHint,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prazo: ${formatDate(deadline)}',
                      style: const TextStyle(
                        color: DuoColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      days! >= 0
                          ? '$days ${days == 1 ? 'dia restante' : 'dias restantes'}'
                          : 'Prazo cadastrado encerrado',
                      style: TextStyle(
                        color: days! >= 0
                            ? DuoColors.primaryLight
                            : DuoColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _GoalChart extends StatelessWidget {
  final SavingsGoal goal;
  final List<SavingsGoalMovement> movements;
  final String Function(double) formatMoney;
  const _GoalChart({
    required this.goal,
    required this.movements,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return const _NeutralBlock(
        icon: Icons.show_chart_rounded,
        title: 'Evolução ainda não disponível',
        message: 'O gráfico será formado a partir dos movimentos registrados.',
      );
    }
    final points = _movementPoints(goal, movements);
    final maxValue = math.max(
      goal.targetAmount,
      points.fold<double>(0, (value, point) => math.max(value, point.balance)),
    );
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 2,
              decoration: BoxDecoration(
                color: DuoColors.primaryLight,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              'Saldo reconstruído',
              style: TextStyle(color: DuoColors.textSecondary, fontSize: 10),
            ),
            const Spacer(),
            Text(
              formatMoney(goal.savedAmount),
              style: const TextStyle(
                color: DuoColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Expanded(
          child: CustomPaint(
            painter: _GoalChartPainter(points: points, maxValue: maxValue),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd/MM').format(points.first.date),
              style: const TextStyle(color: DuoColors.textHint, fontSize: 9),
            ),
            Text(
              DateFormat('dd/MM').format(points.last.date),
              style: const TextStyle(color: DuoColors.textHint, fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }
}

class _GoalChartPainter extends CustomPainter {
  final List<_MovementPoint> points;
  final double maxValue;
  const _GoalChartPainter({required this.points, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = DuoColors.divider
      ..strokeWidth = 1;
    for (var index = 0; index <= 3; index++) {
      final y = size.height * index / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final denominator = maxValue <= 0 ? 1.0 : maxValue;
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? size.width
          : size.width * index / (points.length - 1);
      final y =
          size.height -
          size.height * (points[index].balance / denominator).clamp(0.0, 1.0);
      index == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = DuoColors.primaryLight
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    final lastY =
        size.height -
        size.height * (points.last.balance / denominator).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(size.width, lastY),
      4.5,
      Paint()..color = DuoColors.primaryLight,
    );
  }

  @override
  bool shouldRepaint(covariant _GoalChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.maxValue != maxValue;
}

class _CategoryDonutPainter extends CustomPainter {
  final List<MapEntry<SavingsGoalCategory, double>> entries;
  final double total;

  const _CategoryDonutPainter({required this.entries, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const gap = .025;
    var start = -math.pi / 2;
    final strokeWidth = size.shortestSide * .16;
    for (final entry in entries) {
      final sweep = total <= 0 ? 0.0 : entry.value / total * math.pi * 2;
      final visibleSweep = math.max(0, sweep - gap).toDouble();
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        start,
        visibleSweep,
        false,
        Paint()
          ..color = entry.key.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryDonutPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.total != total;
}

class _MovementTile extends StatelessWidget {
  final SavingsGoalMovement movement;
  final String Function(double) formatMoney;
  final String Function(DateTime) formatDate;
  const _MovementTile({
    required this.movement,
    required this.formatMoney,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final contribution = movement.isContribution;
    final color = contribution ? DuoColors.success : DuoColors.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              contribution ? Icons.add_rounded : Icons.remove_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contribution ? 'Aporte' : 'Retirada',
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDate(movement.occurredAt),
                  style: const TextStyle(
                    color: DuoColors.textHint,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Text(
              '${contribution ? '+' : '-'} ${formatMoney(movement.amount)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _MetricCell({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 11, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 8.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: accent,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceTile extends StatelessWidget {
  final _GuidanceItem item;
  const _GuidanceTile({required this.item});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: item.accent.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: item.accent, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: DuoColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.message,
                style: const TextStyle(
                  color: DuoColors.textSecondary,
                  fontSize: 9.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SmallAction({required this.icon, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 16),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: DuoColors.textSecondary,
      side: const BorderSide(color: DuoColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final SavingsGoal goal;
  final Color accent;
  const _StatusPill({required this.goal, required this.accent});
  @override
  Widget build(BuildContext context) {
    final label = goal.isArchived
        ? 'Arquivada'
        : goal.isCompleted
        ? 'Realizada'
        : 'Em andamento';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _GoalIcon extends StatelessWidget {
  final SavingsGoal goal;
  final Color accent;
  const _GoalIcon({required this.goal, required this.accent});
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent.withValues(alpha: .42), accent.withValues(alpha: .12)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: accent.withValues(alpha: .55)),
    ),
    child: Icon(
      goal.isCompleted ? Icons.emoji_events_rounded : goal.category.icon,
      color: accent,
      size: 23,
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle({required this.title, this.subtitle});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: DuoColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: -.25,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 3),
        Text(
          subtitle!,
          style: const TextStyle(color: DuoColors.textHint, fontSize: 10),
        ),
      ],
    ],
  );
}

class _NeutralBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _NeutralBlock({
    required this.icon,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: DuoColors.primaryLight, size: 21),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    ),
  );
}

class _OrbitSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Gradient? gradient;
  final double radius;
  const _OrbitSurface({
    required this.child,
    required this.padding,
    this.borderColor,
    this.gradient,
    this.radius = 20,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: gradient == null ? DuoColors.surface : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? DuoColors.border),
      boxShadow: DuoColors.softShadow,
    ),
    child: child,
  );
}

class _GoalInsightCopy {
  final String title;
  final String message;
  const _GoalInsightCopy(this.title, this.message);
}

class _GuidanceItem {
  final IconData icon;
  final String title;
  final String message;
  final Color accent;
  const _GuidanceItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.accent,
  });
}

class _MovementPoint {
  final DateTime date;
  final double balance;
  const _MovementPoint(this.date, this.balance);
}

Color _goalAccent(SavingsGoal goal) => goal.isArchived
    ? DuoColors.textHint
    : goal.isCompleted
    ? DuoColors.success
    : goal.category.accent;

int _daysUntil(DateTime deadline) {
  final now = DateTime.now();
  return DateTime(
    deadline.year,
    deadline.month,
    deadline.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
}

String _deadlineGuidance(DateTime deadline) {
  final days = _daysUntil(deadline);
  if (days < 0) return 'O prazo cadastrado já foi encerrado.';
  if (days == 0) return 'O prazo cadastrado termina hoje.';
  if (days == 1) return 'Resta 1 dia até o prazo cadastrado.';
  return 'Restam $days dias até o prazo cadastrado.';
}

_GoalInsightCopy _goalInsight(
  SavingsGoal goal, {
  required List<SavingsGoalMovement>? movements,
  required String Function(double) formatMoney,
  required String Function(DateTime) formatDate,
}) {
  if (goal.isCompleted)
    return const _GoalInsightCopy(
      'Meta alcançada',
      'O valor guardado atingiu o objetivo cadastrado para este sonho.',
    );
  if (goal.isArchived)
    return const _GoalInsightCopy(
      'Meta arquivada',
      'O histórico permanece disponível para acompanhar os movimentos registrados.',
    );
  if (goal.savedAmount <= 0 && (movements == null || movements.isEmpty))
    return const _GoalInsightCopy(
      'Seu acompanhamento começa aqui',
      'Quando você registrar aportes, o Orbit usará o histórico desta meta para oferecer informações mais personalizadas.',
    );
  final deadline = goal.deadline;
  if (deadline == null)
    return _GoalInsightCopy(
      'Próximo passo registrado',
      'Faltam ${formatMoney(goal.remainingAmount)} para atingir a meta. Adicione um prazo se quiser acompanhar os dias restantes.',
    );
  final days = _daysUntil(deadline);
  if (days < 0)
    return _GoalInsightCopy(
      'Prazo cadastrado encerrado',
      'O prazo foi ${formatDate(deadline)} e ainda faltam ${formatMoney(goal.remainingAmount)} para atingir o valor-alvo.',
    );
  return _GoalInsightCopy(
    'Acompanhamento da meta',
    'Faltam ${formatMoney(goal.remainingAmount)} e $days ${days == 1 ? 'dia' : 'dias'} até o prazo cadastrado.',
  );
}

List<_MovementPoint> _movementPoints(
  SavingsGoal goal,
  List<SavingsGoalMovement> movements,
) {
  final ordered = [...movements]
    ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  final net = ordered.fold<double>(
    0,
    (total, item) => total + (item.isContribution ? item.amount : -item.amount),
  );
  var balance = math.max(0, goal.savedAmount - net).toDouble();
  return ordered.map((item) {
    balance += item.isContribution ? item.amount : -item.amount;
    return _MovementPoint(item.occurredAt, math.max(0, balance).toDouble());
  }).toList();
}
