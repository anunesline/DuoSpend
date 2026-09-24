import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../financial_intelligence/domain/models/financial_insight.dart';
import '../../../goals/domain/models/savings_goal.dart';
import '../../../goals/presentation/widgets/goal_category_visuals.dart';
import '../../../household_routines/domain/models/household_task.dart';
import '../../../reports/domain/models/financial_report.dart';
import '../../../transactions/domain/calendar/financial_calendar_entry.dart';
import '../../domain/models/orbit_home_overview.dart';
import 'orbit_home_primitives.dart';
import 'orbit_insight_card.dart' show selectOrbitPriorityInsight;

/// Both contexts use the same surfaces, headings, spacing and navigation.
/// This widget is presentation-only: every number comes from the overview.
class OrbitHomeContent extends StatelessWidget {
  final OrbitHomeOverview data;
  final bool valuesVisible;
  final VoidCallback onWallet;
  final VoidCallback onBudget;
  final VoidCallback onCalendar;
  final VoidCallback onGoals;
  final VoidCallback onInsights;
  final VoidCallback onRoutines;
  final VoidCallback onSettlements;
  final VoidCallback onContribution;
  final VoidCallback onHistory;
  final VoidCallback onRetry;
  final ValueChanged<HouseholdTask> onCompleteTask;
  final Set<String> completingTasks;

  const OrbitHomeContent({
    super.key,
    required this.data,
    required this.valuesVisible,
    required this.onWallet,
    required this.onBudget,
    required this.onCalendar,
    required this.onGoals,
    required this.onInsights,
    required this.onRoutines,
    required this.onSettlements,
    required this.onContribution,
    required this.onHistory,
    required this.onRetry,
    required this.onCompleteTask,
    this.completingTasks = const {},
  });

  @override
  Widget build(BuildContext context) {
    final shared = data.wallet.isShared;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (shared) ...[
          _SharedSummary(
            data: data,
            visible: valuesVisible,
            onDetails: onWallet,
            onSpending: onHistory,
            onCalendar: onCalendar,
          ),
          const SizedBox(height: OrbitHomeTokens.gap),
          _SettlementCard(
            data: data,
            visible: valuesVisible,
            onTap: onSettlements,
          ),
          const SizedBox(height: OrbitHomeTokens.gap),
          _ContributionCard(
            data: data,
            visible: valuesVisible,
            onTap: onContribution,
          ),
          const SizedBox(height: OrbitHomeTokens.gap),
          _CommitmentsCard(
            data: data,
            visible: valuesVisible,
            onTap: onCalendar,
          ),
          const SizedBox(height: OrbitHomeTokens.gap),
          _SharedGoalsCard(data: data, visible: valuesVisible, onTap: onGoals),
        ] else ...[
          _SoloBalanceCard(
            data: data,
            visible: valuesVisible,
            onWallet: onWallet,
            onCalendar: onCalendar,
          ),
          const SizedBox(height: OrbitHomeTokens.gap),
          _BudgetCard(data: data, visible: valuesVisible, onTap: onBudget),
          const SizedBox(height: OrbitHomeTokens.gap),
          LayoutBuilder(
            builder: (context, constraints) {
              final items = [
                _BillsCard(data: data, onTap: onCalendar),
                _SoloGoalCard(
                  data: data,
                  visible: valuesVisible,
                  onTap: onGoals,
                ),
              ];
              if (constraints.maxWidth < 315 ||
                  MediaQuery.textScalerOf(context).scale(14) > 19) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [items[0], const SizedBox(height: 10), items[1]],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 9, child: items[0]),
                    const SizedBox(width: 12),
                    Expanded(flex: 11, child: items[1]),
                  ],
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 10),
        OrbitHomeSectionTitle(
          title: shared ? 'Insights para vocês' : 'Insights da IA',
          icon: Icons.bolt_rounded,
          action: 'Ver tudo',
          onAction: onInsights,
        ),
        const SizedBox(height: 3),
        _InsightCard(data: data, visible: valuesVisible, onTap: onInsights),
        const SizedBox(height: 9),
        OrbitHomeSectionTitle(
          title: shared ? 'Rotinas da casa' : 'Rotinas de hoje',
          icon: Icons.check_box_outlined,
          color: OrbitHomeTokens.green,
          action: 'Ver todas',
          onAction: onRoutines,
        ),
        const SizedBox(height: 3),
        if (data.errors.containsKey(OrbitHomeSection.routines))
          OrbitHomeMessage(
            message:
                'Não foi possível carregar as rotinas. Toque para tentar novamente.',
            onTap: onRetry,
          )
        else if (data.todayTasks.isEmpty)
          OrbitHomeMessage(
            message: shared && data.wallet.memberIds.length < 2
                ? 'Conecte alguém à carteira para organizar as rotinas da casa.'
                : 'Nenhuma rotina para hoje. Organize seu próximo passo.',
            icon: Icons.task_alt_rounded,
            onTap: shared && data.wallet.memberIds.length < 2
                ? onWallet
                : onRoutines,
          )
        else
          for (final task in data.todayTasks.take(3)) ...[
            _RoutineRow(
              task: task,
              busy: completingTasks.contains(task.id),
              onComplete: () => onCompleteTask(task),
              onOpen: onRoutines,
            ),
            const SizedBox(height: 7),
          ],
        if (data.overdueTaskCount > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRoutines,
              icon: const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: OrbitHomeTokens.amber,
              ),
              label: Text(
                '${data.overdueTaskCount} ${data.overdueTaskCount == 1 ? 'rotina atrasada' : 'rotinas atrasadas'}',
                style: const TextStyle(
                  color: OrbitHomeTokens.amber,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        if (data.pendingConfirmationCount > 0) ...[
          const SizedBox(height: 8),
          OrbitHomeMessage(
            message:
                '${data.pendingConfirmationCount} ${data.pendingConfirmationCount == 1 ? 'despesa aguarda' : 'despesas aguardam'} sua confirmação.',
            onTap: onHistory,
            icon: Icons.fact_check_outlined,
          ),
        ],
      ],
    );
  }
}

class _SoloBalanceCard extends StatelessWidget {
  final OrbitHomeOverview data;
  final bool visible;
  final VoidCallback onWallet;
  final VoidCallback onCalendar;
  const _SoloBalanceCard({
    required this.data,
    required this.visible,
    required this.onWallet,
    required this.onCalendar,
  });
  @override
  Widget build(BuildContext context) => OrbitHomeSurface(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final balanceColor = visible
            ? OrbitHomeTokens.balanceColor(data.wallet.balance)
            : OrbitHomeTokens.muted;
        final left = InkWell(
          onTap: onWallet,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Caption('Saldo disponível'),
                const SizedBox(height: 6),
                _Amount(
                  orbitMoney(data.wallet.balance, visible: visible),
                  size: 23,
                ),
                const SizedBox(height: 7),
                Text(
                  data.wallet.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: OrbitHomeTokens.muted,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: balanceColor,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ],
            ),
          ),
        );
        final projected = data.projection?.projectedBalance;
        final right = InkWell(
          onTap: onCalendar,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Caption('Saldo previsto'),
                Text(
                  'até ${DateFormat('dd/MM').format(DateTime(data.reference.year, data.reference.month + 1, 0))}',
                  style: const TextStyle(
                    color: OrbitHomeTokens.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                _Amount(
                  projected == null
                      ? 'Indisponível'
                      : orbitMoney(projected, visible: visible),
                  size: projected == null ? 13 : 19,
                ),
                const SizedBox(height: 7),
                // A sign indicator, not an invented completion percentage.
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: projected == null || !visible
                        ? OrbitHomeTokens.border
                        : OrbitHomeTokens.balanceColor(projected),
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ],
            ),
          ),
        );
        if (constraints.maxWidth < 285 ||
            MediaQuery.textScalerOf(context).scale(14) > 21) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: OrbitHomeTokens.border, height: 1),
              ),
              right,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 6, child: left),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: VerticalDivider(width: 1, color: OrbitHomeTokens.border),
              ),
              Expanded(flex: 5, child: right),
            ],
          ),
        );
      },
    ),
  );
}

class _BudgetCard extends StatelessWidget {
  final OrbitHomeOverview data;
  final bool visible;
  final VoidCallback onTap;
  const _BudgetCard({
    required this.data,
    required this.visible,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final budget = data.summary.budget;
    final failed = data.errors.containsKey(OrbitHomeSection.budget);
    return OrbitHomeSurface(
      onTap: onTap,
      child: Row(
        children: [
          const OrbitHomeIcon(
            icon: Icons.account_balance_wallet_outlined,
            color: OrbitHomeTokens.purple,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orçamento de ${DateFormat.MMMM('pt_BR').format(data.reference)}',
                  style: const TextStyle(
                    color: OrbitHomeTokens.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                if (failed)
                  const _Caption('Resumo indisponível')
                else if (budget == null)
                  const _Caption('Defina seu orçamento do mês')
                else ...[
                  Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        orbitMoney(budget.spentAmount, visible: visible),
                        style: const TextStyle(
                          color: OrbitHomeTokens.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'de ${orbitMoney(budget.limitAmount, visible: visible)}',
                        style: const TextStyle(
                          color: OrbitHomeTokens.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: OrbitHomeProgress(
                          value: visible ? budget.progress : null,
                          colors: budget.isOverLimit
                              ? const [OrbitHomeTokens.red, OrbitHomeTokens.red]
                              : const [
                                  OrbitHomeTokens.purple,
                                  Color(0xFF57CBDD),
                                  OrbitHomeTokens.green,
                                ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        visible ? '${budget.usagePercentage.round()}%' : '••',
                        style: TextStyle(
                          color: budget.isOverLimit && visible
                              ? OrbitHomeTokens.red
                              : OrbitHomeTokens.text,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (budget == null)
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: OrbitHomeTokens.purple,
            ),
        ],
      ),
    );
  }
}

class _BillsCard extends StatelessWidget {
  final OrbitHomeOverview data;
  final VoidCallback onTap;
  const _BillsCard({required this.data, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final failed = data.errors.containsKey(OrbitHomeSection.calendar);
    final count = data.commitments.length;
    final first = data.commitments.firstOrNull;
    return OrbitHomeSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OrbitHomeIcon(
            icon: Icons.calendar_month_outlined,
            color: OrbitHomeTokens.cyan,
            size: 34,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  failed
                      ? 'Contas'
                      : count == 0
                      ? 'Tudo em dia'
                      : '$count ${count == 1 ? 'conta' : 'contas'}',
                  style: const TextStyle(
                    color: OrbitHomeTokens.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  failed
                      ? 'Resumo indisponível'
                      : count == 0
                      ? 'Sem vencimentos'
                      : 'a vencer',
                  style: const TextStyle(
                    color: OrbitHomeTokens.text,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  first == null
                      ? 'Próximos 30 dias'
                      : '${_dueLabel(first.date, data.reference)}: ${first.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OrbitHomeTokens.muted,
                    fontSize: 10,
                    height: 1.4,
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

class _SoloGoalCard extends StatelessWidget {
  final OrbitHomeOverview data;
  final bool visible;
  final VoidCallback onTap;
  const _SoloGoalCard({
    required this.data,
    required this.visible,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final goal = data.goals.firstOrNull;
    return OrbitHomeSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OrbitHomeIcon(
            icon: Icons.track_changes_rounded,
            color: OrbitHomeTokens.green,
            size: 34,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meta em andamento',
                  style: TextStyle(color: OrbitHomeTokens.muted, fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  data.errors.containsKey(OrbitHomeSection.goals)
                      ? 'Resumo indisponível'
                      : goal?.name ?? 'Seu próximo sonho',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OrbitHomeTokens.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                if (goal != null) ...[
                  Text(
                    visible
                        ? '${goal.progressPercentage.round()}% concluído'
                        : 'Progresso oculto',
                    style: const TextStyle(
                      color: OrbitHomeTokens.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  OrbitHomeProgress(value: visible ? goal.progress : null),
                ] else if (!data.errors.containsKey(OrbitHomeSection.goals))
                  const Text(
                    'Criar uma meta',
                    style: TextStyle(
                      color: OrbitHomeTokens.green,
                      fontSize: 11,
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

class _SharedSummary extends StatelessWidget {
  final OrbitHomeOverview data;
  final bool visible;
  final VoidCallback onDetails;
  final VoidCallback onSpending;
  final VoidCallback onCalendar;
  const _SharedSummary({
    required this.data,
    required this.visible,
    required this.onDetails,
    required this.onSpending,
    required this.onCalendar,
  });
  @override
  Widget build(BuildContext context) {
    final budget = data.summary.budget;
    final metrics = [
      _Metric(
        label: 'Total disponível',
        value: orbitMoney(data.wallet.balance, visible: visible),
        color: visible
            ? OrbitHomeTokens.balanceColor(data.wallet.balance)
            : OrbitHomeTokens.muted,
        subtitle: data.wallet.name,
        onTap: onDetails,
      ),
      _Metric(
        label: 'Gastos do mês',
        value: orbitMoney(data.monthReport.totalExpense, visible: visible),
        color: OrbitHomeTokens.purple,
        subtitle: !visible
            ? 'Valores ocultos'
            : budget == null
            ? 'Despesas confirmadas'
            : '${budget.usagePercentage.round()}% do orçamento',
        onTap: onSpending,
      ),
      _Metric(
        label: 'Comprometido',
        value: data.projection == null
            ? '—'
            : orbitMoney(data.committedAmount, visible: visible),
        color: OrbitHomeTokens.amber,
        subtitle: data.projection == null ? 'Indisponível' : 'Próximos 30 dias',
        onTap: onCalendar,
      ),
    ];
    return OrbitHomeSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Resumo de nós',
                  style: TextStyle(
                    color: OrbitHomeTokens.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              OrbitHomeAction(
                label: 'Ver detalhes',
                onTap: onDetails,
                outlined: true,
              ),
            ],
          ),
          Text(
            DateFormat.yMMMM('pt_BR').format(data.reference),
            style: const TextStyle(color: OrbitHomeTokens.muted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 305 ||
                  MediaQuery.textScalerOf(context).scale(13) > 18) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < metrics.length; i++) ...[
                      metrics[i],
                      if (i < 2)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            color: OrbitHomeTokens.border,
                            height: 1,
                          ),
                        ),
                    ],
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < metrics.length; i++) ...[
                      if (i > 0)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 9),
                          child: VerticalDivider(
                            width: 1,
                            color: OrbitHomeTokens.border,
                          ),
                        ),
                      Expanded(child: metrics[i]),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // This strip represents actual spending by category, not a comparison
          // between incompatible totals such as balance and future commitments.
          _SpendingStrip(report: data.monthReport, visible: visible),
          const SizedBox(height: 5),
          const Text(
            'Distribuição dos gastos do mês',
            style: TextStyle(color: OrbitHomeTokens.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _Metric({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: OrbitHomeTokens.text, fontSize: 11),
        ),
        const SizedBox(height: 3),
        _Amount(value, color: color, size: 15),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: OrbitHomeTokens.muted,
            fontSize: 10,
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}

class _SpendingStrip extends StatelessWidget {
  final FinancialReport report;
  final bool visible;
  const _SpendingStrip({required this.report, required this.visible});
  @override
  Widget build(BuildContext context) {
    const colors = [
      OrbitHomeTokens.purple,
      OrbitHomeTokens.amber,
      OrbitHomeTokens.cyan,
      OrbitHomeTokens.green,
    ];
    final categories = report.expenseByCategory;
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        height: 7,
        child: !visible || report.totalExpense <= 0
            ? const ColoredBox(color: OrbitHomeTokens.border)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < categories.length; i++)
                    if (categories[i].amount > 0)
                      Expanded(
                        flex: math.max(1, (categories[i].amount * 100).round()),
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: i == categories.length - 1 ? 0 : 2,
                          ),
                          child: ColoredBox(color: colors[i % colors.length]),
                        ),
                      ),
                ],
              ),
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final OrbitHomeOverview data;
  final bool visible;
  final VoidCallback onTap;
  const _SettlementCard({
    required this.data,
    required this.visible,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final settlement = data.settlements.firstOrNull;
    final failed = data.errors.containsKey(OrbitHomeSection.settlements);
    return OrbitHomeSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Acerto entre vocês',
                  style: TextStyle(
                    color: OrbitHomeTokens.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              OrbitHomeAction(
                label: settlement == null ? 'Ver acertos' : 'Acertar agora',
                onTap: onTap,
                outlined: true,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const OrbitHomeIcon(
                icon: Icons.swap_horiz_rounded,
                color: OrbitHomeTokens.purple,
                size: 51,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      failed
                          ? 'Resumo indisponível'
                          : settlement == null
                          ? 'Nenhum acerto pendente'
                          : '${data.memberName(settlement.fromMemberId)} ${settlement.isAwaitingConfirmation ? 'informou pagamento a' : 'deve para'} ${data.memberName(settlement.toMemberId)}',
                      style: const TextStyle(
                        color: OrbitHomeTokens.muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    if (settlement != null) ...[
                      const SizedBox(height: 4),
                      _Amount(
                        orbitMoney(settlement.amount, visible: visible),
                        size: 20,
                        color: OrbitHomeTokens.purple,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settlement.isAwaitingConfirmation
                            ? 'Aguardando confirmação do recebimento'
                            : data.settlements.length > 1
                            ? '${data.settlements.length} acertos pendentes'
                            : 'Pagamento e confirmação no detalhe',
                        style: const TextStyle(
                          color: OrbitHomeTokens.muted,
                          fontSize: 10,
                        ),
                      ),
                    ] else if (!failed)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Acompanhem os pagamentos por aqui.',
                          style: TextStyle(
                            color: OrbitHomeTokens.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final OrbitHomeOverview data;
  final bool visible;
  final VoidCallback onTap;
  const _ContributionCard({
    required this.data,
    required this.visible,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final members = data.contribution.members
        .where((m) => data.wallet.memberIds.contains(m.memberId))
        .toList();
    final total = data.contribution.totalSharedExpense;
    final knownPaid = members.fold(0.0, (sum, item) => sum + item.amountPaid);
    final unknown = math.max(0.0, total - knownPaid);
    const colors = [OrbitHomeTokens.purple, OrbitHomeTokens.cyan];
    Widget member(int index) {
      if (index >= members.length) return const SizedBox.shrink();
      final item = members[index];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.memberName(item.memberId),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: OrbitHomeTokens.muted, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            !visible
                ? '••'
                : total <= 0
                ? '—'
                : '${(item.amountPaid / total * 100).round()}%',
            style: TextStyle(
              color: colors[index % 2],
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          _Amount(orbitMoney(item.amountPaid, visible: visible), size: 13),
        ],
      );
    }

    return OrbitHomeSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Nós este mês',
                  style: TextStyle(
                    color: OrbitHomeTokens.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              OrbitHomeAction(
                label: 'Contribuição',
                onTap: onTap,
                outlined: true,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (members.length < 2)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Conecte alguém à carteira para acompanhar a participação de vocês.',
                style: TextStyle(color: OrbitHomeTokens.muted, fontSize: 12),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  Expanded(child: member(0)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: SizedBox(
                      width: constraints.maxWidth < 310 ? 70 : 78,
                      height: constraints.maxWidth < 310 ? 70 : 78,
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: _ContributionPainter(
                            ratios: visible && total > 0
                                ? [
                                    for (final m in members)
                                      (m.amountPaid / total).clamp(0.0, 1.0),
                                    if (unknown > 0) unknown / total,
                                  ]
                                : const [],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.favorite_border_rounded,
                              color: OrbitHomeTokens.purple,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: member(1)),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            total > 0
                ? 'Participação nos pagamentos das despesas confirmadas.'
                : 'Sem despesas confirmadas neste mês.',
            style: const TextStyle(
              color: OrbitHomeTokens.muted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          if (unknown > .01)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                visible
                    ? '${orbitMoney(unknown)} sem pagador identificado.'
                    : 'Há despesas sem pagador identificado.',
                style: const TextStyle(
                  color: OrbitHomeTokens.muted,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContributionPainter extends CustomPainter {
  final List<double> ratios;
  const _ContributionPainter({required this.ratios});
  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      OrbitHomeTokens.purple,
      OrbitHomeTokens.cyan,
      OrbitHomeTokens.muted,
    ];
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      paint..color = OrbitHomeTokens.border,
    );
    var angle = -math.pi / 2;
    for (var i = 0; i < ratios.length; i++) {
      final sweep = ratios[i] * math.pi * 2;
      if (sweep > .02) {
        paint.shader = LinearGradient(
          colors: [colors[i % 3].withValues(alpha: .75), colors[i % 3]],
        ).createShader(rect);
        canvas.drawArc(rect, angle + .01, sweep - .02, false, paint);
      }
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(_ContributionPainter oldDelegate) =>
      oldDelegate.ratios != ratios;
}

class _CommitmentsCard extends StatelessWidget {
  final OrbitHomeOverview data;
  final bool visible;
  final VoidCallback onTap;
  const _CommitmentsCard({
    required this.data,
    required this.visible,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => OrbitHomeSurface(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OrbitHomeSectionTitle(
          title: 'Próximos compromissos',
          action: 'Ver calendário',
          onAction: onTap,
        ),
        if (data.projection == null)
          const _Caption('Resumo indisponível')
        else if (data.commitments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: _Caption('Sem compromissos nos próximos 30 dias.'),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < data.commitments.take(4).length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    _CommitmentTile(
                      entry: data.commitments[i],
                      reference: data.reference,
                      visible: visible,
                      onTap: onTap,
                      index: i,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _CommitmentTile extends StatelessWidget {
  final FinancialCalendarEntry entry;
  final DateTime reference;
  final bool visible;
  final VoidCallback onTap;
  final int index;
  const _CommitmentTile({
    required this.entry,
    required this.reference,
    required this.visible,
    required this.onTap,
    required this.index,
  });
  @override
  Widget build(BuildContext context) {
    const colors = [
      OrbitHomeTokens.purple,
      OrbitHomeTokens.cyan,
      OrbitHomeTokens.amber,
      OrbitHomeTokens.green,
    ];
    final color = colors[index % colors.length];
    final category = entry.transaction?.category.toLowerCase() ?? '';
    final icon = entry.kind == FinancialCalendarEntryKind.creditCardInvoice
        ? Icons.credit_card_rounded
        : category.contains('casa') || category.contains('moradia')
        ? Icons.home_outlined
        : category.contains('mercado') || category.contains('alimenta')
        ? Icons.shopping_cart_outlined
        : Icons.event_outlined;
    return SizedBox(
      width: 100,
      child: OrbitHomeSurface(
        radius: 13,
        padding: const EdgeInsets.all(8),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrbitHomeIcon(icon: icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              entry.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: OrbitHomeTokens.text, fontSize: 10),
            ),
            const SizedBox(height: 4),
            _Amount(orbitMoney(entry.value, visible: visible), size: 11),
            const SizedBox(height: 7),
            Text(
              _dueLabel(entry.date, reference),
              style: TextStyle(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedGoalsCard extends StatelessWidget {
  final OrbitHomeOverview data;
  final bool visible;
  final VoidCallback onTap;
  const _SharedGoalsCard({
    required this.data,
    required this.visible,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => OrbitHomeSurface(
    padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OrbitHomeSectionTitle(
          title: 'Nossas metas',
          action: 'Ver todas',
          onAction: onTap,
        ),
        if (data.errors.containsKey(OrbitHomeSection.goals))
          const _Caption('Resumo indisponível')
        else if (data.goals.isEmpty)
          InkWell(
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: _Caption('Qual será a próxima conquista de vocês?'),
            ),
          )
        else
          for (final goal in data.goals.take(2))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _GoalRow(
                goal: goal,
                visible: visible,
                onTap: onTap,
                reference: data.reference,
              ),
            ),
      ],
    ),
  );
}

class _GoalRow extends StatelessWidget {
  final SavingsGoal goal;
  final DateTime reference;
  final bool visible;
  final VoidCallback onTap;
  const _GoalRow({
    required this.goal,
    required this.visible,
    required this.onTap,
    required this.reference,
  });
  @override
  Widget build(BuildContext context) {
    final deadline = goal.deadline;
    final pastDeadline =
        deadline != null &&
        DateTime(
          deadline.year,
          deadline.month,
          deadline.day,
        ).isBefore(DateTime(reference.year, reference.month, reference.day));
    final color = goal.category == SavingsGoalCategory.housing
        ? OrbitHomeTokens.amber
        : OrbitHomeTokens.purple;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            OrbitHomeIcon(icon: goal.category.icon, color: color, size: 45),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: OrbitHomeTokens.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        visible ? '${goal.progressPercentage.round()}%' : '••',
                        style: TextStyle(color: color, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  OrbitHomeProgress(
                    value: visible ? goal.progress : null,
                    colors: [color, color],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${orbitMoney(goal.savedAmount, visible: visible)} de ${orbitMoney(goal.targetAmount, visible: visible)}',
                    style: const TextStyle(
                      color: OrbitHomeTokens.muted,
                      fontSize: 10,
                    ),
                  ),
                  if (deadline != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        pastDeadline
                            ? 'Prazo encerrado'
                            : 'Até ${DateFormat('dd/MM/yy').format(deadline)}',
                        style: TextStyle(
                          color: pastDeadline
                              ? OrbitHomeTokens.amber
                              : OrbitHomeTokens.muted,
                          fontSize: 10,
                        ),
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

class _InsightCard extends StatelessWidget {
  final OrbitHomeOverview data;
  final bool visible;
  final VoidCallback onTap;
  const _InsightCard({
    required this.data,
    required this.visible,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final insight = selectOrbitPriorityInsight(data.insights);
    final color = insight?.severity == FinancialInsightSeverity.warning
        ? OrbitHomeTokens.red
        : OrbitHomeTokens.amber;
    return OrbitHomeSurface(
      onTap: onTap,
      child: Row(
        children: [
          OrbitHomeIcon(
            icon: Icons.lightbulb_outline_rounded,
            color: color,
            size: 45,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              !visible
                  ? 'Mostre os valores para consultar seu insight financeiro.'
                  : insight?.message ??
                        'Seus insights aparecerão aqui conforme os dados financeiros estiverem disponíveis.',
              style: const TextStyle(
                color: OrbitHomeTokens.text,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(width: 7),
          const Icon(
            Icons.chevron_right_rounded,
            color: OrbitHomeTokens.muted,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  final HouseholdTask task;
  final bool busy;
  final VoidCallback onComplete;
  final VoidCallback onOpen;
  const _RoutineRow({
    required this.task,
    required this.busy,
    required this.onComplete,
    required this.onOpen,
  });
  @override
  Widget build(BuildContext context) {
    final at = task.isCompleted ? task.completedAt : task.dueAt;
    final title = task.title.toLowerCase();
    final icon = title.contains('roupa')
        ? Icons.local_laundry_service_outlined
        : title.contains('lixo')
        ? Icons.delete_outline_rounded
        : title.contains('louça') || title.contains('cozinha')
        ? Icons.kitchen_outlined
        : Icons.task_alt_outlined;
    return OrbitHomeSurface(
      radius: 13,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Semantics(
            label: task.isCompleted
                ? '${task.title} concluída'
                : 'Concluir ${task.title}',
            checked: task.isCompleted,
            child: IconButton(
              onPressed: task.isCompleted || busy ? null : onComplete,
              tooltip: task.isCompleted ? 'Concluída' : 'Concluir tarefa',
              icon: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: OrbitHomeTokens.green,
                      ),
                    )
                  : Icon(
                      task.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: task.isCompleted
                          ? OrbitHomeTokens.green
                          : OrbitHomeTokens.muted,
                      size: 27,
                    ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: OrbitHomeTokens.text,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${task.isCompleted ? 'Concluída' : 'Hoje'}${at == null ? '' : ' • ${DateFormat('HH:mm').format(at)}'}',
                      style: const TextStyle(
                        color: OrbitHomeTokens.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(icon, color: OrbitHomeTokens.cyan, size: 23),
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  final String text;
  const _Caption(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: OrbitHomeTokens.muted,
      fontSize: 12,
      height: 1.35,
    ),
  );
}

class _Amount extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  const _Amount(this.text, {this.size = 20, this.color = OrbitHomeTokens.text});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w600,
          letterSpacing: -.35,
          height: 1.15,
        ),
      ),
    ),
  );
}

String _dueLabel(DateTime date, DateTime reference) {
  final days = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(reference.year, reference.month, reference.day)).inDays;
  return days == 0
      ? 'Hoje'
      : days == 1
      ? 'Amanhã'
      : days < 0
      ? 'Vencido'
      : 'Em $days dias';
}
