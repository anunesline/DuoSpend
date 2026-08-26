import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../domain/models/orbit_dashboard_summary.dart';

class OrbitMonthSummary extends StatelessWidget {
  final OrbitDashboardSummary summary;
  final bool isLoading;
  final VoidCallback onBudgetTap;
  final VoidCallback onGoalTap;
  final VoidCallback onInvoiceTap;

  const OrbitMonthSummary({
    super.key,
    required this.summary,
    required this.isLoading,
    required this.onBudgetTap,
    required this.onGoalTap,
    required this.onInvoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const DuoCard(
        borderRadius: 20,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(child: CircularProgressIndicator(color: DuoColors.primary)),
        ),
      );
    }

    final rows = <Widget>[
      _SummaryRow(
        icon: Icons.pie_chart_rounded,
        color: DuoColors.warning,
        title: 'Orçamento do mês',
        subtitle: _budgetSubtitle(summary.budget),
        progress: summary.budget?.usage,
        onTap: onBudgetTap,
      ),
      _SummaryRow(
        icon: Icons.savings_rounded,
        color: DuoColors.success,
        title: summary.goal?.name ?? 'Metas',
        subtitle: _goalSubtitle(summary.goal),
        progress: summary.goal?.progress,
        onTap: onGoalTap,
      ),
      _SummaryRow(
        icon: Icons.credit_card_rounded,
        color: DuoColors.primaryLight,
        title: 'Cartões e faturas',
        subtitle: _invoiceSubtitle(summary.invoice),
        onTap: onInvoiceTap,
      ),
    ];

    return DuoCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (var index = 0; index < rows.length; index++) ...[
          rows[index],
          if (index != rows.length - 1)
            Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: DuoColors.divider),
        ],
      ]),
    );
  }

  String _budgetSubtitle(OrbitBudgetSummary? budget) {
    if (budget == null) return 'Crie um orçamento para acompanhar seus limites';
    final usage = budget.usagePercentage.round();
    final base = '${_money(budget.spentAmount)} de ${_money(budget.limitAmount)} · $usage% usado';
    if (budget.isOverLimit) return '$base · limite excedido';
    if (usage >= 80 && budget.highestRiskCategory != null) {
      return '$base · atenção em ${budget.highestRiskCategory}';
    }
    return base;
  }

  String _goalSubtitle(OrbitGoalSummary? goal) {
    if (goal == null) return 'Crie uma meta e acompanhe o progresso aqui';
    final progress = goal.progressPercentage.round();
    return '${_money(goal.savedAmount)} de ${_money(goal.targetAmount)} · $progress% concluída';
  }

  String _invoiceSubtitle(OrbitInvoiceSummary? invoice) {
    if (invoice == null) return 'Nenhuma fatura aberta neste mês';
    final due = DateFormat("dd/MM", 'pt_BR').format(invoice.dueDate);
    final label = invoice.invoiceCount == 1 ? 'fatura' : '${invoice.invoiceCount} faturas';
    return '${_money(invoice.total)} · $label · vence $due';
  }

  String _money(double value) => NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2).format(value);
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final double? progress;
  final VoidCallback onTap;

  const _SummaryRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DuoColors.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: DuoColors.textSecondary, height: 1.3)),
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: DuoColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: DuoColors.textHint, size: 20),
          ]),
        ),
      ),
    );
  }
}
