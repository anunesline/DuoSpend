import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../domain/models/budget_consumption.dart';

Color budgetCategoryColor(String category) {
  final value = _normalizeCategory(category);
  if (value.contains('aliment') || value.contains('mercado')) {
    return const Color(0xFFFF921F);
  }
  if (value.contains('transporte')) return const Color(0xFF3995FF);
  if (value.contains('moradia') || value.contains('casa')) {
    return const Color(0xFF3BCC72);
  }
  if (value.contains('compra')) return const Color(0xFFF4B51B);
  if (value.contains('lazer')) return const Color(0xFFA782FF);
  if (value.contains('saude')) return const Color(0xFFFF5C6C);
  if (value.contains('pet')) return const Color(0xFFF6F8FB);
  if (value.contains('educa')) return const Color(0xFF22B8CF);
  if (value.contains('conta') || value.contains('servic')) {
    return const Color(0xFFF59E0B);
  }
  if (value.contains('invest')) return const Color(0xFF10B981);
  if (value.contains('viagem')) return const Color(0xFF60A5FA);
  if (value.contains('presente')) return const Color(0xFFC084FC);
  if (value.contains('divida') || value.contains('parcela')) {
    return const Color(0xFFEF4444);
  }
  return const Color(0xFF98A2B3);
}

String _normalizeCategory(String category) {
  var value = category.trim().toLowerCase();
  const replacements = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  for (final entry in replacements.entries) {
    value = value.replaceAll(entry.key, entry.value);
  }
  return value;
}

IconData budgetCategoryIcon(String category) {
  final value = _normalizeCategory(category);
  if (value.contains('aliment') || value.contains('mercado')) {
    return Icons.restaurant_outlined;
  }
  if (value.contains('transporte')) return Icons.directions_car_outlined;
  if (value.contains('moradia') || value.contains('casa')) {
    return Icons.home_outlined;
  }
  if (value.contains('compra')) return Icons.shopping_bag_outlined;
  if (value.contains('lazer')) return Icons.sports_esports_outlined;
  if (value.contains('saúde') || value.contains('saude')) {
    return Icons.favorite_border;
  }
  if (value.contains('pet')) return Icons.pets_outlined;
  if (value.contains('educa')) return Icons.school_outlined;
  if (value.contains('conta') || value.contains('servic')) {
    return Icons.receipt_long_outlined;
  }
  if (value.contains('invest')) return Icons.trending_up;
  if (value.contains('viagem')) return Icons.flight_outlined;
  if (value.contains('presente')) return Icons.card_giftcard_outlined;
  if (value.contains('divida') || value.contains('parcela')) {
    return Icons.credit_card_outlined;
  }
  if (value.contains('outro')) return Icons.category_outlined;
  return Icons.more_horiz;
}

class BudgetPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool accent;
  const BudgetPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: accent ? const Color(0xFF191228) : DuoColors.orbitSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: accent
            ? DuoColors.orbitAccent.withValues(alpha: .4)
            : DuoColors.orbitBorder,
      ),
    ),
    child: child,
  );
}

class BudgetCategoryRow extends StatelessWidget {
  final BudgetConsumption item;
  final NumberFormat money;
  final VoidCallback? onTap;
  final String? scopeLabel;
  const BudgetCategoryRow({
    super.key,
    required this.item,
    required this.money,
    this.onTap,
    this.scopeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = budgetCategoryColor(item.budget.category);
    final statusColor = item.health == BudgetHealth.exceeded
        ? DuoColors.error
        : color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: .09),
                border: Border.all(color: color.withValues(alpha: .3)),
              ),
              child: Icon(
                budgetCategoryIcon(item.budget.category),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.budget.category,
                          style: const TextStyle(
                            fontSize: 15,
                            color: DuoColors.orbitTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statusColor.withValues(alpha: .15),
                          ),
                        ),
                        child: Text(
                          '${item.percentageDisplay.round()}%',
                          style: TextStyle(color: statusColor, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${money.format(item.spentAmount)} de ${money.format(item.budget.limitAmount)}',
                    style: const TextStyle(
                      color: DuoColors.orbitTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (scopeLabel != null)
                    Text(
                      scopeLabel!,
                      style: const TextStyle(
                        color: DuoColors.orbitTextSecondary,
                        fontSize: 10,
                      ),
                    ),
                  const SizedBox(height: 8),
                  BudgetProgress(
                    value: item.percentage,
                    color: statusColor,
                    height: 4,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.budget.isPaused ? 'Pausado · ' : ''}${item.remainingAmount < 0 ? 'Excedido: ${money.format(-item.remainingAmount)}' : 'Disponível: ${money.format(item.remainingAmount)}'}',
                    style: TextStyle(
                      color: item.remainingAmount < 0
                          ? DuoColors.error
                          : DuoColors.success,
                      fontSize: 11,
                    ),
                  ),
                  if (item.health == BudgetHealth.attention)
                    const Text(
                      'Atenção ao limite',
                      style: TextStyle(color: DuoColors.warning, fontSize: 10),
                    ),
                ],
              ),
            ),
            if (onTap != null)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.chevron_right,
                  color: DuoColors.orbitTextSecondary,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BudgetProgress extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const BudgetProgress({
    super.key,
    required this.value,
    this.color = DuoColors.orbitAccent,
    this.height = 8,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: LinearProgressIndicator(
      value: value.clamp(0.0, 1.0),
      minHeight: height,
      backgroundColor: const Color(0xFF252A34),
      color: color,
    ),
  );
}

class BudgetMonthSummary extends StatelessWidget {
  final List<BudgetConsumption> items;
  final DateTime month;
  final NumberFormat money;
  final VoidCallback onHelp;
  const BudgetMonthSummary({
    super.key,
    required this.items,
    required this.month,
    required this.money,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    final limit = items.fold<double>(
      0,
      (sum, item) => sum + item.budget.limitAmount,
    );
    final spent = items.fold<double>(0, (sum, item) => sum + item.spentAmount);
    final ratio = limit > 0 ? spent / limit : 0.0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    final isCurrent = now.year == month.year && now.month == month.month;
    final elapsed = isCurrent
        ? now.day / dayCount
        : (today.isBefore(month) ? 0.0 : 1.0);
    final daysLabel = isCurrent
        ? '${dayCount - now.day} dias restantes neste mês'
        : today.isBefore(month)
        ? 'Mês ainda não iniciado · $dayCount dias'
        : 'Mês encerrado';
    final ring = SizedBox(
      width: 116,
      height: 116,
      child: Semantics(
        label: '${(ratio * 100).round()} por cento utilizado',
        child: CustomPaint(
          painter: _BudgetRingPainter(items: items, limit: limit),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(ratio * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 27,
                    color: DuoColors.orbitTextPrimary,
                  ),
                ),
                const Text(
                  'utilizado',
                  style: TextStyle(
                    color: DuoColors.orbitTextSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Widget metric(String label, double value, Color color) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: DuoColors.orbitTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(money.format(value), style: TextStyle(fontSize: 14, color: color)),
      ],
    );
    final metrics = LayoutBuilder(
      builder: (context, constraints) {
        final children = [
          metric('Limite total', limit, DuoColors.orbitTextPrimary),
          metric('Gasto', spent, DuoColors.orbitAccent),
          metric(
            'Disponível',
            limit - spent,
            spent > limit ? DuoColors.error : DuoColors.success,
          ),
        ];
        if (constraints.maxWidth < 270 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Wrap(spacing: 16, runSpacing: 12, children: children);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: DuoColors.orbitBorder,
                ),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
    final timeline = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          daysLabel,
          style: const TextStyle(
            color: DuoColors.orbitTextSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label: 'Progresso do período mensal',
          value: '${(elapsed * 100).round()}%',
          child: BudgetProgress(value: elapsed),
        ),
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0%',
              style: TextStyle(
                fontSize: 10,
                color: DuoColors.orbitTextSecondary,
              ),
            ),
            Text(
              '50%',
              style: TextStyle(
                fontSize: 10,
                color: DuoColors.orbitTextSecondary,
              ),
            ),
            Text(
              '100%',
              style: TextStyle(
                fontSize: 10,
                color: DuoColors.orbitTextSecondary,
              ),
            ),
          ],
        ),
      ],
    );
    return BudgetPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Resumo do mês', style: TextStyle(fontSize: 17)),
              IconButton(
                tooltip: 'Entenda seus orçamentos',
                onPressed: onHelp,
                icon: const Icon(
                  Icons.info_outline,
                  size: 17,
                  color: DuoColors.orbitTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 490) {
                return Row(
                  children: [
                    ring,
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          metrics,
                          const SizedBox(height: 24),
                          timeline,
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      ring,
                      const SizedBox(width: 18),
                      Expanded(child: timeline),
                    ],
                  ),
                  const SizedBox(height: 20),
                  metrics,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BudgetRingPainter extends CustomPainter {
  final List<BudgetConsumption> items;
  final double limit;
  const _BudgetRingPainter({required this.items, required this.limit});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(6, 6) & Size(size.width - 12, size.height - 12);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = const Color(0xFF292D34);
    canvas.drawArc(rect, 0, math.pi * 2, false, paint);
    if (limit <= 0) return;
    final totalSpent = items.fold<double>(
      0,
      (sum, item) => sum + math.max(0, item.spentAmount),
    );
    final denominator = math.max(limit, totalSpent);
    var start = -math.pi / 2;
    for (final item in items) {
      final sweep = math.max(0, item.spentAmount) / denominator * math.pi * 2;
      if (sweep == 0) continue;
      paint.color = budgetCategoryColor(item.budget.category);
      canvas.drawArc(rect, start, math.max(0, sweep - .018), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetRingPainter oldDelegate) =>
      oldDelegate.items != items || oldDelegate.limit != limit;
}

class BudgetEvolutionChart extends StatelessWidget {
  final List<double> values;
  final DateTime month;
  const BudgetEvolutionChart({
    super.key,
    required this.values,
    required this.month,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Evolução das despesas acumuladas. Consulte os valores diários em Ver evolução completa.',
    child: Column(
      children: [
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: CustomPaint(
              painter: _EvolutionPainter(
                values,
                DateTime(month.year, month.month + 1, 0).day,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1 ${DateFormat('MMM', 'pt_BR').format(month).toUpperCase()}',
              style: const TextStyle(
                fontSize: 9,
                color: DuoColors.orbitTextSecondary,
              ),
            ),
            Text(
              '${DateTime(month.year, month.month + 1, 0).day} ${DateFormat('MMM', 'pt_BR').format(month).toUpperCase()}',
              style: const TextStyle(
                fontSize: 9,
                color: DuoColors.orbitTextSecondary,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _EvolutionPainter extends CustomPainter {
  final List<double> values;
  final int days;
  const _EvolutionPainter(this.values, this.days);
  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 5;
    final grid = Paint()
      ..color = DuoColors.orbitBorder
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseline), Offset(size.width, baseline), grid);
    if (values.isEmpty) return;
    final maxValue = math.max(1.0, values.reduce(math.max));
    final path = Path()..moveTo(0, baseline);
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i + 1) / days;
      final y = baseline - (values[i] / maxValue) * (size.height - 12);
      path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = DuoColors.orbitAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    final last = Offset(
      size.width * values.length / days,
      baseline - values.last / maxValue * (size.height - 12),
    );
    canvas.drawCircle(last, 3, Paint()..color = DuoColors.orbitAccent);
  }

  @override
  bool shouldRepaint(covariant _EvolutionPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.days != days;
}
