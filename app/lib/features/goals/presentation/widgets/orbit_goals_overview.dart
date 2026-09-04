import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../domain/models/savings_goal.dart';
import '../../domain/models/savings_goal_movement.dart';

class OrbitGoalHeroCard extends StatelessWidget {
  final SavingsGoal goal;
  final String Function(double) formatMoney;
  final String Function(DateTime) formatDate;

  const OrbitGoalHeroCard({
    super.key,
    required this.goal,
    required this.formatMoney,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _goalAccent(goal);
    final deadline = goal.deadline;
    final days = deadline == null ? null : _daysUntil(deadline);
    return _OrbitSurface(
      borderColor: DuoColors.primary.withValues(alpha: .5),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GoalIcon(goal: goal, accent: accent),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DuoColors.textPrimary,
                        fontSize: 19,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusPill(goal: goal, accent: accent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
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
                  children: [ring, const SizedBox(height: 20), values],
                );
              }
              return Row(
                children: [
                  ring,
                  const SizedBox(width: 22),
                  Expanded(child: values),
                ],
              );
            },
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
    return _OrbitSurface(
      padding: const EdgeInsets.all(16),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF171326), Color(0xFF10141C)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: DuoColors.primary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DuoColors.primaryLight.withValues(alpha: .25),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 19,
              color: DuoColors.primaryLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Orbit acompanha esta meta',
                  style: TextStyle(
                    color: DuoColors.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  insight.title,
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: const TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 12,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth < 300
            ? constraints.maxWidth
            : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricCard(
              width: itemWidth,
              label: 'Falta para a meta',
              value: formatMoney(goal.remainingAmount),
              icon: Icons.flag_outlined,
              accent: DuoColors.primaryLight,
            ),
            _MetricCard(
              width: itemWidth,
              label: 'Progresso real',
              value: '${goal.progressPercentage.toStringAsFixed(0)}%',
              icon: Icons.donut_large_rounded,
              accent: DuoColors.success,
            ),
            _MetricCard(
              width: itemWidth,
              label: 'Aportes registrados',
              value: movements == null ? 'Carregando' : '$contributions',
              icon: Icons.add_circle_outline_rounded,
              accent: DuoColors.success,
            ),
            _MetricCard(
              width: itemWidth,
              label: 'Retiradas registradas',
              value: movements == null ? 'Carregando' : '$withdrawals',
              icon: Icons.remove_circle_outline_rounded,
              accent: DuoColors.warning,
            ),
          ],
        );
      },
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
        const _SectionTitle(
          title: 'Evolução da meta',
          subtitle: 'Construída somente com movimentações reais',
        ),
        const SizedBox(height: 10),
        _OrbitSurface(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
          child: SizedBox(
            height: 190,
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
        const SizedBox(height: 8),
        _OrbitSurface(
          padding: EdgeInsets.zero,
          child: isLoading
              ? const SizedBox(
                  height: 92,
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
        const _SectionTitle(
          title: 'Para acompanhar seu sonho',
          subtitle: 'Informações baseadas no cadastro da meta',
        ),
        const SizedBox(height: 10),
        _OrbitSurface(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _GuidanceTile(item: items[index]),
                if (index != items.length - 1) const SizedBox(height: 12),
              ],
            ],
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
        const SizedBox(height: 10),
        _OrbitSurface(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
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
        ),
      ],
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
                        : Icons.flag_rounded,
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
                  : Icons.flag_rounded,
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
      width: 132,
      height: 132,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: goal.progress,
            strokeWidth: 14,
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
                    fontSize: 29,
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
            fontSize: 23,
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
          const SizedBox(height: 15),
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
              height: 3,
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
        const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(11),
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

class _MetricCard extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: _OrbitSurface(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DuoColors.textSecondary,
                      fontSize: 9.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DuoColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: item.accent.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(11),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.message,
                style: const TextStyle(
                  color: DuoColors.textSecondary,
                  fontSize: 10.5,
                  height: 1.35,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      visualDensity: VisualDensity.compact,
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
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent.withValues(alpha: .42), accent.withValues(alpha: .12)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: accent.withValues(alpha: .55)),
    ),
    child: Icon(
      goal.isCompleted ? Icons.emoji_events_rounded : Icons.flag_rounded,
      color: accent,
      size: 25,
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
          fontSize: 16,
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
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: DuoColors.primaryLight, size: 26),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
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
  const _OrbitSurface({
    required this.child,
    required this.padding,
    this.borderColor,
    this.gradient,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: gradient == null ? DuoColors.surface : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(20),
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
    : DuoColors.primaryLight;

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
