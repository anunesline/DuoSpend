import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../home/data/models/wallet_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../domain/models/budget.dart';
import '../../domain/models/budget_consumption.dart';
import '../controllers/budgets_controller.dart';

class BudgetsPage extends StatefulWidget {
  final WalletModel wallet;
  final List<TransactionModel> transactions;
  final String currentUserId;
  const BudgetsPage({super.key, required this.wallet, required this.transactions, required this.currentUserId});
  @override State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  late final BudgetsController controller;
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
  @override void initState() { super.initState(); controller = BudgetsController(wallet: widget.wallet, currentUserId: widget.currentUserId, transactions: widget.transactions)..load(); }
  @override void dispose() { controller.dispose(); super.dispose(); }

  Future<void> _changeMonth() async {
    final chosen = await showDatePicker(context: context, initialDate: selectedMonth, firstDate: DateTime(2020), lastDate: DateTime(2035), helpText: 'Escolha um dia do mês desejado');
    if (chosen != null) setState(() => selectedMonth = DateTime(chosen.year, chosen.month));
  }

  Future<void> _showEditor([Budget? budget]) async {
    if (!controller.canManage) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Somente o proprietário pode alterar orçamentos compartilhados.'))); return; }
    final category = TextEditingController(text: budget?.category ?? '');
    final limit = TextEditingController(text: budget?.limitAmount.toStringAsFixed(2).replaceAll('.', ',') ?? '');
    DateTime month = budget?.month ?? selectedMonth;
    final saved = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text(budget == null ? 'Novo orçamento' : 'Editar orçamento'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: category, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Categoria', hintText: 'Ex.: Mercado')),
        TextField(controller: limit, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Limite mensal', prefixText: 'R\$ ')),
        const SizedBox(height: 12),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('Mês'), subtitle: Text(DateFormat('MMMM yyyy', 'pt_BR').format(month)), trailing: const Icon(Icons.calendar_month_rounded), onTap: () async { final date = await showDatePicker(context: context, initialDate: month, firstDate: DateTime(2020), lastDate: DateTime(2035)); if (date != null) setDialogState(() => month = DateTime(date.year, date.month)); }),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Salvar'))],
    )));
    if (saved != true) return;
    final parsed = double.tryParse(limit.text.trim().replaceAll('.', '').replaceAll(',', '.'));
    final result = budget == null ? await controller.create(category: category.text, month: month, limitAmount: parsed ?? 0) : await controller.update(budget, category: category.text, month: month, limitAmount: parsed ?? 0);
    if (!mounted) return;
    if (result == null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.errorMessage ?? 'Não foi possível salvar o orçamento.')));
  }

  Color _color(BudgetHealth health) => switch (health) { BudgetHealth.healthy => Colors.green, BudgetHealth.attention => Colors.orange, BudgetHealth.exceeded => Colors.red };
  String _label(BudgetHealth health) => switch (health) { BudgetHealth.healthy => 'Saudável', BudgetHealth.attention => 'Atenção', BudgetHealth.exceeded => 'Estourado' };

  @override Widget build(BuildContext context) => AnimatedBuilder(animation: controller, builder: (context, _) {
    final budgets = controller.forMonth(selectedMonth);
    return Scaffold(
      appBar: AppBar(title: const Text('Orçamentos'), actions: [IconButton(onPressed: _changeMonth, icon: const Icon(Icons.calendar_month_rounded), tooltip: 'Escolher mês')]),
      floatingActionButton: controller.canManage ? FloatingActionButton.extended(onPressed: controller.isProcessing ? null : () => _showEditor(), icon: const Icon(Icons.add_rounded), label: const Text('Orçamento')) : null,
      body: controller.isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: controller.load, child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
        Text(DateFormat('MMMM yyyy', 'pt_BR').format(selectedMonth), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4), Text(widget.wallet.isShared ? 'Planejamento compartilhado da carteira' : 'Planejamento da sua carteira'),
        if (!controller.canManage && widget.wallet.isShared) const Padding(padding: EdgeInsets.only(top: 12), child: Text('Você pode acompanhar os limites, mas somente o proprietário da carteira pode alterá-los.')),
        const SizedBox(height: 18),
        if (budgets.isEmpty) const Padding(padding: EdgeInsets.only(top: 48), child: Center(child: Text('Nenhum orçamento neste mês.'))),
        ...budgets.map((item) => _BudgetCard(consumption: item, money: money, color: _color(item.health), label: _label(item.health), canManage: controller.canManage, onEdit: () => _showEditor(item.budget), onPause: () => controller.changeStatus(item.budget, item.budget.isPaused ? BudgetStatus.active : BudgetStatus.paused), onArchive: () => controller.changeStatus(item.budget, BudgetStatus.archived))),
        if (controller.budgets.where((item) => item.isArchived).isNotEmpty) const Padding(padding: EdgeInsets.only(top: 24), child: Text('Arquivados', style: TextStyle(fontWeight: FontWeight.w800))),
        ...controller.budgets.where((item) => item.isArchived).map((item) => ListTile(title: Text(item.category), subtitle: Text('${DateFormat('MM/yyyy').format(item.month)} · Arquivado'), trailing: controller.canManage ? IconButton(icon: const Icon(Icons.unarchive_rounded), onPressed: () => controller.changeStatus(item, BudgetStatus.active)) : null)),
      ])),
    );
  });
}

class _BudgetCard extends StatelessWidget {
  final BudgetConsumption consumption; final NumberFormat money; final Color color; final String label; final bool canManage; final VoidCallback onEdit; final VoidCallback onPause; final VoidCallback onArchive;
  const _BudgetCard({required this.consumption, required this.money, required this.color, required this.label, required this.canManage, required this.onEdit, required this.onPause, required this.onArchive});
  @override Widget build(BuildContext context) {
    final budget = consumption.budget;
    final progress = consumption.percentage.clamp(0.0, 1.0);
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(budget.category, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))), if (budget.isPaused) const Chip(label: Text('Pausado')), if (canManage) PopupMenuButton<String>(onSelected: (action) { if (action == 'edit') onEdit(); if (action == 'pause') onPause(); if (action == 'archive') onArchive(); }, itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'pause', child: Text(budget.isPaused ? 'Retomar' : 'Pausar')), const PopupMenuItem(value: 'archive', child: Text('Arquivar'))])]),
      const SizedBox(height: 14), LinearProgressIndicator(value: progress, color: color, minHeight: 8, borderRadius: BorderRadius.circular(99)), const SizedBox(height: 10),
      Text('${money.format(consumption.spentAmount)} de ${money.format(budget.limitAmount)}'),
      const SizedBox(height: 4), Text(consumption.remainingAmount >= 0 ? '${money.format(consumption.remainingAmount)} restantes · $label' : '${money.format(-consumption.remainingAmount)} acima do limite · $label', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    ])));
  }
}
