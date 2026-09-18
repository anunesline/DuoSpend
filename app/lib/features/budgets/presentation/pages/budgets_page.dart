import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../domain/models/budget.dart';
import '../../domain/models/budget_consumption.dart';
import '../../domain/services/budget_consumption_service.dart';
import '../widgets/budget_visuals.dart';
import '../controllers/budgets_controller.dart';

enum BudgetDestination { home, finance, create, routines, ai }

const _budgetCategories = [
  'Alimentação',
  'Transporte',
  'Moradia',
  'Compras',
  'Lazer',
  'Saúde',
  'Pets',
  'Educação',
  'Contas e serviços',
  'Investimentos',
  'Viagem',
  'Presentes',
  'Dívidas e parcelas',
  'Outros',
];
const _createCategory = '__create_category__';

String _normalizeBudgetCategory(String value) {
  var normalized = value.trim().toLowerCase();
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
    normalized = normalized.replaceAll(entry.key, entry.value);
  }
  return normalized;
}

class _BudgetEditorValues {
  final String category;
  final DateTime month;
  final double limitAmount;

  const _BudgetEditorValues({
    required this.category,
    required this.month,
    required this.limitAmount,
  });
}

class _BudgetEditorDialog extends StatefulWidget {
  final Budget? budget;
  final DateTime selectedMonth;
  final Future<String?> Function(String selected) selectCategory;

  const _BudgetEditorDialog({
    required this.budget,
    required this.selectedMonth,
    required this.selectCategory,
  });

  @override
  State<_BudgetEditorDialog> createState() => _BudgetEditorDialogState();
}

class _BudgetEditorDialogState extends State<_BudgetEditorDialog> {
  late final TextEditingController category;
  late final TextEditingController limit;
  late DateTime month;
  late bool customCategory;

  @override
  void initState() {
    super.initState();
    category = TextEditingController(text: widget.budget?.category ?? '');
    limit = TextEditingController(
      text:
          widget.budget?.limitAmount.toStringAsFixed(2).replaceAll('.', ',') ??
          '',
    );
    month = widget.budget?.month ?? widget.selectedMonth;
    customCategory = !_budgetCategories.any(
      (item) =>
          _normalizeBudgetCategory(item) ==
          _normalizeBudgetCategory(category.text),
    );
  }

  @override
  void dispose() {
    category.dispose();
    limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: DuoColors.surface,
    title: Text(widget.budget == null ? 'Novo orçamento' : 'Editar orçamento'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Categoria',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: budgetCategoryColor(
                category.text,
              ).withValues(alpha: .14),
              child: Icon(
                budgetCategoryIcon(category.text),
                color: budgetCategoryColor(category.text),
                size: 20,
              ),
            ),
            title: Text(
              category.text.isEmpty ? 'Selecionar categoria' : category.text,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final result = await widget.selectCategory(category.text);
              if (!mounted || result == null) return;
              setState(() {
                if (result == _createCategory) {
                  customCategory = true;
                  if (_budgetCategories.any(
                    (item) =>
                        _normalizeBudgetCategory(item) ==
                        _normalizeBudgetCategory(category.text),
                  )) {
                    category.clear();
                  }
                } else {
                  customCategory = false;
                  category.text = result;
                }
              });
            },
          ),
          if (customCategory)
            TextField(
              controller: category,
              autofocus: widget.budget == null,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome da categoria',
                hintText: 'Ex.: Academia',
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: limit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Limite mensal',
              prefixText: 'R\$ ',
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mês'),
            subtitle: Text(DateFormat('MMMM yyyy', 'pt_BR').format(month)),
            trailing: const Icon(Icons.calendar_month_rounded),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: month,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (date != null && mounted) {
                setState(() => month = DateTime(date.year, date.month));
              }
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _BudgetEditorValues(
            category: category.text,
            month: month,
            limitAmount:
                double.tryParse(
                  limit.text.trim().replaceAll('.', '').replaceAll(',', '.'),
                ) ??
                0,
          ),
        ),
        child: const Text('Salvar'),
      ),
    ],
  );
}

class BudgetsPage extends StatefulWidget {
  final WalletModel wallet;
  final List<TransactionModel> transactions;
  final String currentUserId;
  final Widget Function(ValueChanged<BudgetDestination>) navigationBuilder;

  const BudgetsPage({
    super.key,
    required this.wallet,
    required this.transactions,
    required this.currentUserId,
    required this.navigationBuilder,
  });

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  late final BudgetsController controller;
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  int selectedTab = 0;
  int sortOrder = 0;

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

  Future<String?> _selectBudgetCategory(String selected) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: DuoColors.orbitSurface,
        builder: (context) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .78,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(
                    'Selecionar categoria',
                    style: TextStyle(
                      color: DuoColors.orbitTextPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final item in _budgetCategories)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      backgroundColor: budgetCategoryColor(
                        item,
                      ).withValues(alpha: .14),
                      child: Icon(
                        budgetCategoryIcon(item),
                        color: budgetCategoryColor(item),
                      ),
                    ),
                    title: Text(item),
                    trailing:
                        _normalizeBudgetCategory(selected) ==
                            _normalizeBudgetCategory(item)
                        ? const Icon(
                            Icons.check_rounded,
                            color: DuoColors.orbitAccent,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, item),
                  ),
                const Divider(height: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: CircleAvatar(
                    backgroundColor: DuoColors.orbitAccent.withValues(
                      alpha: .14,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: DuoColors.orbitAccent,
                    ),
                  ),
                  title: const Text('+ Criar categoria'),
                  onTap: () => Navigator.pop(context, _createCategory),
                ),
              ],
            ),
          ),
        ),
      );

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
    final values = await showDialog<_BudgetEditorValues>(
      context: context,
      builder: (_) => _BudgetEditorDialog(
        budget: budget,
        selectedMonth: selectedMonth,
        selectCategory: _selectBudgetCategory,
      ),
    );
    if (values == null || !mounted) return;
    final result = budget == null
        ? await controller.create(
            category: values.category,
            month: values.month,
            limitAmount: values.limitAmount,
          )
        : await controller.update(
            budget,
            category: values.category,
            month: values.month,
            limitAmount: values.limitAmount,
          );
    if (!mounted || result != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          controller.errorMessage ?? 'Não foi possível salvar o orçamento.',
        ),
      ),
    );
  }

  void _navigate(BudgetDestination destination) =>
      Navigator.pop(context, destination);

  List<BudgetConsumption> _sorted(List<BudgetConsumption> items) {
    final result = [...items];
    result.sort(
      (a, b) => switch (sortOrder) {
        1 => b.percentage.compareTo(a.percentage),
        2 => a.budget.category.compareTo(b.budget.category),
        _ => b.spentAmount.compareTo(a.spentAmount),
      },
    );
    return result;
  }

  Future<void> _status(Budget budget, BudgetStatus status) async {
    final result = await controller.changeStatus(budget, status);
    if (!mounted || result != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          controller.errorMessage ?? 'Não foi possível alterar o orçamento.',
        ),
      ),
    );
  }

  Future<void> _sheet(String title, List<Widget> children) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: DuoColors.orbitSurface,
        builder: (context) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .82,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      color: DuoColors.orbitTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      );

  void _help() => _sheet('Entenda seus orçamentos', [
    const Text(
      'Orçamentos ajudam a manter o controle dos seus gastos e alcançar seus objetivos financeiros.',
    ),
    const SizedBox(height: 20),
    const Text('Como funciona?', style: TextStyle(fontSize: 18)),
    const ListTile(
      leading: Icon(Icons.pie_chart_outline, color: DuoColors.orbitAccent),
      title: Text('Defina limites mensais por categoria'),
      subtitle: Text('Use o mesmo nome de categoria das suas transações.'),
    ),
    const ListTile(
      leading: Icon(Icons.query_stats, color: DuoColors.orbitAccent),
      title: Text('Acompanhe seus gastos'),
      subtitle: Text(
        'Puxe a tela para atualizar os dados da carteira. A partir de 80% do limite, a categoria recebe um sinal de atenção.',
      ),
    ),
    const ListTile(
      leading: Icon(Icons.tune, color: DuoColors.orbitAccent),
      title: Text('Ajuste sempre que precisar'),
      subtitle: Text(
        'Toque na categoria para consultar, editar, pausar ou arquivar.',
      ),
    ),
    const Divider(),
    const Text('Dicas para você', style: TextStyle(fontSize: 18)),
    const ListTile(
      leading: Icon(Icons.calendar_month_outlined),
      title: Text('Revise semanalmente'),
      subtitle: Text('Uma revisão rápida por semana já faz toda a diferença.'),
    ),
    const ListTile(
      leading: Icon(Icons.track_changes),
      title: Text('Seja realista'),
      subtitle: Text('Defina limites que façam sentido para sua realidade.'),
    ),
    const ListTile(
      leading: Icon(Icons.star_outline),
      title: Text('Priorize o que importa'),
      subtitle: Text(
        'Coloque mais foco nas categorias que realmente importam para você.',
      ),
    ),
    const Divider(),
    if (controller.canManage) ...[
      ListTile(
        leading: const Icon(Icons.add),
        title: const Text('Novo orçamento'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pop(context);
          _showEditor();
        },
      ),
      ListTile(
        leading: const Icon(Icons.tune),
        title: const Text('Ajustar orçamentos'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pop(context);
          setState(() => selectedTab = 2);
        },
      ),
    ],
    ListTile(
      leading: const Icon(Icons.auto_awesome, color: DuoColors.orbitAccent),
      title: const Text('Precisa de ajuda?'),
      subtitle: const Text('Abrir insights da IA'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
        _navigate(BudgetDestination.ai);
      },
    ),
  ]);

  void _details(BudgetConsumption item) {
    final budget = item.budget;
    _sheet(budget.category, [
      Text(DateFormat('MMMM yyyy', 'pt_BR').format(budget.month)),
      const SizedBox(height: 16),
      BudgetCategoryRow(item: item, money: money),
      const SizedBox(height: 16),
      Text(
        budget.isPaused
            ? 'Pausado · as despesas da categoria continuam visíveis no acompanhamento.'
            : 'O consumo considera despesas desta categoria, carteira e mês, exceto acertos e transações sem efeito no saldo compartilhado.',
      ),
      if (controller.canManage) ...[
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Editar orçamento'),
          onTap: () {
            Navigator.pop(context);
            _showEditor(budget);
          },
        ),
        ListTile(
          leading: Icon(budget.isPaused ? Icons.play_arrow : Icons.pause),
          title: Text(
            budget.isPaused ? 'Retomar orçamento' : 'Pausar orçamento',
          ),
          onTap: () {
            Navigator.pop(context);
            _status(
              budget,
              budget.isPaused ? BudgetStatus.active : BudgetStatus.paused,
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: const Text('Arquivar orçamento'),
          onTap: () {
            Navigator.pop(context);
            _status(budget, BudgetStatus.archived);
          },
        ),
      ],
    ]);
  }

  // Reuse the domain service at each day boundary, including all its exclusions.
  List<double> _evolution(List<BudgetConsumption> items) {
    final days = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final now = DateTime.now();
    final current =
        selectedMonth.year == now.year && selectedMonth.month == now.month;
    final count = current ? now.day : days;
    const service = BudgetConsumptionService();
    return List.generate(count, (index) {
      final cutoff = DateTime(
        selectedMonth.year,
        selectedMonth.month,
        index + 2,
      );
      final transactions = controller.transactions.where(
        (transaction) => transaction.date.isBefore(cutoff),
      );
      return items.fold<double>(
        0,
        (sum, item) =>
            sum +
            service
                .calculate(budget: item.budget, transactions: transactions)
                .spentAmount,
      );
    });
  }

  void _evolutionDetails(List<double> values) => _sheet('Evolução do mês', [
    Text(DateFormat('MMMM yyyy', 'pt_BR').format(selectedMonth)),
    const SizedBox(height: 12),
    const Text(
      'Despesas acumuladas das categorias orçadas. Não há distribuição diária do limite cadastrada.',
    ),
    const SizedBox(height: 16),
    SizedBox(
      height: 160,
      width: double.infinity,
      child: BudgetEvolutionChart(values: values, month: selectedMonth),
    ),
    const SizedBox(height: 16),
    for (var i = 0; i < values.length; i++)
      ListTile(
        dense: true,
        title: Text(
          DateFormat(
            'dd/MM',
          ).format(DateTime(selectedMonth.year, selectedMonth.month, i + 1)),
        ),
        trailing: Text(money.format(values[i])),
      ),
  ]);

  Widget _empty() => BudgetPanel(
    child: Column(
      children: [
        const Icon(
          Icons.pie_chart_outline,
          size: 36,
          color: DuoColors.orbitAccent,
        ),
        const SizedBox(height: 12),
        const Text(
          'Nenhum orçamento neste mês',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Defina limites por categoria para acompanhar seus gastos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: DuoColors.orbitTextSecondary),
        ),
        if (controller.canManage)
          TextButton.icon(
            onPressed: controller.isProcessing ? null : () => _showEditor(),
            icon: const Icon(Icons.add),
            label: const Text('Criar orçamento'),
          ),
      ],
    ),
  );

  Widget _categories(List<BudgetConsumption> items) => Column(
    children: [
      Row(
        children: [
          const Expanded(
            child: Text('Por categoria', style: TextStyle(fontSize: 18)),
          ),
          PopupMenuButton<int>(
            tooltip: 'Ordenar categorias',
            initialValue: sortOrder,
            onSelected: (value) => setState(() => sortOrder = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 0, child: Text('Maior gasto')),
              PopupMenuItem(value: 1, child: Text('Mais perto do limite')),
              PopupMenuItem(value: 2, child: Text('Nome')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ['Maior gasto', 'Utilização', 'Nome'][sortOrder],
                    style: const TextStyle(
                      color: DuoColors.orbitAccent,
                      fontSize: 12,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: DuoColors.orbitAccent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      if (items.isEmpty)
        _empty()
      else
        BudgetPanel(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                BudgetCategoryRow(
                  item: items[i],
                  money: money,
                  onTap: controller.isProcessing
                      ? null
                      : () => _details(items[i]),
                ),
                if (i < items.length - 1)
                  const Divider(height: 1, color: DuoColors.orbitBorder),
              ],
            ],
          ),
        ),
    ],
  );

  Widget _insight(List<BudgetConsumption> items) {
    final exceeded = items.where((item) => item.remainingAmount < 0).toList();
    if (exceeded.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: BudgetPanel(
        accent: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: DuoColors.orbitAccent,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Você está acima do planejado em ${exceeded.length} ${exceeded.length == 1 ? 'orçamento' : 'orçamentos'}',
                  ),
                  const SizedBox(height: 5),
                  Text(
                    exceeded
                        .map(
                          (item) =>
                              '${item.budget.category} (+${money.format(-item.remainingAmount)})',
                        )
                        .join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: DuoColors.orbitTextSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _sheet('Acima do planejado', [
                      for (final item in exceeded)
                        BudgetCategoryRow(item: item, money: money),
                    ]),
                    child: const Text('Ver insights'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lowerCards(List<BudgetConsumption> items) {
    final closest = [...items]
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final evolution = _evolution(items);
    final near = BudgetPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categorias mais próximas do limite',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Cadastre um orçamento para acompanhar.',
              style: TextStyle(color: DuoColors.orbitTextSecondary),
            ),
          for (final item in closest.take(3))
            InkWell(
              onTap: () => _details(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      budgetCategoryIcon(item.budget.category),
                      color: budgetCategoryColor(item.budget.category),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.budget.category,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${item.percentageDisplay.round()}%',
                      style: TextStyle(
                        color: item.remainingAmount < 0
                            ? DuoColors.error
                            : budgetCategoryColor(item.budget.category),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          TextButton(
            onPressed: () => setState(() {
              selectedTab = 1;
              sortOrder = 1;
            }),
            child: const Text('Ver todas'),
          ),
        ],
      ),
    );
    final chart = BudgetPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Evolução do mês', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          const Text(
            '● Gasto real acumulado',
            style: TextStyle(color: DuoColors.orbitAccent, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            money.format(evolution.isEmpty ? 0 : evolution.last),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 108,
            width: double.infinity,
            child: BudgetEvolutionChart(
              values: evolution,
              month: selectedMonth,
            ),
          ),
          TextButton(
            onPressed: () => _evolutionDetails(evolution),
            child: const Text(
              'Ver evolução completa',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 360 ||
              MediaQuery.textScalerOf(context).scale(14) > 18) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [near, const SizedBox(height: 12), chart],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: near),
              const SizedBox(width: 10),
              Expanded(child: chart),
            ],
          );
        },
      ),
    );
  }

  Widget _planned(List<BudgetConsumption> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Limites planejados para o mês',
        style: TextStyle(fontSize: 18),
      ),
      const SizedBox(height: 8),
      const Text(
        'Orçamentos cadastrados, incluindo os pausados.',
        style: TextStyle(color: DuoColors.orbitTextSecondary),
      ),
      const SizedBox(height: 16),
      if (items.isEmpty) _empty(),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: BudgetPanel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                budgetCategoryIcon(item.budget.category),
                color: budgetCategoryColor(item.budget.category),
              ),
              title: Text(item.budget.category),
              subtitle: Text(
                '${money.format(item.budget.limitAmount)} · ${item.budget.isPaused ? 'Pausado' : 'Ativo'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.isProcessing ? null : () => _details(item),
            ),
          ),
        ),
    ],
  );

  Widget _history(List<BudgetConsumption> items) {
    final archived = controller.budgets
        .where(
          (item) =>
              item.isArchived &&
              item.month.year == selectedMonth.year &&
              item.month.month == selectedMonth.month,
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Histórico do mês selecionado',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          'Troque o mês no topo para consultar outros períodos. Os valores refletem os registros atuais, sem histórico de versões dos limites.',
          style: TextStyle(color: DuoColors.orbitTextSecondary),
        ),
        const SizedBox(height: 12),
        _categories(items),
        const SizedBox(height: 20),
        const Text('Arquivados', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 12),
        if (archived.isEmpty)
          const Text(
            'Nenhum orçamento arquivado neste mês.',
            style: TextStyle(color: DuoColors.orbitTextSecondary),
          ),
        for (final budget in archived)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BudgetPanel(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(budget.category),
                subtitle: Text(
                  '${money.format(budget.limitAmount)} · Arquivado',
                ),
                trailing: controller.canManage
                    ? IconButton(
                        tooltip: 'Restaurar orçamento',
                        icon: const Icon(
                          Icons.unarchive_outlined,
                          color: DuoColors.orbitAccent,
                        ),
                        onPressed: controller.isProcessing
                            ? null
                            : () => _status(budget, BudgetStatus.active),
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final items = _sorted(controller.forMonth(selectedMonth));
      return Scaffold(
        backgroundColor: DuoColors.orbitBackground,
        bottomNavigationBar: widget.navigationBuilder(_navigate),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    const Expanded(
                      child: Text(
                        'Orçamentos',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w500,
                          color: DuoColors.orbitTextPrimary,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _changeMonth,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        foregroundColor: DuoColors.orbitAccent,
                        side: BorderSide(
                          color: DuoColors.orbitAccent.withValues(alpha: .3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 17),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMM yy', 'pt_BR')
                                .format(selectedMonth)
                                .replaceAll('.', '')
                                .toUpperCase(),
                            style: const TextStyle(fontSize: 11),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Novo orçamento',
                      style: IconButton.styleFrom(
                        backgroundColor: DuoColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          controller.canManage && !controller.isProcessing
                          ? () => _showEditor()
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BudgetPanel(
                  padding: const EdgeInsets.all(4),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const labels = [
                        'Visão geral',
                        'Categorias',
                        'Planejados',
                        'Histórico',
                      ];
                      final scroll =
                          constraints.maxWidth < 325 ||
                          MediaQuery.textScalerOf(context).scale(12) > 16;
                      final tabs = [
                        for (var i = 0; i < labels.length; i++)
                          Semantics(
                            selected: selectedTab == i,
                            button: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(9),
                              onTap: () => setState(() => selectedTab = i),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedTab == i
                                      ? DuoColors.primary.withValues(alpha: .22)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: selectedTab == i
                                        ? DuoColors.orbitAccent.withValues(
                                            alpha: .4,
                                          )
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  labels[i],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                      ];
                      return scroll
                          ? SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(children: tabs),
                            )
                          : Row(
                              children: [
                                for (final tab in tabs) Expanded(child: tab),
                              ],
                            );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (controller.isProcessing)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: controller.load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                            if (controller.errorMessage != null)
                              BudgetPanel(
                                child: Column(
                                  children: [
                                    Text(controller.errorMessage!),
                                    TextButton(
                                      onPressed: controller.load,
                                      child: const Text('Tentar novamente'),
                                    ),
                                  ],
                                ),
                              ),
                            if (!controller.canManage)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'Somente o proprietário pode alterar os orçamentos compartilhados.',
                                  style: TextStyle(
                                    color: DuoColors.orbitTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (selectedTab == 0) ...[
                              BudgetMonthSummary(
                                items: items,
                                month: selectedMonth,
                                money: money,
                                onHelp: _help,
                              ),
                              const SizedBox(height: 8),
                              _categories(items),
                              _insight(items),
                              _lowerCards(items),
                            ],
                            if (selectedTab == 1) _categories(items),
                            if (selectedTab == 2) _planned(items),
                            if (selectedTab == 3) _history(items),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _help,
                              icon: const Icon(Icons.help_outline, size: 18),
                              label: const Text('Entenda seus orçamentos'),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
