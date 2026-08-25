import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../domain/models/financial_insight.dart';
import '../controllers/insights_controller.dart';

class InsightsPage extends StatefulWidget {
  final WalletModel wallet;

  const InsightsPage({super.key, required this.wallet});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  late final InsightsController controller;

  @override
  void initState() {
    super.initState();
    controller = InsightsController(wallet: widget.wallet)..load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Scaffold(
        backgroundColor: DuoColors.background,
        appBar: AppBar(title: const Text('Insights financeiros')),
        body: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : controller.errorMessage != null
                ? Center(child: Text(controller.errorMessage!))
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: controller.insights.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => _InsightCard(
                      insight: controller.insights[index],
                    ),
                  ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final FinancialInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = switch (insight.severity) {
      FinancialInsightSeverity.warning => DuoColors.error,
      FinancialInsightSeverity.attention => DuoColors.warning,
      FinancialInsightSeverity.info => DuoColors.primaryLight,
    };
    final amount = insight.amount;
    return DuoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.auto_awesome_rounded, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(insight.title, style: const TextStyle(fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 10),
          Text(insight.message),
          if (amount != null) ...[
            const SizedBox(height: 10),
            Text(NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(amount), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 10),
          Text('Cálculo: ${insight.source}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}
