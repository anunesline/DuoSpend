import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../financial_intelligence/domain/models/financial_insight.dart';
import '../../../financial_intelligence/presentation/controllers/insights_controller.dart';
import '../../data/models/wallet_model.dart';

FinancialInsight? selectOrbitPriorityInsight(List<FinancialInsight> insights) {
  if (insights.isEmpty) return null;

  const severityWeight = {
    FinancialInsightSeverity.warning: 3,
    FinancialInsightSeverity.attention: 2,
    FinancialInsightSeverity.info: 1,
  };

  final candidates = insights
      .where((insight) => insight.type != FinancialInsightType.insufficientData)
      .toList();
  if (candidates.isEmpty) return insights.first;

  candidates.sort((a, b) {
    final severity = (severityWeight[b.severity] ?? 0)
        .compareTo(severityWeight[a.severity] ?? 0);
    if (severity != 0) return severity;

    const typeWeight = {
      FinancialInsightType.cashFlowRisk: 9,
      FinancialInsightType.projectedBalance: 8,
      FinancialInsightType.cardInvoice: 7,
      FinancialInsightType.budget: 6,
      FinancialInsightType.goal: 5,
      FinancialInsightType.spendingTrend: 4,
      FinancialInsightType.recurring: 3,
      FinancialInsightType.purchaseImpact: 2,
      FinancialInsightType.insufficientData: 1,
    };
    return (typeWeight[b.type] ?? 0).compareTo(typeWeight[a.type] ?? 0);
  });

  return candidates.first;
}

class OrbitInsightCard extends StatefulWidget {
  final WalletModel wallet;
  final VoidCallback onTap;

  const OrbitInsightCard({
    super.key,
    required this.wallet,
    required this.onTap,
  });

  @override
  State<OrbitInsightCard> createState() => _OrbitInsightCardState();
}

class _OrbitInsightCardState extends State<OrbitInsightCard> {
  late InsightsController _controller;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  @override
  void didUpdateWidget(covariant OrbitInsightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallet.id != widget.wallet.id) {
      _controller.dispose();
      _createController();
    }
  }

  void _createController() {
    _controller = InsightsController(wallet: widget.wallet)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const _OrbitLoadingCard();
        }

        if (_controller.errorMessage != null) {
          return const SizedBox.shrink();
        }

        final insight = selectOrbitPriorityInsight(_controller.insights);
        if (insight == null) return const SizedBox.shrink();

        return _OrbitInsightContent(insight: insight, onTap: widget.onTap);
      },
    );
  }
}

class _OrbitInsightContent extends StatelessWidget {
  final FinancialInsight insight;
  final VoidCallback onTap;

  const _OrbitInsightContent({required this.insight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = switch (insight.severity) {
      FinancialInsightSeverity.warning => DuoColors.error,
      FinancialInsightSeverity.attention => DuoColors.warning,
      FinancialInsightSeverity.info => DuoColors.primaryLight,
    };

    final amount = insight.amount;
    final formattedAmount = amount == null
        ? null
        : NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(amount);

    return DuoCard(
      borderRadius: 22,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: accent, size: 18),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'Orbit percebeu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: DuoColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: DuoColors.textHint),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                insight.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: DuoColors.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                insight.message,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: DuoColors.textSecondary,
                ),
              ),
              if (formattedAmount != null) ...[
                const SizedBox(height: 10),
                Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitLoadingCard extends StatelessWidget {
  const _OrbitLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const DuoCard(
      borderRadius: 22,
      child: SizedBox(
        height: 72,
        child: Center(
          child: CircularProgressIndicator(
            color: DuoColors.primary,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}
