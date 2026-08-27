import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../../core/utils/money_parser.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../domain/models/savings_goal.dart';
import '../../domain/models/savings_goal_movement.dart';
import '../controllers/savings_goals_controller.dart';

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

  String _formatMoney(double value) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(value);
  }

  String _formatDeadline(DateTime deadline) {
    return DateFormat('dd/MM/yyyy').format(deadline);
  }

  Future<void> _createGoal() async {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    DateTime? deadline;

    final input = await showDialog<_NewGoalInput>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova meta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nome da meta',
                        hintText: 'Ex.: Viagem',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor-alvo',
                        prefixText: 'R\$ ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final pickedDate = await showDatePicker(
                          context: dialogContext,
                          initialDate:
                              deadline ?? now.add(const Duration(days: 30)),
                          firstDate: DateTime(now.year, now.month, now.day),
                          lastDate: DateTime(now.year + 30),
                          helpText: 'Prazo da meta',
                          cancelText: 'Sem prazo',
                          confirmText: 'Selecionar',
                        );

                        if (pickedDate == null) {
                          return;
                        }

                        setDialogState(() {
                          deadline = pickedDate;
                        });
                      },
                      icon: const Icon(Icons.event_rounded),
                      label: Text(
                        deadline == null
                            ? 'Adicionar prazo'
                            : _formatDeadline(deadline!),
                      ),
                    ),
                    if (deadline != null)
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            deadline = null;
                          });
                        },
                        child: const Text('Remover prazo'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final targetAmount = _parseMoney(targetController.text);

                    if (nameController.text.trim().isEmpty ||
                        targetAmount == null ||
                        targetAmount <= 0) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      _NewGoalInput(
                        name: nameController.text.trim(),
                        targetAmount: targetAmount,
                        deadline: deadline,
                      ),
                    );
                  },
                  child: const Text('Criar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    targetController.dispose();

    if (input == null || !mounted) {
      return;
    }

    final goal = await controller.createGoal(
      name: input.name,
      targetAmount: input.targetAmount,
      deadline: input.deadline,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      goal == null
          ? controller.errorMessage ?? 'Não foi possível criar a meta.'
          : 'Meta criada.',
    );
  }

  Future<void> _showMovementDialog({
    required SavingsGoal goal,
    required bool isContribution,
  }) async {
    if (controller.financialWallets.isEmpty) {
      _showMessage('Crie uma carteira individual para movimentar esta meta.');
      return;
    }

    final amountController = TextEditingController();
    var selectedWallet = controller.financialWallets.first;

    final input = await showDialog<_GoalMovementInput>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isContribution ? 'Fazer aporte' : 'Retirar valor'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isContribution
                        ? 'O valor sairá da carteira e ficará reservado.'
                        : 'O valor reservado voltará para a carteira.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedWallet.id,
                    decoration: InputDecoration(
                      labelText: isContribution
                          ? 'Carteira de origem'
                          : 'Carteira de destino',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final wallet in controller.financialWallets)
                        DropdownMenuItem(
                          value: wallet.id,
                          child: Text(
                            '${wallet.name} • '
                            '${_formatMoney(wallet.balance)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (walletId) {
                      if (walletId == null) {
                        return;
                      }

                      setDialogState(() {
                        selectedWallet = controller.financialWallets.firstWhere(
                          (wallet) => wallet.id == walletId,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Valor',
                      prefixText: 'R\$ ',
                      helperText: isContribution
                          ? 'Faltam ${_formatMoney(goal.remainingAmount)}'
                          : 'Reservado: ${_formatMoney(goal.savedAmount)}',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = _parseMoney(amountController.text);

                    if (amount == null || amount <= 0) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      _GoalMovementInput(
                        wallet: selectedWallet,
                        amount: amount,
                      ),
                    );
                  },
                  child: Text(isContribution ? 'Aportar' : 'Retirar'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();

    if (input == null || !mounted) {
      return;
    }

    final updatedGoal = isContribution
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

    if (!mounted) {
      return;
    }

    _showMessage(
      updatedGoal == null
          ? controller.errorMessage ?? 'Não foi possível movimentar a meta.'
          : isContribution
          ? 'Aporte realizado.'
          : 'Valor devolvido à carteira.',
    );
  }

  Future<void> _editGoal(SavingsGoal goal) async {
    final nameController = TextEditingController(text: goal.name);
    final targetController = TextEditingController(
      text: goal.targetAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
    DateTime? deadline = goal.deadline;

    final input = await showDialog<_EditGoalInput>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar meta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nome da meta',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Valor-alvo',
                        prefixText: 'R\$ ',
                        helperText:
                            'Reservado: ${_formatMoney(goal.savedAmount)}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final currentDeadline = deadline;
                        final initialDate =
                            currentDeadline != null &&
                                !currentDeadline.isBefore(today)
                            ? currentDeadline
                            : today;
                        final pickedDate = await showDatePicker(
                          context: dialogContext,
                          initialDate: initialDate,
                          firstDate: today,
                          lastDate: DateTime(now.year + 30),
                          helpText: 'Prazo da meta',
                          cancelText: 'Cancelar',
                          confirmText: 'Selecionar',
                        );

                        if (pickedDate != null) {
                          setDialogState(() {
                            deadline = pickedDate;
                          });
                        }
                      },
                      icon: const Icon(Icons.event_rounded),
                      label: Text(
                        deadline == null
                            ? 'Adicionar prazo'
                            : _formatDeadline(deadline!),
                      ),
                    ),
                    if (deadline != null)
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            deadline = null;
                          });
                        },
                        child: const Text('Remover prazo'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final targetAmount = _parseMoney(targetController.text);

                    if (nameController.text.trim().isEmpty ||
                        targetAmount == null ||
                        targetAmount <= 0) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      _EditGoalInput(
                        name: nameController.text.trim(),
                        targetAmount: targetAmount,
                        deadline: deadline,
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    targetController.dispose();

    if (input == null || !mounted) {
      return;
    }

    final updatedGoal = await controller.updateGoal(
      goal: goal,
      name: input.name,
      targetAmount: input.targetAmount,
      deadline: input.deadline,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      updatedGoal == null
          ? controller.errorMessage ?? 'Não foi possível editar a meta.'
          : 'Meta atualizada.',
    );
  }

  Future<void> _showMovementHistory(SavingsGoal goal) async {
    final movements = await controller.loadMovements(goal);

    if (!mounted) {
      return;
    }

    if (movements == null) {
      _showMessage(
        controller.errorMessage ??
            'Não foi possível carregar o histórico da meta.',
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DuoColors.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return _GoalHistorySheet(
          goal: goal,
          movements: movements,
          currentUserId: widget.currentUserId,
          wallets: controller.financialWallets,
          formatMoney: _formatMoney,
        );
      },
    );
  }

  Future<void> _archiveGoal(SavingsGoal goal) async {
    if (goal.savedAmount > 0) {
      _showMessage('Retire todo o valor reservado antes de arquivar.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Arquivar meta?'),
          content: Text(
            '“${goal.name}” sairá dos totais e ficará no histórico.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Arquivar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final archivedGoal = await controller.archiveGoal(goal);

    if (!mounted) {
      return;
    }

    _showMessage(
      archivedGoal == null
          ? controller.errorMessage ?? 'Não foi possível arquivar a meta.'
          : 'Meta arquivada.',
    );
  }

  double? _parseMoney(String value) {
    return parseMoneyInput(value);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
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
        final visibleGoals = controller.goals.where((goal) {
          switch (selectedFilter) {
            case _GoalListFilter.active:
              return goal.isActive;
            case _GoalListFilter.completed:
              return goal.isCompleted && !goal.isArchived;
            case _GoalListFilter.archived:
              return goal.isArchived;
          }
        }).toList();

        return Scaffold(
          backgroundColor: DuoColors.background,
          appBar: AppBar(
            backgroundColor: DuoColors.background,
            foregroundColor: DuoColors.textPrimary,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Metas e sonhos',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            centerTitle: false,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: controller.isProcessing ? null : _createGoal,
            backgroundColor: DuoColors.primary,
            foregroundColor: DuoColors.textPrimary,
            child: const Icon(Icons.add_rounded),
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
                    children: [
                      _GoalsHeader(
                        wallet: widget.contextWallet,
                        totalSaved: controller.totalSaved,
                        totalTarget: controller.totalTarget,
                        activeGoalCount: controller.activeGoalCount,
                        formatMoney: _formatMoney,
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Suas metas',
                        style: TextStyle(
                          color: DuoColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GoalFilters(
                        selected: selectedFilter,
                        activeCount: controller.goals
                            .where((goal) => goal.isActive)
                            .length,
                        completedCount: controller.goals
                            .where(
                              (goal) => goal.isCompleted && !goal.isArchived,
                            )
                            .length,
                        archivedCount: controller.goals
                            .where((goal) => goal.isArchived)
                            .length,
                        onSelected: (filter) {
                          setState(() {
                            selectedFilter = filter;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      if (visibleGoals.isEmpty)
                        _EmptyGoals(filter: selectedFilter)
                      else
                        for (final goal in visibleGoals) ...[
                          _GoalCard(
                            goal: goal,
                            formattedSaved: _formatMoney(goal.savedAmount),
                            formattedTarget: _formatMoney(goal.targetAmount),
                            formattedRemaining: _formatMoney(
                              goal.remainingAmount,
                            ),
                            formattedDeadline: goal.deadline == null
                                ? null
                                : _formatDeadline(goal.deadline!),
                            isProcessing:
                                controller.processingGoalId == goal.id,
                            onHistory: () => _showMovementHistory(goal),
                            onEdit:
                                !goal.isArchived &&
                                    goal.createdByUserId == widget.currentUserId
                                ? () => _editGoal(goal)
                                : null,
                            onContribute: goal.isActive
                                ? () => _showMovementDialog(
                                    goal: goal,
                                    isContribution: true,
                                  )
                                : null,
                            onWithdraw: goal.savedAmount > 0 && !goal.isArchived
                                ? () => _showMovementDialog(
                                    goal: goal,
                                    isContribution: false,
                                  )
                                : null,
                            onArchive:
                                !goal.isArchived &&
                                    goal.createdByUserId == widget.currentUserId
                                ? () => _archiveGoal(goal)
                                : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _GoalsHeader extends StatelessWidget {
  final WalletModel wallet;
  final double totalSaved;
  final double totalTarget;
  final int activeGoalCount;
  final String Function(double) formatMoney;

  const _GoalsHeader({
    required this.wallet,
    required this.totalSaved,
    required this.totalTarget,
    required this.activeGoalCount,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            wallet.name,
            style: const TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Total reservado',
            style: TextStyle(color: DuoColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            formatMoney(totalSaved),
            style: const TextStyle(
              color: DuoColors.primaryLight,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$activeGoalCount metas ativas • '
            'Alvo total: ${formatMoney(totalTarget)}',
            style: const TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final String formattedSaved;
  final String formattedTarget;
  final String formattedRemaining;
  final String? formattedDeadline;
  final bool isProcessing;
  final VoidCallback onHistory;
  final VoidCallback? onEdit;
  final VoidCallback? onContribute;
  final VoidCallback? onWithdraw;
  final VoidCallback? onArchive;

  const _GoalCard({
    required this.goal,
    required this.formattedSaved,
    required this.formattedTarget,
    required this.formattedRemaining,
    required this.formattedDeadline,
    required this.isProcessing,
    required this.onHistory,
    required this.onEdit,
    required this.onContribute,
    required this.onWithdraw,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = goal.isArchived
        ? DuoColors.textHint
        : goal.isCompleted
        ? DuoColors.success
        : DuoColors.primaryLight;

    return DuoCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  goal.isArchived
                      ? Icons.inventory_2_outlined
                      : goal.isCompleted
                      ? Icons.flag_rounded
                      : Icons.savings_rounded,
                  color: statusColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${goal.progressPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                onPressed: isProcessing ? null : onHistory,
                tooltip: 'Histórico da meta',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.history_rounded,
                  color: DuoColors.textHint,
                  size: 20,
                ),
              ),
              if (onEdit != null || onArchive != null)
                PopupMenuButton<String>(
                  enabled: !isProcessing,
                  tooltip: 'Opções da meta',
                  color: DuoColors.surface,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: DuoColors.textHint,
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'archive') {
                      onArchive?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    if (onArchive != null)
                      const PopupMenuItem(
                        value: 'archive',
                        child: Text('Arquivar'),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 9,
              backgroundColor: DuoColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$formattedSaved de $formattedTarget',
            style: const TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            goal.isArchived
                ? 'Meta arquivada'
                : goal.isCompleted
                ? 'Meta concluída!'
                : 'Faltam $formattedRemaining',
            style: TextStyle(
              color: goal.isArchived
                  ? DuoColors.textHint
                  : goal.isCompleted
                  ? DuoColors.success
                  : DuoColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (formattedDeadline != null) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.event_rounded,
                  color: DuoColors.textHint,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  'Prazo: $formattedDeadline',
                  style: const TextStyle(
                    color: DuoColors.textHint,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
          if (onContribute != null || onWithdraw != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (onWithdraw != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isProcessing ? null : onWithdraw,
                      child: const Text('Retirar'),
                    ),
                  ),
                if (onWithdraw != null && onContribute != null)
                  const SizedBox(width: 8),
                if (onContribute != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isProcessing ? null : onContribute,
                      icon: isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Aportar'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalFilters extends StatelessWidget {
  final _GoalListFilter selected;
  final int activeCount;
  final int completedCount;
  final int archivedCount;
  final ValueChanged<_GoalListFilter> onSelected;

  const _GoalFilters({
    required this.selected,
    required this.activeCount,
    required this.completedCount,
    required this.archivedCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(_GoalListFilter filter, String label, int count) {
      return ChoiceChip(
        selected: selected == filter,
        onSelected: (_) => onSelected(filter),
        label: Text('$label ($count)'),
        selectedColor: DuoColors.primary.withValues(alpha: .22),
        side: const BorderSide(color: DuoColors.border),
        labelStyle: TextStyle(
          color: selected == filter
              ? DuoColors.primaryLight
              : DuoColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(_GoalListFilter.active, 'Ativas', activeCount),
          const SizedBox(width: 8),
          chip(_GoalListFilter.completed, 'Concluídas', completedCount),
          const SizedBox(width: 8),
          chip(_GoalListFilter.archived, 'Arquivadas', archivedCount),
        ],
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  final _GoalListFilter filter;

  const _EmptyGoals({required this.filter});

  @override
  Widget build(BuildContext context) {
    final title = switch (filter) {
      _GoalListFilter.active => 'Nenhuma meta ativa',
      _GoalListFilter.completed => 'Nenhuma meta concluída',
      _GoalListFilter.archived => 'Nenhuma meta arquivada',
    };
    final description = switch (filter) {
      _GoalListFilter.active =>
        'Crie uma meta e reserve dinheiro das suas carteiras.',
      _GoalListFilter.completed => 'As metas finalizadas aparecerão aqui.',
      _GoalListFilter.archived =>
        'As metas arquivadas continuarão disponíveis aqui.',
    };

    return DuoCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(
            Icons.savings_outlined,
            color: DuoColors.textHint,
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalHistorySheet extends StatelessWidget {
  final SavingsGoal goal;
  final List<SavingsGoalMovement> movements;
  final String currentUserId;
  final List<WalletModel> wallets;
  final String Function(double) formatMoney;

  const _GoalHistorySheet({
    required this.goal,
    required this.movements,
    required this.currentUserId,
    required this.wallets,
    required this.formatMoney,
  });

  String _walletName(String walletId) {
    for (final wallet in wallets) {
      if (wallet.id == walletId) {
        return wallet.name;
      }
    }

    return 'Carteira anterior';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy • HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Histórico da meta',
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
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          'Esta meta ainda não possui aportes ou retiradas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: DuoColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: movements.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final movement = movements[index];
                        final isContribution = movement.isContribution;
                        final color = isContribution
                            ? DuoColors.success
                            : DuoColors.warning;
                        final memberLabel =
                            movement.createdByUserId == currentUserId
                            ? 'Você'
                            : 'Outro membro';

                        return DuoCard(
                          borderRadius: 16,
                          padding: const EdgeInsets.all(14),
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
                                  isContribution
                                      ? Icons.add_rounded
                                      : Icons.remove_rounded,
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isContribution ? 'Aporte' : 'Retirada',
                                      style: const TextStyle(
                                        color: DuoColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_formatDate(movement.occurredAt)}'
                                      ' • ${_walletName(movement.walletId)}'
                                      ' • $memberLabel',
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
                              const SizedBox(width: 8),
                              Text(
                                '${isContribution ? '+' : '-'} '
                                '${formatMoney(movement.amount)}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
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

class _EditGoalInput {
  final String name;
  final double targetAmount;
  final DateTime? deadline;

  const _EditGoalInput({
    required this.name,
    required this.targetAmount,
    required this.deadline,
  });
}

class _NewGoalInput {
  final String name;
  final double targetAmount;
  final DateTime? deadline;

  const _NewGoalInput({
    required this.name,
    required this.targetAmount,
    required this.deadline,
  });
}

class _GoalMovementInput {
  final WalletModel wallet;
  final double amount;

  const _GoalMovementInput({required this.wallet, required this.amount});
}
