import 'package:flutter/material.dart';

import '../../domain/models/household_routine.dart';
import '../../domain/models/household_task.dart';
import '../controllers/household_routines_controller.dart';

class CreateHouseholdRoutinePage extends StatefulWidget {
  final HouseholdRoutinesController controller;
  final String scopeId;
  final HouseholdTaskScope scope;
  final List<String> memberIds;
  final String currentUserId;
  final HouseholdRoutine? routine;

  const CreateHouseholdRoutinePage({
    super.key,
    required this.controller,
    required this.scopeId,
    required this.scope,
    required this.memberIds,
    required this.currentUserId,
    this.routine,
  });

  @override
  State<CreateHouseholdRoutinePage> createState() =>
      _CreateHouseholdRoutinePageState();
}

class _CreateHouseholdRoutinePageState
    extends State<CreateHouseholdRoutinePage> {
  final _nameController = TextEditingController();
  final _repeatDaysController = TextEditingController(text: '7');
  final List<_RoutineStepDraft> _steps = [];
  bool _saving = false;
  bool _recurring = false;

  bool get _isEditing => widget.routine != null;

  @override
  void initState() {
    super.initState();
    final routine = widget.routine;
    if (routine == null) {
      _steps.add(_RoutineStepDraft(assigneeId: widget.currentUserId));
      return;
    }

    _nameController.text = routine.name;
    _recurring = routine.isRecurring;
    if (routine.repeatEveryDays != null) {
      _repeatDaysController.text = routine.repeatEveryDays.toString();
    }
    _steps.addAll(
      routine.steps.map(_RoutineStepDraft.fromStep),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _repeatDaysController.dispose();
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  void _addStep() => setState(
        () => _steps.add(
          _RoutineStepDraft(assigneeId: widget.currentUserId),
        ),
      );

  void _removeStep(int index) {
    if (_steps.length == 1) return;
    final removed = _steps.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    if (_saving) return;
    final steps = <HouseholdRoutineStep>[];
    for (var i = 0; i < _steps.length; i++) {
      final draft = _steps[i];
      final title = draft.titleController.text.trim();
      if (title.isEmpty) {
        _showMessage('Preencha o nome de todas as etapas.');
        return;
      }
      final delayHours = i == 0
          ? 0
          : int.tryParse(draft.delayHoursController.text.trim()) ?? -1;
      if (delayHours < 0) {
        _showMessage('Informe um intervalo válido em horas.');
        return;
      }
      steps.add(
        HouseholdRoutineStep(
          title: title,
          notes: draft.notesController.text.trim().isEmpty
              ? null
              : draft.notesController.text.trim(),
          delayAfterPrevious: Duration(hours: delayHours),
          assigneeId: draft.assigneeId,
        ),
      );
    }

    final repeatDays =
        _recurring ? int.tryParse(_repeatDaysController.text.trim()) : null;
    if (_recurring && (repeatDays == null || repeatDays <= 0)) {
      _showMessage('Informe a recorrência em dias.');
      return;
    }

    setState(() => _saving = true);
    final existing = widget.routine;
    final saved = existing == null
        ? await widget.controller.createRoutine(
            scopeId: widget.scopeId,
            scope: widget.scope,
            name: _nameController.text,
            steps: steps,
            startsAt: DateTime.now(),
            repeatEveryDays: repeatDays,
          )
        : await widget.controller.updateRoutine(
            routine: existing,
            name: _nameController.text,
            steps: steps,
            repeatEveryDays: repeatDays,
          );

    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      _showMessage(
        widget.controller.errorMessage ??
            (_isEditing
                ? 'Não foi possível atualizar a rotina.'
                : 'Não foi possível criar a rotina.'),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar rotina' : 'Nova rotina'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome da rotina',
              hintText: 'Ex.: Roupas',
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Repetir esta rotina'),
            subtitle: const Text(
              'Ao concluir a última etapa, agenda um novo ciclo.',
            ),
            value: _recurring,
            onChanged: (value) => setState(() => _recurring = value),
          ),
          if (_recurring) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _repeatDaysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Repetir depois de',
                suffixText: 'dias',
                helperText: 'Ex.: 7 para uma rotina semanal',
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Etapas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _isEditing
                ? 'As alterações valem para as próximas etapas geradas. Etapas já concluídas não são recriadas.'
                : 'A próxima etapa só é criada quando a anterior for concluída. O intervalo começa a contar a partir da conclusão real.',
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _steps.length; i++) ...[
            _StepEditor(
              index: i,
              draft: _steps[i],
              isFirst: i == 0,
              canRemove: _steps.length > 1,
              isShared: widget.scope == HouseholdTaskScope.shared,
              memberIds: widget.memberIds,
              currentUserId: widget.currentUserId,
              onAssigneeChanged: (value) =>
                  setState(() => _steps[i].assigneeId = value),
              onRemove: () => _removeStep(i),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: _addStep,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar etapa'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _isEditing
                      ? Icons.save_rounded
                      : Icons.playlist_add_check_rounded,
                ),
          label: Text(
            _saving
                ? 'Salvando...'
                : _isEditing
                    ? 'Salvar alterações'
                    : 'Criar e iniciar rotina',
          ),
        ),
      ),
    );
  }
}

class _StepEditor extends StatelessWidget {
  final int index;
  final _RoutineStepDraft draft;
  final bool isFirst;
  final bool canRemove;
  final bool isShared;
  final List<String> memberIds;
  final String currentUserId;
  final ValueChanged<String?> onAssigneeChanged;
  final VoidCallback onRemove;

  const _StepEditor({
    required this.index,
    required this.draft,
    required this.isFirst,
    required this.canRemove,
    required this.isShared,
    required this.memberIds,
    required this.currentUserId,
    required this.onAssigneeChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Etapa ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (canRemove)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Remover etapa',
                  ),
              ],
            ),
            TextField(
              controller: draft.titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Tarefa',
                hintText: isFirst ? 'Ex.: Lavar roupa' : 'Ex.: Estender roupa',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: draft.notesController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
              ),
            ),
            if (!isFirst) ...[
              const SizedBox(height: 12),
              TextField(
                controller: draft.delayHoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Abrir depois de quantas horas?',
                  suffixText: 'h',
                ),
              ),
            ],
            if (isShared && memberIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: memberIds.contains(draft.assigneeId)
                    ? draft.assigneeId
                    : null,
                decoration: const InputDecoration(labelText: 'Responsável'),
                items: memberIds
                    .map(
                      (memberId) => DropdownMenuItem(
                        value: memberId,
                        child: Text(
                          memberId == currentUserId ? 'Eu' : 'Outro membro',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onAssigneeChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoutineStepDraft {
  final TextEditingController titleController;
  final TextEditingController notesController;
  final TextEditingController delayHoursController;
  String? assigneeId;

  _RoutineStepDraft({this.assigneeId})
      : titleController = TextEditingController(),
        notesController = TextEditingController(),
        delayHoursController = TextEditingController(text: '0');

  _RoutineStepDraft.fromStep(HouseholdRoutineStep step)
      : titleController = TextEditingController(text: step.title),
        notesController = TextEditingController(text: step.notes ?? ''),
        delayHoursController =
            TextEditingController(text: step.delayAfterPrevious.inHours.toString()),
        assigneeId = step.assigneeId;

  void dispose() {
    titleController.dispose();
    notesController.dispose();
    delayHoursController.dispose();
  }
}
