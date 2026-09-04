import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../../../core/utils/money_parser.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../domain/models/savings_goal.dart';
import '../../domain/models/savings_goal_movement.dart';
import '../controllers/savings_goals_controller.dart';
import '../widgets/orbit_goals_overview.dart';

enum _GoalListFilter { active, completed, archived }

class SavingsGoalsPage extends StatefulWidget {
  final WalletModel contextWallet;
  final List<WalletModel> individualWallets;
  final String currentUserId;

  const SavingsGoalsPage({
    super.key,
    required this.contextWallet,
    required this.individualWallets,
    required this.currentUserId,
  });

  @override
  State<SavingsGoalsPage> createState() => _SavingsGoalsPageState();
}

class _SavingsGoalsPageState extends State<SavingsGoalsPage> {
  late final SavingsGoalsController controller;
  _GoalListFilter selectedFilter = _GoalListFilter.active;
  String? selectedGoalId;
  final Set<String> _movementRequests = {};

  @override
  void initState() {
    super.initState();
    controller = SavingsGoalsController(
      contextWallet: widget.contextWallet,
      financialWallets: widget.individualWallets,
      currentUserId: widget.currentUserId,
    );
    controller.loadGoals();
  }

  String _money(double value) => NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  ).format(value);

  String _date(DateTime value) => DateFormat('dd/MM/yyyy').format(value);

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<_GoalFormInput?> _goalForm({SavingsGoal? goal}) async {
    final name = TextEditingController(text: goal?.name ?? '');
    final target = TextEditingController(
      text: goal == null
          ? ''
          : goal.targetAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
    DateTime? deadline = goal?.deadline;

    final result = await showModalBottomSheet<_GoalFormInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DuoColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal == null ? 'Novo sonho' : 'Editar sonho',
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Transforme um plano em uma meta que você pode acompanhar.',
                  style: TextStyle(
                    color: DuoColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: name,
                  autofocus: goal == null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nome da meta',
                    hintText: 'Ex.: Viagem dos sonhos',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: target,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Quanto você quer guardar?',
                    prefixText: 'R\$ ',
                    helperText: goal == null
                        ? null
                        : 'Já guardado: ${_money(goal.savedAmount)}',
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final initial =
                        deadline != null && !deadline!.isBefore(today)
                        ? deadline!
                        : today.add(const Duration(days: 30));
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: initial,
                      firstDate: today,
                      lastDate: DateTime(now.year + 30),
                      helpText: 'Prazo da meta',
                    );
                    if (picked != null) {
                      setSheetState(() => deadline = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DuoColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DuoColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: DuoColors.primaryLight,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            deadline == null
                                ? 'Adicionar prazo'
                                : 'Até ${_date(deadline!)}',
                            style: const TextStyle(
                              color: DuoColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (deadline != null)
                          IconButton(
                            onPressed: () =>
                                setSheetState(() => deadline = null),
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final amount = parseMoneyInput(target.text);
                      if (name.text.trim().isEmpty ||
                          amount == null ||
                          amount <= 0) {
                        return;
                      }
                      Navigator.pop(
                        sheetContext,
                        _GoalFormInput(
                          name: name.text.trim(),
                          targetAmount: amount,
                          deadline: deadline,
                        ),
                      );
                    },
                    icon: Icon(
                      goal == null ? Icons.add_rounded : Icons.check_rounded,
                    ),
                    label: Text(
                      goal == null ? 'Criar meta' : 'Salvar alterações',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    name.dispose();
    target.dispose();
    return result;
  }

  Future<void> _createGoal() async {
    final input = await _goalForm();
    if (input == null || !mounted) return;
    final result = await controller.createGoal(
      name: input.name,
      targetAmount: input.targetAmount,
      deadline: input.deadline,
    );
    if (!mounted) return;
    _message(
      result == null
          ? controller.errorMessage ?? 'Não foi possível criar a meta.'
          : 'Meta criada. Um sonho a caminho ✨',
    );
  }

  Future<void> _editGoal(SavingsGoal goal) async {
    final input = await _goalForm(goal: goal);
    if (input == null || !mounted) return;
    final result = await controller.updateGoal(
      goal: goal,
      name: input.name,
      targetAmount: input.targetAmount,
      deadline: input.deadline,
    );
    if (!mounted) return;
    _message(
      result == null
          ? controller.errorMessage ?? 'Não foi possível editar a meta.'
          : 'Meta atualizada.',
    );
  }

  Future<void> _move(SavingsGoal goal, {required bool contribution}) async {
    if (controller.financialWallets.isEmpty) {
      _message('Crie uma carteira individual para movimentar esta meta.');
      return;
    }
    final amount = TextEditingController();
    var wallet = controller.financialWallets.first;
    final input = await showModalBottomSheet<_MovementInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DuoColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contribution ? 'Guardar neste sonho' : 'Retirar deste sonho',
                style: const TextStyle(
                  color: DuoColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                contribution
                    ? 'Faltam ${_money(goal.remainingAmount)} para ${goal.name}.'
                    : 'Você tem ${_money(goal.savedAmount)} reservado.',
                style: const TextStyle(
                  color: DuoColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: wallet.id,
                decoration: InputDecoration(
                  labelText: contribution
                      ? 'Carteira de origem'
                      : 'Carteira de destino',
                ),
                items: controller.financialWallets
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.name} • ${_money(item.balance)}'),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  setSheetState(() {
                    wallet = controller.financialWallets.firstWhere(
                      (item) => item.id == id,
                    );
                  });
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final value = parseMoneyInput(amount.text);
                    if (value == null || value <= 0) return;
                    Navigator.pop(sheetContext, _MovementInput(wallet, value));
                  },
                  child: Text(contribution ? 'Guardar' : 'Retirar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    amount.dispose();
    if (input == null || !mounted) return;
    final result = contribution
        ? await controller.contribute(
            goal: goal,
            sourceWallet: input.wallet,
            amount: input.amount,
          )
        : await controller.withdraw(
            goal: goal,
            destinationWallet: input.wallet,
            amount: input.amount,
          );
    if (!mounted) return;
    if (result != null) {
      await controller.loadMovements(result);
      if (!mounted) return;
    }
    _message(
      result == null
          ? controller.errorMessage ?? 'Não foi possível movimentar a meta.'
          : contribution
          ? 'Valor guardado ✨'
          : 'Valor devolvido à carteira.',
    );
  }

  Future<void> _history(SavingsGoal goal) async {
    final movements = await controller.loadMovements(goal);
    if (!mounted) return;
    if (movements == null) {
      _message(
        controller.errorMessage ?? 'Não foi possível carregar o histórico.',
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DuoColors.surface,
      showDragHandle: true,
      builder: (context) => _HistorySheet(
        goal: goal,
        movements: movements,
        wallets: controller.financialWallets,
        currentUserId: widget.currentUserId,
        money: _money,
      ),
    );
  }

  Future<void> _archive(SavingsGoal goal) async {
    if (goal.savedAmount > 0) {
      _message('Retire todo o valor reservado antes de arquivar.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arquivar meta?'),
        content: Text('“${goal.name}” ficará disponível no histórico.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await controller.archiveGoal(goal);
    if (!mounted) return;
    _message(
      result == null
          ? controller.errorMessage ?? 'Não foi possível arquivar a meta.'
          : 'Meta arquivada.',
    );
  }

  void _selectGoal(String goalId) {
    if (selectedGoalId == goalId) return;
    setState(() => selectedGoalId = goalId);
    SavingsGoal? goal;
    for (final item in controller.goals) {
      if (item.id == goalId) {
        goal = item;
        break;
      }
    }
    if (goal != null) {
      _movementRequests.add(goal.id);
      controller.loadMovements(goal);
    }
  }

  void _ensureMovementsLoaded(SavingsGoal goal) {
    if (_movementRequests.contains(goal.id) ||
        controller.movementsByGoal.containsKey(goal.id) ||
        controller.isLoadingHistoryFor(goal.id)) {
      return;
    }
    _movementRequests.add(goal.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !controller.movementsByGoal.containsKey(goal.id)) {
        controller.loadMovements(goal);
      }
    });
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
      builder: (context, _) {
        final visible = controller.goals.where((goal) {
          return switch (selectedFilter) {
            _GoalListFilter.active => goal.isActive,
            _GoalListFilter.completed => goal.isCompleted && !goal.isArchived,
            _GoalListFilter.archived => goal.isArchived,
          };
        }).toList();

        SavingsGoal? selectedGoal;
        for (final goal in visible) {
          if (goal.id == selectedGoalId) {
            selectedGoal = goal;
            break;
          }
        }
        if (selectedGoal == null && visible.isNotEmpty) {
          selectedGoal = visible.first;
        }
        if (selectedGoal != null) {
          _ensureMovementsLoaded(selectedGoal);
        }

        return Scaffold(
          backgroundColor: DuoColors.background,
          appBar: AppBar(
            backgroundColor: DuoColors.background,
            foregroundColor: DuoColors.textPrimary,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Metas e sonhos',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -.4),
            ),
            actions: [
              IconButton(
                onPressed: controller.isProcessing ? null : _createGoal,
                tooltip: 'Nova meta',
                icon: const Icon(
                  Icons.add_circle_rounded,
                  color: DuoColors.primaryLight,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: DuoColors.primary),
                )
              : RefreshIndicator(
                  color: DuoColors.primary,
                  onRefresh: controller.loadGoals,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 44),
                    children: [
                      _Filters(
                        selected: selectedFilter,
                        active: controller.goals
                            .where((g) => g.isActive)
                            .length,
                        completed: controller.goals
                            .where((g) => g.isCompleted && !g.isArchived)
                            .length,
                        archived: controller.goals
                            .where((g) => g.isArchived)
                            .length,
                        onSelected: (value) => setState(() {
                          selectedFilter = value;
                          selectedGoalId = null;
                        }),
                      ),
                      const SizedBox(height: 16),
                      if (visible.isEmpty)
                        _Empty(filter: selectedFilter, onCreate: _createGoal)
                      else if (selectedGoal case final goal?) ...[
                        OrbitGoalSelector(
                          goals: visible,
                          selectedGoalId: goal.id,
                          onSelected: _selectGoal,
                        ),
                        if (visible.length > 1) const SizedBox(height: 14),
                        OrbitGoalHeroCard(
                          goal: goal,
                          formatMoney: _money,
                          formatDate: _date,
                        ),
                        const SizedBox(height: 12),
                        OrbitGoalInsightCard(
                          goal: goal,
                          movements: controller.movementsByGoal[goal.id],
                          formatMoney: _money,
                          formatDate: _date,
                        ),
                        const SizedBox(height: 14),
                        OrbitGoalMetrics(
                          goal: goal,
                          movements: controller.movementsByGoal[goal.id],
                          formatMoney: _money,
                        ),
                        const SizedBox(height: 24),
                        OrbitGoalProgressSection(
                          goal: goal,
                          movements: controller.movementsByGoal[goal.id],
                          isLoading: controller.isLoadingHistoryFor(goal.id),
                          formatMoney: _money,
                        ),
                        const SizedBox(height: 24),
                        OrbitGoalMovementsSection(
                          movements: controller.movementsByGoal[goal.id],
                          isLoading: controller.isLoadingHistoryFor(goal.id),
                          formatMoney: _money,
                          formatDate: _date,
                          onSeeAll: () => _history(goal),
                        ),
                        const SizedBox(height: 24),
                        OrbitGoalGuidanceSection(
                          goal: goal,
                          movements: controller.movementsByGoal[goal.id],
                        ),
                        const SizedBox(height: 24),
                        OrbitGoalActions(
                          processing: controller.processingGoalId == goal.id,
                          onHistory: () => _history(goal),
                          onEdit:
                              !goal.isArchived &&
                                  goal.createdByUserId == widget.currentUserId
                              ? () => _editGoal(goal)
                              : null,
                          onContribute: goal.isActive
                              ? () => _move(goal, contribution: true)
                              : null,
                          onWithdraw: goal.savedAmount > 0 && !goal.isArchived
                              ? () => _move(goal, contribution: false)
                              : null,
                          onArchive:
                              !goal.isArchived &&
                                  goal.createdByUserId == widget.currentUserId
                              ? () => _archive(goal)
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  final _GoalListFilter selected;
  final int active;
  final int completed;
  final int archived;
  final ValueChanged<_GoalListFilter> onSelected;

  const _Filters({
    required this.selected,
    required this.active,
    required this.completed,
    required this.archived,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(_GoalListFilter value, String label, int count) => ChoiceChip(
      selected: selected == value,
      onSelected: (_) => onSelected(value),
      label: Text('$label ($count)'),
      selectedColor: DuoColors.primary.withValues(alpha: .2),
      side: const BorderSide(color: DuoColors.border),
      labelStyle: TextStyle(
        color: selected == value
            ? DuoColors.primaryLight
            : DuoColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(_GoalListFilter.active, 'Ativas', active),
          const SizedBox(width: 8),
          chip(_GoalListFilter.completed, 'Realizadas', completed),
          const SizedBox(width: 8),
          chip(_GoalListFilter.archived, 'Arquivadas', archived),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final _GoalListFilter filter;
  final VoidCallback onCreate;

  const _Empty({required this.filter, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final title = switch (filter) {
      _GoalListFilter.active => 'Qual é o próximo sonho?',
      _GoalListFilter.completed => 'Nenhum sonho realizado ainda',
      _GoalListFilter.archived => 'Nenhuma meta arquivada',
    };
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: DuoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DuoColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: DuoColors.primaryLight,
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: DuoColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (filter == _GoalListFilter.active) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar primeira meta'),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistorySheet extends StatelessWidget {
  final SavingsGoal goal;
  final List<SavingsGoalMovement> movements;
  final List<WalletModel> wallets;
  final String currentUserId;
  final String Function(double) money;

  const _HistorySheet({
    required this.goal,
    required this.movements,
    required this.wallets,
    required this.currentUserId,
    required this.money,
  });

  String _wallet(String id) {
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet.name;
    }
    return 'Carteira anterior';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Histórico do sonho',
                    style: TextStyle(
                      color: DuoColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal.name,
                    style: const TextStyle(
                      color: DuoColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: DuoColors.divider),
            Expanded(
              child: movements.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma movimentação ainda.',
                        style: TextStyle(color: DuoColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: movements.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final movement = movements[index];
                        final contribution = movement.isContribution;
                        final color = contribution
                            ? DuoColors.success
                            : DuoColors.warning;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: DuoColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: DuoColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: .14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  contribution
                                      ? Icons.add_rounded
                                      : Icons.remove_rounded,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contribution ? 'Guardado' : 'Retirado',
                                      style: const TextStyle(
                                        color: DuoColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${DateFormat('dd/MM/yyyy • HH:mm').format(movement.occurredAt)} • ${_wallet(movement.walletId)} • ${movement.createdByUserId == currentUserId ? 'Você' : 'Outro membro'}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: DuoColors.textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${contribution ? '+' : '-'} ${money(movement.amount)}',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalFormInput {
  final String name;
  final double targetAmount;
  final DateTime? deadline;

  const _GoalFormInput({
    required this.name,
    required this.targetAmount,
    required this.deadline,
  });
}

class _MovementInput {
  final WalletModel wallet;
  final double amount;

  const _MovementInput(this.wallet, this.amount);
}
