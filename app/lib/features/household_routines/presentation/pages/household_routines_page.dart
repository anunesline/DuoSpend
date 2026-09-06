import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../domain/models/household_routine.dart';
import '../../domain/models/household_task.dart';
import '../../domain/services/household_scope_id.dart';
import '../controllers/household_routines_controller.dart';
import 'create_household_routine_page.dart';
import 'household_task_detail_page.dart';

class HouseholdRoutinesPage extends StatefulWidget {
  final HouseholdRoutinesController controller;
  final String scopeId;
  final HouseholdTaskScope scope;
  final List<String> memberIds;
  final String currentUserId;
  final List<String>? loadScopeIds;
  final String? sharedScopeId;

  const HouseholdRoutinesPage({
    super.key,
    required this.controller,
    required this.scopeId,
    required this.scope,
    required this.memberIds,
    required this.currentUserId,
    this.loadScopeIds,
    this.sharedScopeId,
  });

  @override
  State<HouseholdRoutinesPage> createState() => HouseholdRoutinesPageState();
}

class HouseholdRoutinesPageState extends State<HouseholdRoutinesPage> {
  bool _isOpeningTaskEditor = false;
  late DateTime _selectedDay;

  List<String> _memberIdsForScope({
    required HouseholdTaskScope scope,
    required String scopeId,
    HouseholdTask? task,
  }) {
    final members = <String>{
      widget.currentUserId,
    };
    if (scope == HouseholdTaskScope.shared) {
      members.addAll(HouseholdScopeId.members(scopeId));
      members.addAll(
        widget.memberIds.map((id) => id.trim()).where((id) => id.isNotEmpty),
      );
    }
    final assigneeId = task?.assigneeId?.trim();
    if (assigneeId != null && assigneeId.isNotEmpty) members.add(assigneeId);
    return List.unmodifiable(members);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _loadContent();
  }

  void _changeSelectedDay(int offset) {
    setState(() => _selectedDay = _selectedDay.add(Duration(days: offset)));
  }

  @override
  void didUpdateWidget(covariant HouseholdRoutinesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scopeId != widget.scopeId ||
        !_sameScopes(oldWidget.loadScopeIds, widget.loadScopeIds)) {
      _loadContent();
    }
  }

  Future<void> _loadContent() => widget.loadScopeIds == null
      ? widget.controller.load(widget.scopeId)
      : widget.controller.loadScopes(widget.loadScopeIds!);

  bool _sameScopes(List<String>? first, List<String>? second) {
    if (identical(first, second)) return true;
    if (first == null || second == null || first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
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

  Future<void> createTask() async {
    if (_isOpeningTaskEditor) return;
    _isOpeningTaskEditor = true;
    try {
      await _openTaskEditor();
    } finally {
      _isOpeningTaskEditor = false;
    }
  }
  Future<void> _createTask() => createTask();
  Future<void> _editTask(HouseholdTask task) => _openTaskEditor(task: task);

  Future<void> _openTaskEditor({HouseholdTask? task}) async {
    final isEditing = task != null;
    final titleController = TextEditingController(text: task?.title ?? '');
    final notesController = TextEditingController(text: task?.notes ?? '');
    final repeatController = TextEditingController(
      text: task?.repeatEveryDays?.toString() ?? '',
    );
    var selectedScope = task?.scope ?? widget.scope;
    var selectedScopeId = task?.scopeId ?? widget.scopeId;
    String? assigneeId = task?.assigneeId ?? widget.currentUserId;
    DateTime? dueAt = task?.dueAt;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final memberIds = _memberIdsForScope(
            scope: selectedScope,
            scopeId: selectedScopeId,
            task: task,
          );

          Future<void> pickDueAt() async {
            final picked = await _pickDateTime(initialValue: dueAt);
            if (picked != null && dialogContext.mounted) {
              setDialogState(() => dueAt = picked);
            }
          }

          return Theme(
            data: _orbitFormTheme(context),
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .82,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: DuoColors.orbitCardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: DuoColors.orbitBorder.withValues(alpha: .52),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 8, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: DuoColors.orbitAccent.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.checklist_rounded,
                                color: DuoColors.orbitAccent,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                isEditing ? 'Editar tarefa' : 'Nova tarefa',
                                style: const TextStyle(
                                  color: DuoColors.orbitTextPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Fechar',
                              onPressed: () => Navigator.pop(dialogContext, false),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: DuoColors.orbitBorder.withValues(alpha: .48),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
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
                                maxLines: 2,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  labelText: 'Descrição ou nota',
                                  hintText: 'Opcional',
                                ),
                              ),
                              const SizedBox(height: 16),
                              _EditorSettingsGroup(
                                children: [
                                  if (widget.sharedScopeId != null)
                                    _EditorSettingRow(
                                      icon: Icons.group_outlined,
                                      label: 'Contexto',
                                      child: SegmentedButton<HouseholdTaskScope>(
                                        showSelectedIcon: false,
                                        style: const ButtonStyle(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        segments: const [
                                          ButtonSegment(
                                            value: HouseholdTaskScope.personal,
                                            label: Text('Pessoal'),
                                          ),
                                          ButtonSegment(
                                            value: HouseholdTaskScope.shared,
                                            label: Text('Compartilhada'),
                                          ),
                                        ],
                                        selected: {selectedScope},
                                        onSelectionChanged: (selection) {
                                          final scope = selection.first;
                                          setDialogState(() {
                                            selectedScope = scope;
                                            selectedScopeId = scope ==
                                                    HouseholdTaskScope.shared
                                                ? widget.sharedScopeId!
                                                : widget.scopeId;
                                            assigneeId = widget.currentUserId;
                                          });
                                        },
                                      ),
                                    ),
                                  _EditorSettingRow(
                                    icon: Icons.schedule_rounded,
                                    label: 'Data e horário',
                                    value: dueAt == null
                                        ? 'Não definido'
                                        : _formatDueAt(dueAt!),
                                    onTap: pickDueAt,
                                    trailing: dueAt == null
                                        ? const Icon(Icons.chevron_right_rounded)
                                        : IconButton(
                                            tooltip: 'Remover horário',
                                            onPressed: () =>
                                                setDialogState(() => dueAt = null),
                                            icon: const Icon(Icons.close_rounded),
                                          ),
                                  ),
                                  _EditorSettingRow(
                                    icon: Icons.repeat_rounded,
                                    label: 'Frequência',
                                    child: TextField(
                                      controller: repeatController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      decoration: const InputDecoration(
                                        hintText: 'A cada dias',
                                        isDense: true,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                      ),
                                    ),
                                  ),
                                  if (memberIds.isNotEmpty)
                                    _EditorSettingRow(
                                      icon: Icons.person_outline_rounded,
                                      label: 'Responsável',
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: memberIds.contains(assigneeId)
                                              ? assigneeId
                                              : null,
                                          isDense: true,
                                          dropdownColor: DuoColors.orbitSurface,
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
                                          onChanged: (value) =>
                                              setDialogState(() => assigneeId = value),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext, false),
                              child: const Text('Cancelar'),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () => Navigator.pop(dialogContext, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: DuoColors.orbitAccent,
                                foregroundColor: DuoColors.orbitBackground,
                              ),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: Text(isEditing ? 'Salvar' : 'Criar tarefa'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
          scopeId: selectedScopeId,
          scope: selectedScope,
          title: titleController.text,
          notes: notesController.text,
          assigneeId: assigneeId,
          dueAt: dueAt,
          repeatEveryDays: repeatEveryDays,
        );
      } else {
        await widget.controller.updateTask(
          task: task,
          scopeId: selectedScopeId,
          scope: selectedScope,
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
          memberIds: _memberIdsForScope(
            scope: widget.scope,
            scopeId: widget.scopeId,
          ),
          currentUserId: widget.currentUserId,
          routine: routine,
        ),
      ),
    );
    if (saved == true) {
      await _loadContent();
    }
  }

  @override
  Widget build(BuildContext context) => _buildContent();

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
        final selectedDayStart = DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
        );
        final selectedDayEnd = selectedDayStart.add(const Duration(days: 1));
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
        final selectedDayTasks = widget.controller.tasks
            .where(
              (task) =>
                  task.dueAt != null &&
                  !task.dueAt!.isBefore(selectedDayStart) &&
                  task.dueAt!.isBefore(selectedDayEnd),
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
            onOpen: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => HouseholdTaskDetailPage(
                    task: task,
                    controller: widget.controller,
                    currentUserId: widget.currentUserId,
                    onEdit: task.isPending
                        ? () async {
                            await _editTask(task);
                          }
                        : null,
                    onCancel: task.isPending
                        ? () async {
                            await widget.controller.cancelTask(task.id);
                          }
                        : null,
                    onRemind: isPartnerTask
                        ? () async {
                            await _remindTask(task);
                          }
                        : null,
                  ),
                ),
              );
            },
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
          onRefresh: _loadContent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 120),
            children: [
              _RoutineSummary(
                today: todayTasks.where((task) => task.isPending).length,
                overdue: overdue.length,
                completed: completedThisWeek,
              ),
              const SizedBox(height: 16),
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
              _DaySectionTitle(
                day: selectedDayStart,
                onPrevious: () => _changeSelectedDay(-1),
                onNext: () => _changeSelectedDay(1),
                trailing: 'Ordenar',
                onTrailing: openSecondaryContent,
              ),
              const SizedBox(height: 8),
              if (selectedDayTasks.isNotEmpty) ...[
                _OrbitListCard(
                  children: [
                    for (final task in selectedDayTasks) taskTile(task),
                  ],
                ),
              ] else ...[
                const _CompactEmptyState(
                  icon: Icons.wb_sunny_outlined,
                  message: 'Nenhuma tarefa com horário neste dia.',
                ),
              ],
              const SizedBox(height: 18),
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

class _EditorSettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _EditorSettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: DuoColors.orbitSurface.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DuoColors.orbitBorder.withValues(alpha: .42),
          ),
        ),
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1)
                Divider(
                  height: 1,
                  indent: 46,
                  color: DuoColors.orbitBorder.withValues(alpha: .42),
                ),
            ],
          ],
        ),
      );
}

class _EditorSettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? child;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _EditorSettingRow({
    required this.icon,
    required this.label,
    this.value,
    this.child,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(icon, color: DuoColors.orbitTextSecondary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: DuoColors.orbitTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              Flexible(
                child: child ?? Text(
                  value ?? '',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DuoColors.orbitTextPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ],
            ],
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
      height: 102,
      padding: const EdgeInsets.fromLTRB(12, 13, 10, 12),
      decoration: BoxDecoration(
        color: DuoColors.orbitCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DuoColors.orbitBorder.withValues(alpha: .42),
        ),
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
                        fontSize: 27,
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
              Icon(icon, color: color, size: 22),
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
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: DuoColors.orbitBorder.withValues(alpha: .42),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(
                height: 1,
                indent: 69,
                color: DuoColors.orbitBorder.withValues(alpha: .42),
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
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: DuoColors.orbitCardSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: DuoColors.orbitBorder.withValues(alpha: .38)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DuoColors.orbitTextSecondary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: DuoColors.orbitTextSecondary,
                fontSize: 10.5,
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
              fontSize: 14,
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

class _DaySectionTitle extends StatelessWidget {
  final DateTime day;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final String trailing;
  final VoidCallback onTrailing;

  const _DaySectionTitle({
    required this.day,
    required this.onPrevious,
    required this.onNext,
    required this.trailing,
    required this.onTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = day.difference(today).inDays;
    final prefix = switch (difference) {
      0 => 'Hoje',
      1 => 'Amanhã',
      -1 => 'Ontem',
      _ => null,
    };
    final heading = prefix == null ? _shortDate(day) : '$prefix • ${_shortDate(day)}';
    return Row(
      children: [
        _DayNavigationButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Dia anterior',
          onTap: onPrevious,
        ),
        Expanded(
          child: Text(
            heading,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DuoColors.orbitTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _DayNavigationButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Próximo dia',
          onTap: onNext,
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: onTrailing,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Text(
              trailing,
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

class _DayNavigationButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _DayNavigationButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkResponse(
        onTap: onTap,
        radius: 20,
        child: Tooltip(
          message: tooltip,
          child: Icon(icon, color: DuoColors.orbitTextSecondary, size: 22),
        ),
      );
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
  final VoidCallback onOpen;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onRemind;
  final String? reminderLabel;

  const _TaskTile({
    required this.task,
    required this.controller,
    required this.currentUserId,
    required this.onOpen,
    this.onComplete,
    this.onEdit,
    this.onCancel,
    this.onRemind,
    this.reminderLabel,
  });

  List<PopupMenuEntry<String>> _menuItems() {
    final items = <PopupMenuEntry<String>>[];
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
    if (onCancel != null) {
      items.add(const PopupMenuItem(value: 'cancel', child: Text('Cancelar')));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    final assigneeId = task.assigneeId;
    if (task.scope == HouseholdTaskScope.shared && assigneeId != null) {
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
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 5, 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                task.belongsToRoutine
                    ? Icons.account_tree_rounded
                    : Icons.checklist_rounded,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 11),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (subtitleParts.isNotEmpty) ...[
                    const SizedBox(height: 4),
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
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (task.scope == HouseholdTaskScope.shared &&
                assigneeId != null) ...[
              const SizedBox(width: 7),
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
                  width: 30,
                  height: 40,
                ),
                tooltip: 'Concluir',
                icon: Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
            if (task.isPending)
              PopupMenuButton<String>(
                color: DuoColors.orbitSurface,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 27,
                  height: 40,
                ),
                icon: const Icon(Icons.more_vert_rounded, size: 19),
                iconColor: DuoColors.orbitTextSecondary,
                onSelected: (value) {
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
