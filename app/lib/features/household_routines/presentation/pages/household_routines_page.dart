import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../domain/models/household_routine.dart';
import '../../domain/models/household_task.dart';
import '../../domain/services/household_scope_id.dart';
import '../controllers/household_routines_controller.dart';
import 'create_household_routine_page.dart';

class HouseholdRoutinesPage extends StatefulWidget {
  final HouseholdRoutinesController controller;
  final String scopeId;
  final HouseholdTaskScope scope;
  final List<String> memberIds;
  final String currentUserId;
  final bool embedInScaffold;
  final bool showFloatingActions;

  const HouseholdRoutinesPage({
    super.key,
    required this.controller,
    required this.scopeId,
    required this.scope,
    required this.memberIds,
    required this.currentUserId,
    this.embedInScaffold = false,
    this.showFloatingActions = true,
  });

  @override
  State<HouseholdRoutinesPage> createState() => HouseholdRoutinesPageState();
}

class HouseholdRoutinesPageState extends State<HouseholdRoutinesPage> {
  List<String> _memberIds([HouseholdTask? task]) {
    final members = <String>{
      ...HouseholdScopeId.members(widget.scopeId),
      ...widget.memberIds.map((id) => id.trim()).where((id) => id.isNotEmpty),
      widget.currentUserId,
    };
    final assigneeId = task?.assigneeId?.trim();
    if (assigneeId != null && assigneeId.isNotEmpty) members.add(assigneeId);
    return List.unmodifiable(members);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.load(widget.scopeId);
  }

  @override
  void didUpdateWidget(covariant HouseholdRoutinesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scopeId != widget.scopeId) {
      widget.controller.load(widget.scopeId);
    }
  }

  Future<DateTime?> _pickDateTime({DateTime? initialValue}) async {
    final now = DateTime.now();
    final initial = initialValue ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> createTask() => _openTaskEditor();
  Future<void> _createTask() => createTask();
  Future<void> _editTask(HouseholdTask task) => _openTaskEditor(task: task);

  Future<void> _openTaskEditor({HouseholdTask? task}) async {
    final isEditing = task != null;
    final titleController = TextEditingController(text: task?.title ?? '');
    final notesController = TextEditingController(text: task?.notes ?? '');
    final repeatController = TextEditingController(
      text: task?.repeatEveryDays?.toString() ?? '',
    );
    String? assigneeId = task?.assigneeId ?? widget.currentUserId;
    DateTime? dueAt = task?.dueAt;
    final memberIds = _memberIds(task);

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickDueAt() async {
            final picked = await _pickDateTime(initialValue: dueAt);
            if (picked != null && dialogContext.mounted) {
              setDialogState(() => dueAt = picked);
            }
          }

          return Theme(
            data: _orbitFormTheme(context),
            child: AlertDialog(
              backgroundColor: DuoColors.orbitCardSurface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: DuoColors.orbitBorder.withValues(alpha: .62),
                ),
              ),
              title: Text(
                isEditing ? 'Editar tarefa' : 'Nova tarefa',
                style: const TextStyle(
                  color: DuoColors.orbitTextPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: !isEditing,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Tarefa',
                      hintText: 'Ex.: Tirar o lixo',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded),
                    title: Text(
                      dueAt == null
                          ? 'Definir data e horário'
                          : _formatDueAt(dueAt!),
                    ),
                    subtitle: const Text('Opcional'),
                    onTap: pickDueAt,
                    trailing: dueAt == null
                        ? const Icon(Icons.chevron_right_rounded)
                        : IconButton(
                            tooltip: 'Remover horário',
                            onPressed: () => setDialogState(() => dueAt = null),
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: repeatController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Repetir a cada (dias)',
                      hintText: 'Ex.: 7',
                      helperText: 'Opcional',
                    ),
                  ),
                  if (memberIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: memberIds.contains(assigneeId)
                          ? assigneeId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Responsável pela tarefa',
                      ),
                      items: memberIds
                          .map(
                            (memberId) => DropdownMenuItem<String>(
                              value: memberId,
                              child: Text(
                                widget.controller.memberName(
                                  memberId,
                                  currentUserId: widget.currentUserId,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setDialogState(() {
                        assigneeId = value;
                      }),
                    ),
                  ],
                ],
              ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: DuoColors.orbitAccent,
                    foregroundColor: DuoColors.orbitBackground,
                  ),
                  child: Text(isEditing ? 'Salvar' : 'Criar'),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (shouldSave == true) {
      final repeatText = repeatController.text.trim();
      final repeatEveryDays =
          repeatText.isEmpty ? null : int.tryParse(repeatText);
      if (task == null) {
        await widget.controller.createTask(
          scopeId: widget.scopeId,
          scope: widget.scope,
          title: titleController.text,
          notes: notesController.text,
          assigneeId: assigneeId,
          dueAt: dueAt,
          repeatEveryDays: repeatEveryDays,
        );
      } else {
        await widget.controller.updateTask(
          task: task,
          title: titleController.text,
          notes: notesController.text,
          assigneeId: assigneeId,
          dueAt: dueAt,
          repeatEveryDays: repeatEveryDays,
        );
      }
    }

    // showDialog conclui quando o pop é solicitado, antes de a animação da rota
    // terminar. Descartar os controllers imediatamente fazia o TextField ainda
    // montado acessar um controller já disposed ao cancelar a tarefa.
    await Future<void>.delayed(const Duration(milliseconds: 320));
    titleController.dispose();
    notesController.dispose();
    repeatController.dispose();
  }

  Future<void> _remindTask(HouseholdTask task) async {
    final isPartnerTask = task.scope == HouseholdTaskScope.shared &&
        task.assigneeId != null &&
        task.assigneeId != widget.currentUserId;
    DateTime? remindAt;
    if (!isPartnerTask) {
      remindAt = await _pickDateTime(initialValue: task.dueAt);
      if (remindAt == null) return;
    }
    await widget.controller.remindTask(
      task: task,
      currentUserId: widget.currentUserId,
      remindAt: remindAt,
    );
  }

  Future<void> createRoutine() => _openRoutineEditor();
  Future<void> _createRoutine() => createRoutine();
  Future<void> _editRoutine(HouseholdRoutine routine) =>
      _openRoutineEditor(routine: routine);

  Future<void> _openRoutineEditor({HouseholdRoutine? routine}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateHouseholdRoutinePage(
          controller: widget.controller,
          scopeId: widget.scopeId,
          scope: widget.scope,
          memberIds: _memberIds(),
          currentUserId: widget.currentUserId,
          routine: routine,
        ),
      ),
    );
    if (saved == true) {
      await widget.controller.load(widget.scopeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (widget.embedInScaffold && widget.showFloatingActions) {
      return Stack(
        children: [
          content,
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              heroTag: 'household-task-${widget.scopeId}',
              onPressed: _createTask,
              backgroundColor: DuoColors.orbitAccent,
              foregroundColor: DuoColors.orbitBackground,
              tooltip: 'Nova tarefa',
              child: const Icon(Icons.add_rounded, size: 28),
            ),
          ),
          Positioned(
            right: 28,
            bottom: 94,
            child: FloatingActionButton.small(
              heroTag: 'household-routine-${widget.scopeId}',
              onPressed: _createRoutine,
              tooltip: 'Nova rotina',
              backgroundColor: DuoColors.orbitCardSurface,
              foregroundColor: DuoColors.orbitAccent,
              child: const Icon(Icons.account_tree_rounded),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarefas'),
        actions: [
          IconButton(
            onPressed: _createRoutine,
            tooltip: 'Nova rotina',
            icon: const Icon(Icons.account_tree_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTask,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Nova tarefa'),
      ),
      body: content,
    );
  }

  Widget _buildContent() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: DuoColors.orbitAccent),
          );
        }

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final tomorrowStart = todayStart.add(const Duration(days: 1));
        final weekStart = todayStart.subtract(
          Duration(days: todayStart.weekday - DateTime.monday),
        );
        final pending = widget.controller.pendingTasks;
        final completed = widget.controller.completedTasks;
        final routines = widget.controller.routines;
        final todayTasks = widget.controller.tasks
            .where(
              (task) =>
                  task.dueAt != null &&
                  !task.dueAt!.isBefore(todayStart) &&
                  task.dueAt!.isBefore(tomorrowStart),
            )
            .toList();
        final overdue = pending
            .where(
              (task) =>
                  task.dueAt != null && task.dueAt!.isBefore(todayStart),
            )
            .toList();
        final upcoming = pending
            .where((task) => !todayTasks.contains(task) && !overdue.contains(task))
            .toList();
        final recentCompleted = completed
            .where((task) => !todayTasks.contains(task))
            .take(5)
            .toList();
        final completedThisWeek = completed.where((task) {
          final completedAt = task.completedAt;
          return completedAt != null && !completedAt.isBefore(weekStart);
        }).length;

        _TaskTile taskTile(HouseholdTask task) {
          final isPartnerTask =
              task.scope == HouseholdTaskScope.shared &&
              task.assigneeId != null &&
              task.assigneeId != widget.currentUserId;
          return _TaskTile(
            task: task,
            controller: widget.controller,
            currentUserId: widget.currentUserId,
            onComplete: task.isPending
                ? () => widget.controller.completeTask(task.id)
                : null,
            onEdit: task.isPending ? () => _editTask(task) : null,
            onCancel: task.isPending
                ? () => widget.controller.cancelTask(task.id)
                : null,
            reminderLabel: isPartnerTask
                ? 'Lembrar responsável'
                : 'Agendar lembrete',
            onRemind: task.isPending ? () => _remindTask(task) : null,
          );
        }

        Future<void> openSecondaryContent() => showModalBottomSheet<void>(
              context: context,
              backgroundColor: DuoColors.orbitSurface,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (sheetContext) => SafeArea(
                top: false,
                child: FractionallySizedBox(
                  heightFactor: .72,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      const Text(
                        'Organizar tarefas',
                        style: TextStyle(
                          color: DuoColors.orbitTextPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (upcoming.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const _SectionTitle('Próximas'),
                        const SizedBox(height: 8),
                        _OrbitListCard(
                          children: [
                            for (final task in upcoming) taskTile(task),
                          ],
                        ),
                      ],
                      if (recentCompleted.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const _SectionTitle('Concluídas recentemente'),
                        const SizedBox(height: 8),
                        _OrbitListCard(
                          children: [
                            for (final task in recentCompleted) taskTile(task),
                          ],
                        ),
                      ],
                      if (routines.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const _SectionTitle('Sequências'),
                        const SizedBox(height: 8),
                        _OrbitListCard(
                          children: [
                            for (final routine in routines)
                              _RoutineTile(
                                routine: routine,
                                onEdit: () => _editRoutine(routine),
                                onStart: () =>
                                    widget.controller.startRoutine(
                                  routine: routine,
                                  scope: widget.scope,
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (upcoming.isEmpty &&
                          recentCompleted.isEmpty &&
                          routines.isEmpty) ...[
                        const SizedBox(height: 18),
                        const _CompactEmptyState(
                          icon: Icons.inbox_outlined,
                          message: 'Não há outras tarefas para organizar.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );

        return RefreshIndicator(
          color: DuoColors.orbitAccent,
          onRefresh: () => widget.controller.load(widget.scopeId),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 124),
            children: [
              _RoutineSummary(
                today: todayTasks.where((task) => task.isPending).length,
                overdue: overdue.length,
                completed: completedThisWeek,
              ),
              const SizedBox(height: 14),
              if (widget.controller.errorMessage != null)
                _MessageBanner(
                  message: widget.controller.errorMessage!,
                  color: DuoColors.error,
                ),
              if (widget.controller.successMessage != null)
                _MessageBanner(
                  message: widget.controller.successMessage!,
                  color: DuoColors.success,
                ),
              _SectionTitle(
                'Hoje • ${_shortDate(todayStart)}',
                trailing: 'Ordenar',
                onTrailing: openSecondaryContent,
              ),
              const SizedBox(height: 8),
              if (todayTasks.isNotEmpty) ...[
                _OrbitListCard(
                  children: [for (final task in todayTasks) taskTile(task)],
                ),
              ] else ...[
                const _CompactEmptyState(
                  icon: Icons.wb_sunny_outlined,
                  message: 'Nenhuma tarefa com horário para hoje.',
                ),
              ],
              const SizedBox(height: 22),
              _SectionTitle(
                'Atrasadas (${overdue.length})',
                color: DuoColors.error,
              ),
              const SizedBox(height: 8),
              if (overdue.isNotEmpty)
                _OrbitListCard(
                  children: [for (final task in overdue) taskTile(task)],
                )
              else
                const _CompactEmptyState(
                  icon: Icons.schedule_rounded,
                  message: 'Nenhuma tarefa atrasada.',
                ),
            ],
          ),
        );
      },
    );
  }
}

String _formatDueAt(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} às $hour:$minute';
}

String _shortDate(DateTime date) {
  const weekdays = [
    'segunda',
    'terça',
    'quarta',
    'quinta',
    'sexta',
    'sábado',
    'domingo',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day}/${date.month}';
}

ThemeData _orbitFormTheme(BuildContext context) {
  final theme = Theme.of(context);
  return theme.copyWith(
    colorScheme: theme.colorScheme.copyWith(
      primary: DuoColors.orbitAccent,
      surface: DuoColors.orbitCardSurface,
      onSurface: DuoColors.orbitTextPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: DuoColors.orbitTextSecondary),
      hintStyle: TextStyle(
        color: DuoColors.orbitTextSecondary.withValues(alpha: .72),
      ),
      filled: true,
      fillColor: DuoColors.orbitBackground.withValues(alpha: .52),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: DuoColors.orbitBorder.withValues(alpha: .7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: DuoColors.orbitBorder.withValues(alpha: .7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: DuoColors.orbitAccent),
      ),
    ),
  );
}

class _RoutineSummary extends StatelessWidget {
  final int today;
  final int overdue;
  final int completed;

  const _RoutineSummary({
    required this.today,
    required this.overdue,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Hoje',
            value: '$today',
            caption: 'pendentes',
            color: DuoColors.orbitAccent,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'Atrasadas',
            value: '$overdue',
            caption: 'pendentes',
            color: DuoColors.error,
            icon: Icons.schedule_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'Concluídas',
            value: '$completed',
            caption: 'esta semana',
            color: DuoColors.success,
            icon: Icons.check_circle_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      padding: const EdgeInsets.fromLTRB(13, 13, 10, 11),
      decoration: BoxDecoration(
        color: DuoColors.orbitCardSurface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: DuoColors.orbitBorder.withValues(alpha: .5),
        ),
        boxShadow: DuoColors.orbitCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: DuoColors.orbitTextPrimary,
                        fontSize: 25,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      style: const TextStyle(
                        color: DuoColors.orbitTextSecondary,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: color, size: 21),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrbitListCard extends StatelessWidget {
  final List<Widget> children;

  const _OrbitListCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DuoColors.orbitCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DuoColors.orbitBorder.withValues(alpha: .52),
        ),
        boxShadow: DuoColors.orbitCardShadow,
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(
                height: 1,
                indent: 69,
                color: DuoColors.orbitBorder.withValues(alpha: .55),
              ),
          ],
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final String message;
  final Color color;

  const _MessageBanner({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}

class _CompactEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _CompactEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: DuoColors.orbitCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DuoColors.orbitBorder.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: DuoColors.orbitTextSecondary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: DuoColors.orbitTextSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRoutines extends StatelessWidget {
  final VoidCallback onCreateTask;
  final VoidCallback onCreateRoutine;

  const _EmptyRoutines({
    required this.onCreateTask,
    required this.onCreateRoutine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DuoColors.orbitCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DuoColors.orbitBorder.withValues(alpha: .5),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.checklist_rounded,
            color: DuoColors.orbitAccent,
            size: 30,
          ),
          const SizedBox(height: 8),
          const Text(
            'Sua rotina começa aqui',
            style: TextStyle(
              color: DuoColors.orbitTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Crie uma tarefa ou monte uma sequência encadeada.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DuoColors.orbitTextSecondary,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCreateTask,
                  icon: const Icon(Icons.add_task_rounded, size: 17),
                  label: const Text('Tarefa'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCreateRoutine,
                  icon: const Icon(Icons.account_tree_rounded, size: 17),
                  label: const Text('Sequência'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final Color? color;
  final VoidCallback? onTrailing;

  const _SectionTitle(
    this.title, {
    this.trailing,
    this.color,
    this.onTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: color ?? DuoColors.orbitTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null)
          InkWell(
            onTap: onTrailing,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Text(
                trailing!,
                style: const TextStyle(
                  color: DuoColors.orbitAccent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoutineTile extends StatelessWidget {
  final HouseholdRoutine routine;
  final VoidCallback onEdit;
  final VoidCallback onStart;

  const _RoutineTile({
    required this.routine,
    required this.onEdit,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final repeatLabel = routine.repeatEveryDays == null
        ? null
        : routine.repeatEveryDays == 1
            ? 'repete diariamente'
            : 'repete a cada ${routine.repeatEveryDays} dias';
    final subtitleParts = <String>[
      routine.steps.length == 1 ? '1 etapa' : '${routine.steps.length} etapas',
    ];
    if (repeatLabel != null) subtitleParts.add(repeatLabel);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: DuoColors.orbitAccent.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.account_tree_rounded,
            color: DuoColors.orbitAccent,
            size: 22,
          ),
      ),
      title: Text(routine.name),
      titleTextStyle: const TextStyle(
          color: DuoColors.orbitTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
      ),
      subtitle: Text(
          subtitleParts.join(' • '),
          style: const TextStyle(
            color: DuoColors.orbitTextSecondary,
            fontSize: 10.5,
          ),
      ),
      trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              tooltip: 'Editar rotina',
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onStart,
              tooltip: 'Iniciar rotina',
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final HouseholdTask task;
  final HouseholdRoutinesController controller;
  final String currentUserId;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onRemind;
  final String? reminderLabel;

  const _TaskTile({
    required this.task,
    required this.controller,
    required this.currentUserId,
    this.onComplete,
    this.onEdit,
    this.onCancel,
    this.onRemind,
    this.reminderLabel,
  });

  List<PopupMenuEntry<String>> _menuItems() {
    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem(value: 'complete', child: Text('Concluir')),
    ];
    if (onEdit != null) {
      items.add(
        const PopupMenuItem(value: 'edit', child: Text('Editar tarefa')),
      );
    }
    if (onRemind != null) {
      items.add(
        PopupMenuItem(
          value: 'remind',
          child: Text(reminderLabel ?? 'Agendar lembrete'),
        ),
      );
    }
    items.add(const PopupMenuItem(value: 'cancel', child: Text('Cancelar')));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    final assigneeId = task.assigneeId;
    if (assigneeId != null) {
      subtitleParts.add(
        controller.memberName(
          assigneeId,
          currentUserId: currentUserId,
        ),
      );
    }
    if (task.dueAt != null) subtitleParts.add(_taskTime(task.dueAt!));
    if (task.isRecurring) {
      subtitleParts.add(
        task.repeatEveryDays == 1
            ? 'repete diariamente'
            : 'repete a cada ${task.repeatEveryDays} dias',
      );
    }
    if (task.belongsToRoutine) {
      subtitleParts.add('Etapa ${(task.routineStepIndex ?? 0) + 1}');
    }

    final accent = task.isCompleted
        ? DuoColors.success
        : task.dueAt != null && task.dueAt!.isBefore(DateTime.now())
        ? DuoColors.error
        : DuoColors.orbitAccent;
    return InkWell(
      onTap: task.isPending ? onComplete : null,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 8, 5, 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                task.belongsToRoutine
                    ? Icons.account_tree_rounded
                    : Icons.checklist_rounded,
                color: accent,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: task.isCompleted
                          ? DuoColors.orbitTextSecondary
                          : DuoColors.orbitTextPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (subtitleParts.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitleParts.join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: task.dueAt != null &&
                                task.dueAt!.isBefore(DateTime.now()) &&
                                task.isPending
                            ? DuoColors.error
                            : DuoColors.orbitTextSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (task.scope == HouseholdTaskScope.shared &&
                assigneeId != null) ...[
              const SizedBox(width: 8),
              _MemberAvatar(
                name: controller.memberName(
                  assigneeId,
                  currentUserId: currentUserId,
                ),
                photoUrl: controller.memberPhotoUrl(assigneeId),
              ),
            ],
            if (task.isPending)
              IconButton(
                onPressed: onComplete,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 36,
                ),
                tooltip: 'Concluir',
                icon: Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: accent,
                  size: 21,
                ),
              ),
            if (task.isPending)
              PopupMenuButton<String>(
                color: DuoColors.orbitSurface,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 36,
                ),
                icon: const Icon(Icons.more_vert_rounded, size: 19),
                iconColor: DuoColors.orbitTextSecondary,
                onSelected: (value) {
                  if (value == 'complete') onComplete?.call();
                  if (value == 'edit') onEdit?.call();
                  if (value == 'remind') onRemind?.call();
                  if (value == 'cancel') onCancel?.call();
                },
                itemBuilder: (context) => _menuItems(),
              )
            else
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 8, 7, 8),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: DuoColors.success,
                  size: 21,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const _MemberAvatar({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final normalizedPhoto = photoUrl?.trim();
    return CircleAvatar(
      radius: 14,
      backgroundColor: DuoColors.orbitAccent.withValues(alpha: .18),
      backgroundImage: normalizedPhoto == null || normalizedPhoto.isEmpty
          ? null
          : NetworkImage(normalizedPhoto),
      child: normalizedPhoto == null || normalizedPhoto.isEmpty
          ? Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: const TextStyle(
                color: DuoColors.orbitAccent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

String _taskTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
