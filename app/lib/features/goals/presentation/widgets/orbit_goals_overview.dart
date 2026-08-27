import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../domain/models/savings_goal.dart';

class OrbitGoalsSummary extends StatelessWidget {
  final double totalSaved;
  final double totalTarget;
  final int activeGoals;
  final String Function(double) formatMoney;

  const OrbitGoalsSummary({
    super.key,
    required this.totalSaved,
    required this.totalTarget,
    required this.activeGoals,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalTarget <= 0 ? 0.0 : (totalSaved / totalTarget).clamp(0.0, 1.0);
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
              Icon(Icons.auto_awesome_rounded, color: DuoColors.primaryLight, size: 18),
              SizedBox(width: 8),
              Text('Seus sonhos em movimento', style: TextStyle(color: DuoColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),
          Text(formatMoney(totalSaved), style: const TextStyle(color: DuoColors.textPrimary, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 4),
          Text('guardados de ${formatMoney(totalTarget)}', style: const TextStyle(color: DuoColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: DuoColors.surfaceLight, valueColor: const AlwaysStoppedAnimation<Color>(DuoColors.primary)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$activeGoals ${activeGoals == 1 ? 'meta ativa' : 'metas ativas'}', style: const TextStyle(color: DuoColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              Text('${(progress * 100).toStringAsFixed(0)}% do total', style: const TextStyle(color: DuoColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class OrbitGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final String saved;
  final String target;
  final String remaining;
  final String? deadline;
  final bool processing;
  final VoidCallback onHistory;
  final VoidCallback? onEdit;
  final VoidCallback? onContribute;
  final VoidCallback? onWithdraw;
  final VoidCallback? onArchive;

  const OrbitGoalCard({
    super.key,
    required this.goal,
    required this.saved,
    required this.target,
    required this.remaining,
    required this.deadline,
    required this.processing,
    required this.onHistory,
    this.onEdit,
    this.onContribute,
    this.onWithdraw,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final accent = goal.isArchived ? DuoColors.textHint : goal.isCompleted ? DuoColors.success : DuoColors.primaryLight;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DuoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DuoColors.border),
        boxShadow: DuoColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: accent.withValues(alpha: .13), borderRadius: BorderRadius.circular(15)),
                child: Icon(goal.isCompleted ? Icons.emoji_events_rounded : Icons.flag_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(goal.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DuoColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(goal.isCompleted ? 'Sonho realizado ✨' : 'Faltam $remaining', style: TextStyle(color: goal.isCompleted ? DuoColors.success : DuoColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              ])),
              Text('${goal.progressPercentage.toStringAsFixed(0)}%', style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w900)),
              PopupMenuButton<String>(
                enabled: !processing,
                color: DuoColors.surface,
                icon: const Icon(Icons.more_horiz_rounded, color: DuoColors.textHint),
                onSelected: (value) {
                  if (value == 'history') onHistory();
                  if (value == 'edit') onEdit?.call();
                  if (value == 'archive') onArchive?.call();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'history', child: Text('Histórico')),
                  if (onEdit != null) const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  if (onArchive != null) const PopupMenuItem(value: 'archive', child: Text('Arquivar')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 17),
          ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: goal.progress, minHeight: 8, backgroundColor: DuoColors.surfaceLight, valueColor: AlwaysStoppedAnimation<Color>(accent))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(saved, style: const TextStyle(color: DuoColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
            Text('Meta $target', style: const TextStyle(color: DuoColors.textSecondary, fontSize: 11)),
          ]),
          if (deadline != null) ...[
            const SizedBox(height: 9),
            Row(children: [const Icon(Icons.calendar_today_rounded, size: 13, color: DuoColors.textHint), const SizedBox(width: 6), Text('Até $deadline', style: const TextStyle(color: DuoColors.textHint, fontSize: 10))]),
          ],
          if (onContribute != null || onWithdraw != null) ...[
            const SizedBox(height: 16),
            Row(children: [
              if (onWithdraw != null) Expanded(child: OutlinedButton.icon(onPressed: processing ? null : onWithdraw, icon: const Icon(Icons.remove_rounded, size: 17), label: const Text('Retirar'))),
              if (onWithdraw != null && onContribute != null) const SizedBox(width: 8),
              if (onContribute != null) Expanded(child: FilledButton.icon(onPressed: processing ? null : onContribute, icon: const Icon(Icons.add_rounded, size: 17), label: const Text('Guardar'))),
            ]),
          ],
        ],
      ),
    );
  }
}
