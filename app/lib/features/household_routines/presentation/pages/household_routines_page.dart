import 'package:flutter/material.dart';

import '../../domain/models/household_routine.dart';
import '../../domain/models/household_task.dart';
import '../controllers/household_routines_controller.dart';
import 'create_household_routine_page.dart';

class HouseholdRoutinesPage extends StatefulWidget {
  final HouseholdRoutinesController controller;
  final String scopeId;
  final HouseholdTaskScope scope;
  final List<String> memberIds;
  final String currentUserId;
  final bool embedInScaffold;

  const HouseholdRoutinesPage({
    super.key,
    required this.controller,
    required this.scopeId,
    required this.scope,
    required this.memberIds,
    required this.currentUserId,
    this.embedInScaffold = false,
  });

  @override
  State<HouseholdRoutinesPage> createState() => _HouseholdRoutinesPageState();
}

class _HouseholdRoutinesPageState extends State<HouseholdRoutinesPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.load(widget.scopeId);
  }

  Future<void> _createTask() async {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    String? assigneeId = widget.currentUserId;
    DateTime? dueAt;

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickDueAt() async {
            final now = DateTime.now();
            final initial = dueAt ?? now.add(const Duration(hours: 1));
            final date = await showDatePicker(
              context: dialogContext,
              initialDate: initial,
              firstDate: DateTime(now.year, now.month, now.day),
              lastDate: DateTime(now.year + 5),
            );
            if (date == null || !dialogContext.mounted) return;
            final time = await showTimePicker(
              context: dialogContext,
              initialTime: TimeOfDay.fromDateTime(initial),
            );
            if (time == null) return;
            setDialogState(() {
              dueAt = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
            });
          }

          return AlertDialog(
            title: const Text('Nova tarefa'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
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
                      dueAt == null ? 'Definir data e horário' : _formatDueAt(dueAt!),
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
                  if (widget.scope == HouseholdTaskScope.shared &&
                      widget.memberIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: widget.memberIds.contains(assigneeId)
                          ? assigneeId
                          : null,
                      decoration: const InputDecoration(labelText: 'Responsável'),
                      items: widget.memberIds
                          .map(
                            (memberId) => DropdownMenuItem(
                              value: memberId,
                              child: Text(
                                memberId == widget.currentUserId
                                    ? 'Eu'
                                    : 'Outro membro',
                              ),
                            ),
                          )
                          .toList(),
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
                child: const Text('Criar'),
              ),
            ],
          );
        },
      ),
    );

    if (shouldCreate == true) {
      await widget.controller.createTask(
        scopeId: widget.scopeId,
        scope: widget.scope,
        title: titleController.text,
        notes: notesController.text,
        assigneeId: assigneeId,
        dueAt: dueAt,
      );
    }

    titleController.dispose();
    notesController.dispose();
  }

  Future<void> _createRoutine() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateHouseholdRoutinePage(
          controller: widget.controller,
          scopeId: widget.scopeId,
          scope: widget.scope,
          memberIds: widget.memberIds,
          currentUserId: widget.currentUserId,
        ),
      ),
    );

    if (created == true) {
      await widget.controller.load(widget.scopeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();

    if (widget.embedInScaffold) {
      return Stack(
        children: [
          content,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'household-task-${widget.scopeId}',
              onPressed: _createTask,
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Nova tarefa'),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 82,
            child: FloatingActionButton.small(
              heroTag: 'household-routine-${widget.scopeId}',
              onPressed: _createRoutine,
              tooltip: 'Nova rotina',
              child: const Icon(Icons.account_tree_rounded),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotinas da Casa'),
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
          return const Center(child: CircularProgressIndicator());
        }

        final pending = widget.controller.pendingTasks;
        final completed = widget.controller.completedTasks;
        final routines = widget.controller.routines;

        if (pending.isEmpty && completed.isEmpty && routines.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nenhuma tarefa por aqui ainda.\nCrie uma tarefa ou uma rotina encadeada.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _createRoutine,
                    icon: const Icon(Icons.account_tree_rounded),
                    label: const Text('Criar rotina'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => widget.controller.load(widget.scopeId),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
            children: [
              if (widget.controller.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    widget.controller.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (widget.controller.successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    widget.controller.successMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              if (routines.isNotEmpty) ...[
                const _SectionTitle('Rotinas'),
                const SizedBox(height: 8),
                ...routines.map(
                  (routine) => _RoutineTile(
                    routine: routine,
                    onStart: () => widget.controller.startRoutine(
                      routine: routine,
                      scope: widget.scope,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (pending.isNotEmpty) ...[
                const _SectionTitle('Pendentes'),
                const SizedBox(height: 8),
                ...pending.map(
                  (task) {
                    final isPartnerTask = task.scope == HouseholdTaskScope.shared &&
                        task.assigneeId != null &&
                        task.assigneeId != widget.currentUserId;
                    return _TaskTile(
                      task: task,
                      currentUserId: widget.currentUserId,
                      onComplete: () => widget.controller.completeTask(task.id),
                      onCancel: () => widget.controller.cancelTask(task.id),
                      reminderLabel: isPartnerTask
                          ? 'Lembrar responsável'
                          : 'Criar lembrete',
                      onRemind: () => widget.controller.remindTask(
                        task: task,
                        currentUserId: widget.currentUserId,
                      ),
                    );
                  },
                ),
              ],
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _SectionTitle('Concluídas'),
                const SizedBox(height: 8),
                ...completed.map(
                  (task) => _TaskTile(
                    task: task,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              ],
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _RoutineTile extends StatelessWidget {
  final HouseholdRoutine routine;
  final VoidCallback onStart;

  const _RoutineTile({
    required this.routine,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final repeatLabel = routine.repeatEveryDays == null
        ? null
        : routine.repeatEveryDays == 1
            ? 'repete diariamente'
            : 'repete a cada ${routine.repeatEveryDays} dias';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_tree_rounded),
        title: Text(routine.name),
        subtitle: Text(
          [
            routine.steps.length == 1
                ? '1 etapa'
                : '${routine.steps.length} etapas',
            if (repeatLabel != null) repeatLabel,
          ].join(' • '),
        ),
        trailing: IconButton(
          onPressed: onStart,
          tooltip: 'Iniciar rotina',
          icon: const Icon(Icons.play_arrow_rounded),
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final HouseholdTask task;
  final String currentUserId;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final VoidCallback? onRemind;
  final String? reminderLabel;

  const _TaskTile({
    required this.task,
    required this.currentUserId,
    this.onComplete,
    this.onCancel,
    this.onRemind,
    this.reminderLabel,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (task.assigneeId != null) {
      subtitleParts.add(
        task.assigneeId == currentUserId
            ? 'Responsável: você'
            : 'Responsável: outro membro',
      );
    }
    if (task.dueAt != null) {
      subtitleParts.add(_formatDueAt(task.dueAt!));
    }
    if (task.belongsToRoutine) {
      subtitleParts.add('Etapa ${(task.routineStepIndex ?? 0) + 1}');
    }

    return Card(
      child: ListTile(
        leading: Icon(
          task.isCompleted
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
        ),
        title: Text(
          task.title,
          style: task.isCompleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: subtitleParts.isEmpty
            ? null
            : Text(subtitleParts.join(' • ')),
        trailing: task.isPending
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'complete') onComplete?.call();
                  if (value == 'remind') onRemind?.call();
                  if (value == 'cancel') onCancel?.call();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'complete',
                    child: Text('Concluir'),
                  ),
                  if (onRemind != null)
                    PopupMenuItem(
                      value: 'remind',
                      child: Text(reminderLabel ?? 'Criar lembrete'),
                    ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text('Cancelar'),
                  ),
                ],
              )
            : null,
        onTap: task.isPending ? onComplete : null,
      ),
    );
  }
}
