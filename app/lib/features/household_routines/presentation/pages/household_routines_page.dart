import 'package:flutter/material.dart';

import '../../domain/models/household_task.dart';
import '../controllers/household_routines_controller.dart';

class HouseholdRoutinesPage extends StatefulWidget {
  final HouseholdRoutinesController controller;
  final String scopeId;
  final HouseholdTaskScope scope;
  final List<String> memberIds;
  final String currentUserId;

  const HouseholdRoutinesPage({
    super.key,
    required this.controller,
    required this.scopeId,
    required this.scope,
    required this.memberIds,
    required this.currentUserId,
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

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                    hintText: 'Ex.: Lavar roupa',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                  ),
                ),
                if (widget.scope == HouseholdTaskScope.shared &&
                    widget.memberIds.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: assigneeId,
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
        ),
      ),
    );

    if (shouldCreate == true) {
      await widget.controller.createTask(
        scopeId: widget.scopeId,
        scope: widget.scope,
        title: titleController.text,
        notes: notesController.text,
        assigneeId: assigneeId,
      );
    }

    titleController.dispose();
    notesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotinas da Casa'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTask,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Nova tarefa'),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final pending = widget.controller.pendingTasks;
          final completed = widget.controller.completedTasks;

          if (pending.isEmpty && completed.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nenhuma tarefa por aqui ainda.\nCrie a primeira rotina da casa.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => widget.controller.load(widget.scopeId),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                if (widget.controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      widget.controller.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                if (pending.isNotEmpty) ...[
                  const _SectionTitle('Pendentes'),
                  const SizedBox(height: 8),
                  ...pending.map(
                    (task) => _TaskTile(
                      task: task,
                      currentUserId: widget.currentUserId,
                      onComplete: () => widget.controller.completeTask(task.id),
                      onCancel: () => widget.controller.cancelTask(task.id),
                    ),
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
      ),
    );
  }
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

class _TaskTile extends StatelessWidget {
  final HouseholdTask task;
  final String currentUserId;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const _TaskTile({
    required this.task,
    required this.currentUserId,
    this.onComplete,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (task.assigneeId != null) {
      subtitleParts.add(task.assigneeId == currentUserId ? 'Responsável: você' : 'Responsável: outro membro');
    }
    if (task.dueAt != null) {
      final date = task.dueAt!;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      subtitleParts.add('${date.day}/${date.month} às $hour:$minute');
    }
    if (task.belongsToRoutine) {
      subtitleParts.add('Etapa ${(task.routineStepIndex ?? 0) + 1}');
    }

    return Card(
      child: ListTile(
        leading: Icon(
          task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        ),
        title: Text(
          task.title,
          style: task.isCompleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' • ')),
        trailing: task.isPending
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'complete') onComplete?.call();
                  if (value == 'cancel') onCancel?.call();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'complete', child: Text('Concluir')),
                  PopupMenuItem(value: 'cancel', child: Text('Cancelar')),
                ],
              )
            : null,
        onTap: task.isPending ? onComplete : null,
      ),
    );
  }
}
