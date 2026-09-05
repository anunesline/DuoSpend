import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/data/repositories/user_repository.dart';
import '../../domain/models/household_routine.dart';
import '../../domain/models/household_task.dart';
import '../../domain/models/household_list.dart';
import '../../domain/models/household_list_item.dart';
import '../../domain/repositories/household_list_repository.dart';
import '../../domain/repositories/household_routine_repository.dart';
import '../../domain/repositories/household_task_repository.dart';
import '../../domain/services/household_routine_service.dart';
import '../../domain/services/household_task_reminder_service.dart';
import '../../domain/services/household_scope_id.dart';

class HouseholdRoutinesController extends ChangeNotifier {
  final HouseholdTaskRepository taskRepository;
  final HouseholdRoutineRepository routineRepository;
  final HouseholdListRepository listRepository;
  final HouseholdRoutineService routineService;
  final HouseholdTaskReminderService reminderService;
  final Uuid uuid;
  final UserRepository userRepository;

  HouseholdRoutinesController({
    required this.taskRepository,
    required this.routineRepository,
    required this.listRepository,
    required this.routineService,
    required this.reminderService,
    UserRepository? userRepository,
    this.uuid = const Uuid(),
  }) : userRepository = userRepository ?? UserRepository();

  final List<HouseholdTask> _tasks = [];
  final List<HouseholdRoutine> _routines = [];
  final List<HouseholdList> _lists = [];
  final Map<String, List<HouseholdListItem>> _itemsByList = {};
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, UserProfileSummary> _memberProfiles = const {};

  List<HouseholdTask> get tasks => List.unmodifiable(_tasks);
  List<HouseholdRoutine> get routines => List.unmodifiable(_routines);
  List<HouseholdList> get lists => List.unmodifiable(_lists);
  List<HouseholdListItem> itemsForList(String listId) =>
      List.unmodifiable(_itemsByList[listId] ?? const []);
  List<HouseholdTask> get pendingTasks => List.unmodifiable(
        _tasks.where((task) => task.isPending).toList()
          ..sort((a, b) {
            final aDue = a.dueAt;
            final bDue = b.dueAt;
            if (aDue == null && bDue == null) return 0;
            if (aDue == null) return 1;
            if (bDue == null) return -1;
            return aDue.compareTo(bDue);
          }),
      );
  List<HouseholdTask> get completedTasks => List.unmodifiable(
        _tasks.where((task) => task.isCompleted).toList()
          ..sort(
            (a, b) => (b.completedAt ?? b.updatedAt)
                .compareTo(a.completedAt ?? a.updatedAt),
          ),
      );
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  Map<String, UserProfileSummary> get memberProfiles => _memberProfiles;

  String memberName(String userId, {required String currentUserId}) {
    if (userId == currentUserId) return 'Você';
    return _memberProfiles[userId]?.displayName ?? 'Outro membro';
  }

  String? memberPhotoUrl(String userId) => _memberProfiles[userId]?.photoUrl;

  Future<void> load(String scopeId) async {
    _setLoading(true);
    try {
      _clearMessages();
      final results = await Future.wait([
        taskRepository.getTasksByScope(scopeId),
        routineRepository.getRoutinesByScope(scopeId),
      ]);
      _tasks
        ..clear()
        ..addAll(results[0] as List<HouseholdTask>);
      _routines
        ..clear()
        ..addAll(results[1] as List<HouseholdRoutine>);
      _lists
        ..clear();
      _itemsByList.clear();
      try {
        _lists.addAll(await listRepository.getListsByScope(scopeId));
        _itemsByList.addEntries(
          await Future.wait(
            _lists.map(
              (list) async => MapEntry(
                list.id,
                await listRepository.getItemsByList(list.id),
              ),
            ),
          ),
        );
      } catch (_) {
        // List access must not block the approved routines flow if a user is
        // still on older Firestore rules while this feature rolls out.
        _lists.clear();
        _itemsByList.clear();
      }
      try {
        _memberProfiles = await userRepository.getUserProfileSummaries(
          HouseholdScopeId.members(scopeId),
        );
      } catch (_) {
        // Profile decoration must never prevent the routines themselves from
        // loading. The UI keeps a safe member fallback if a profile is absent.
        _memberProfiles = const {};
      }
    } catch (_) {
      _errorMessage = 'Não foi possível carregar as rotinas da casa.';
    } finally {
      _setLoading(false);
    }
  }

  Future<HouseholdList?> createList({
    required String scopeId,
    required String name,
    required HouseholdListType type,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      _setError('Informe o nome da lista.');
      return null;
    }
    final now = DateTime.now();
    final list = HouseholdList(
      id: uuid.v4(),
      scopeId: scopeId,
      name: normalizedName,
      type: type,
      status: HouseholdListStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    try {
      _clearMessages();
      await listRepository.saveList(list);
      _lists.add(list);
      notifyListeners();
      return list;
    } catch (_) {
      _setError('Não foi possível criar a lista.');
      return null;
    }
  }

  Future<HouseholdList?> updateList({
    required HouseholdList list,
    required String name,
    required HouseholdListType type,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      _setError('Informe o nome da lista.');
      return null;
    }
    final updated = list.copyWith(
      name: normalizedName,
      type: type,
      updatedAt: DateTime.now(),
    );
    try {
      _clearMessages();
      await listRepository.saveList(updated);
      _replaceList(updated);
      notifyListeners();
      return updated;
    } catch (_) {
      _setError('Não foi possível atualizar a lista.');
      return null;
    }
  }

  Future<bool> archiveList(HouseholdList list) async {
    final archived = list.copyWith(
      status: HouseholdListStatus.archived,
      updatedAt: DateTime.now(),
    );
    try {
      _clearMessages();
      await listRepository.saveList(archived);
      _lists.removeWhere((item) => item.id == list.id);
      notifyListeners();
      return true;
    } catch (_) {
      _setError('Não foi possível arquivar a lista.');
      return false;
    }
  }

  Future<bool> deleteEmptyList(HouseholdList list) async {
    final items = await listRepository.getItemsByList(list.id);
    if (items.isNotEmpty) {
      _setError('Arquive esta lista para preservar seus itens e histórico.');
      return false;
    }
    try {
      _clearMessages();
      await listRepository.deleteList(list.id);
      _lists.removeWhere((item) => item.id == list.id);
      notifyListeners();
      return true;
    } catch (_) {
      _setError('Não foi possível excluir a lista.');
      return false;
    }
  }

  Future<void> loadListItems(String listId) async {
    try {
      _itemsByList[listId] = await listRepository.getItemsByList(listId);
      notifyListeners();
    } catch (_) {
      _setError('Não foi possível carregar os itens da lista.');
    }
  }

  Future<HouseholdListItem?> createListItem({
    required HouseholdList list,
    required String displayName,
    num? quantity,
    String? unit,
  }) async {
    final normalizedName = displayName.trim();
    if (normalizedName.isEmpty) {
      _setError('Informe o item da lista.');
      return null;
    }
    final now = DateTime.now();
    final item = HouseholdListItem(
      id: uuid.v4(),
      listId: list.id,
      scopeId: list.scopeId,
      displayName: normalizedName,
      identityKey: HouseholdListItemIdentity.normalize(normalizedName),
      status: HouseholdListItemStatus.pending,
      createdAt: now,
      updatedAt: now,
      quantity: quantity,
      unit: _emptyToNull(unit),
    );
    try {
      _clearMessages();
      await listRepository.saveItem(item);
      final items = _itemsByList.putIfAbsent(list.id, () => []);
      items.add(item);
      _sortListItems(items);
      notifyListeners();
      return item;
    } catch (_) {
      _setError('Não foi possível adicionar o item.');
      return null;
    }
  }

  Future<HouseholdListItem?> updateListItem({
    required HouseholdListItem item,
    required String displayName,
    num? quantity,
    String? unit,
  }) async {
    final normalizedName = displayName.trim();
    if (normalizedName.isEmpty) {
      _setError('Informe o item da lista.');
      return null;
    }
    final updated = item.edit(
      displayName: normalizedName,
      identityKey: HouseholdListItemIdentity.normalize(normalizedName),
      quantity: quantity,
      unit: _emptyToNull(unit),
      updatedAt: DateTime.now(),
    );
    try {
      _clearMessages();
      await listRepository.saveItem(updated);
      _replaceListItem(updated);
      notifyListeners();
      return updated;
    } catch (_) {
      _setError('Não foi possível atualizar o item.');
      return null;
    }
  }

  Future<bool> setListItemPurchased({
    required HouseholdListItem item,
    required bool purchased,
    String? completedBy,
  }) async {
    final now = DateTime.now();
    final updated = purchased
        ? item.markPurchased(at: now, by: _emptyToNull(completedBy))
        : item.markPending(now);
    try {
      _clearMessages();
      if (purchased) {
        await listRepository.markItemPurchased(
          item: updated,
          event: HouseholdListItemPurchaseEvent(
            id: uuid.v4(),
            itemId: item.id,
            listId: item.listId,
            scopeId: item.scopeId,
            displayName: item.displayName,
            identityKey: item.identityKey,
            purchasedAt: now,
            purchasedBy: _emptyToNull(completedBy),
          ),
        );
      } else {
        await listRepository.saveItem(updated);
      }
      _replaceListItem(updated);
      notifyListeners();
      return true;
    } catch (_) {
      _setError('Não foi possível atualizar o item.');
      return false;
    }
  }

  Future<bool> deleteListItem(HouseholdListItem item) async {
    try {
      _clearMessages();
      await listRepository.deleteItem(item.id);
      _itemsByList[item.listId]?.removeWhere((saved) => saved.id == item.id);
      notifyListeners();
      return true;
    } catch (_) {
      _setError('Não foi possível remover o item.');
      return false;
    }
  }

  Future<HouseholdTask?> createTask({
    required String scopeId,
    required HouseholdTaskScope scope,
    required String title,
    String? notes,
    String? assigneeId,
    DateTime? dueAt,
    int? repeatEveryDays,
  }) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      _setError('Informe o nome da tarefa.');
      return null;
    }
    if (repeatEveryDays != null && repeatEveryDays <= 0) {
      _setError('A recorrência deve ser maior que zero dias.');
      return null;
    }
    final now = DateTime.now();
    final task = HouseholdTask(
      id: uuid.v4(),
      scopeId: scopeId,
      scope: scope,
      title: normalizedTitle,
      notes: _emptyToNull(notes),
      assigneeId: _emptyToNull(assigneeId),
      status: HouseholdTaskStatus.pending,
      dueAt: dueAt,
      repeatEveryDays: repeatEveryDays,
      createdAt: now,
      updatedAt: now,
    );
    try {
      _clearMessages();
      await taskRepository.saveTask(task);
      _tasks.add(task);
      notifyListeners();
      return task;
    } catch (_) {
      _setError('Não foi possível criar a tarefa.');
      return null;
    }
  }

  Future<HouseholdTask?> updateTask({
    required HouseholdTask task,
    required String title,
    String? notes,
    String? assigneeId,
    DateTime? dueAt,
    int? repeatEveryDays,
  }) async {
    if (!task.isPending) {
      _setError('Apenas tarefas pendentes podem ser editadas.');
      return null;
    }
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      _setError('Informe o nome da tarefa.');
      return null;
    }
    if (repeatEveryDays != null && repeatEveryDays <= 0) {
      _setError('A recorrência deve ser maior que zero dias.');
      return null;
    }

    final updated = HouseholdTask(
      id: task.id,
      scopeId: task.scopeId,
      scope: task.scope,
      title: normalizedTitle,
      notes: _emptyToNull(notes),
      assigneeId: _emptyToNull(assigneeId),
      status: task.status,
      dueAt: dueAt,
      repeatEveryDays: repeatEveryDays,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
      completedAt: task.completedAt,
      routineId: task.routineId,
      routineStepIndex: task.routineStepIndex,
      previousTaskId: task.previousTaskId,
    );

    try {
      _clearMessages();
      await taskRepository.saveTask(updated);
      _replaceTask(updated);
      _successMessage = 'Tarefa atualizada.';
      notifyListeners();
      return updated;
    } catch (_) {
      _setError('Não foi possível atualizar a tarefa.');
      return null;
    }
  }

  Future<HouseholdRoutine?> createRoutine({
    required String scopeId,
    required HouseholdTaskScope scope,
    required String name,
    required List<HouseholdRoutineStep> steps,
    required DateTime startsAt,
    int? repeatEveryDays,
  }) async {
    final normalizedName = name.trim();
    final normalizedSteps = _normalizeSteps(steps);
    if (!_validateRoutineInput(
      name: normalizedName,
      steps: normalizedSteps,
      repeatEveryDays: repeatEveryDays,
    )) {
      return null;
    }
    final now = DateTime.now();
    final routine = HouseholdRoutine(
      id: uuid.v4(),
      scopeId: scopeId,
      name: normalizedName,
      steps: normalizedSteps,
      repeatEveryDays: repeatEveryDays,
      createdAt: now,
      updatedAt: now,
    );
    try {
      _clearMessages();
      await routineRepository.saveRoutine(routine);
      final firstTask = await routineService.startRoutine(
        routine: routine,
        scope: scope,
        startsAt: startsAt,
      );
      _routines.add(routine);
      _replaceTask(firstTask);
      notifyListeners();
      return routine;
    } catch (_) {
      _setError('Não foi possível criar a rotina.');
      return null;
    }
  }

  Future<HouseholdRoutine?> updateRoutine({
    required HouseholdRoutine routine,
    required String name,
    required List<HouseholdRoutineStep> steps,
    int? repeatEveryDays,
  }) async {
    final normalizedName = name.trim();
    final normalizedSteps = _normalizeSteps(steps);
    if (!_validateRoutineInput(
      name: normalizedName,
      steps: normalizedSteps,
      repeatEveryDays: repeatEveryDays,
    )) {
      return null;
    }

    final updated = HouseholdRoutine(
      id: routine.id,
      scopeId: routine.scopeId,
      name: normalizedName,
      steps: normalizedSteps,
      repeatEveryDays: repeatEveryDays,
      createdAt: routine.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      _clearMessages();
      await routineRepository.saveRoutine(updated);
      _replaceRoutine(updated);
      _successMessage = 'Rotina atualizada. As etapas já concluídas foram preservadas.';
      notifyListeners();
      return updated;
    } catch (_) {
      _setError('Não foi possível atualizar a rotina.');
      return null;
    }
  }

  Future<HouseholdTask?> startRoutine({
    required HouseholdRoutine routine,
    required HouseholdTaskScope scope,
    DateTime? startsAt,
  }) async {
    try {
      _clearMessages();
      final task = await routineService.startRoutine(
        routine: routine,
        scope: scope,
        startsAt: startsAt ?? DateTime.now(),
      );
      _replaceTask(task);
      notifyListeners();
      return task;
    } catch (_) {
      _setError('Não foi possível iniciar a rotina.');
      return null;
    }
  }

  Future<HouseholdTask?> completeTask(String taskId) async {
    try {
      _clearMessages();
      final nextTask = await routineService.completeTask(
        taskId: taskId,
        completedAt: DateTime.now(),
      );
      final current = await taskRepository.getTaskById(taskId);
      if (current != null) _replaceTask(current);
      if (nextTask != null) _replaceTask(nextTask);
      notifyListeners();
      return nextTask;
    } catch (_) {
      _setError('Não foi possível concluir a tarefa.');
      return null;
    }
  }

  Future<void> cancelTask(String taskId) async {
    try {
      _clearMessages();
      await routineService.cancelTask(
        taskId: taskId,
        cancelledAt: DateTime.now(),
      );
      final current = await taskRepository.getTaskById(taskId);
      if (current != null) _replaceTask(current);
      notifyListeners();
    } catch (_) {
      _setError('Não foi possível cancelar a tarefa.');
    }
  }

  Future<bool> remindTask({
    required HouseholdTask task,
    required String currentUserId,
    DateTime? remindAt,
  }) async {
    try {
      _clearMessages();
      final isPartnerReminder = task.scope == HouseholdTaskScope.shared &&
          task.assigneeId != null &&
          task.assigneeId != currentUserId;
      final result = await reminderService.remindAssignee(
        task: task,
        senderUserId: currentUserId,
        now: DateTime.now(),
        remindAt: remindAt,
      );
      if (result.sent) {
        _successMessage = isPartnerReminder
            ? 'Lembrete enviado ao responsável.'
            : 'Lembrete agendado.';
        notifyListeners();
        return true;
      }
      if (result.blocked) {
        final minutes = result.retryAfter!.inMinutes +
            (result.retryAfter!.inSeconds % 60 == 0 ? 0 : 1);
        _setError(
          minutes >= 60
              ? 'Aguarde antes de lembrar novamente.'
              : 'Você poderá lembrar novamente em cerca de $minutes min.',
        );
        return false;
      }
      _setError(result.errorMessage ?? 'Não foi possível criar o lembrete.');
      return false;
    } catch (_) {
      _setError('Não foi possível criar o lembrete.');
      return false;
    }
  }

  List<HouseholdRoutineStep> _normalizeSteps(
    List<HouseholdRoutineStep> steps,
  ) {
    return steps
        .where((step) => step.title.trim().isNotEmpty)
        .map(
          (step) => HouseholdRoutineStep(
            title: step.title.trim(),
            notes: _emptyToNull(step.notes),
            delayAfterPrevious: step.delayAfterPrevious,
            assigneeId: _emptyToNull(step.assigneeId),
          ),
        )
        .toList();
  }

  bool _validateRoutineInput({
    required String name,
    required List<HouseholdRoutineStep> steps,
    required int? repeatEveryDays,
  }) {
    if (name.isEmpty) {
      _setError('Informe o nome da rotina.');
      return false;
    }
    if (steps.isEmpty) {
      _setError('Adicione pelo menos uma etapa à rotina.');
      return false;
    }
    if (steps.any((step) => step.delayAfterPrevious.isNegative)) {
      _setError('O tempo entre etapas não pode ser negativo.');
      return false;
    }
    if (repeatEveryDays != null && repeatEveryDays <= 0) {
      _setError('A recorrência deve ser maior que zero dias.');
      return false;
    }
    return true;
  }

  void _replaceTask(HouseholdTask task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
  }

  void _replaceRoutine(HouseholdRoutine routine) {
    final index = _routines.indexWhere((item) => item.id == routine.id);
    if (index == -1) {
      _routines.add(routine);
    } else {
      _routines[index] = routine;
    }
  }

  void _replaceList(HouseholdList list) {
    final index = _lists.indexWhere((item) => item.id == list.id);
    if (index == -1) {
      _lists.add(list);
    } else {
      _lists[index] = list;
    }
  }

  void _replaceListItem(HouseholdListItem item) {
    final items = _itemsByList.putIfAbsent(item.listId, () => []);
    final index = items.indexWhere((saved) => saved.id == item.id);
    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }
    _sortListItems(items);
  }

  void _sortListItems(List<HouseholdListItem> items) {
    items.sort((a, b) {
      if (a.isPurchased != b.isPurchased) return a.isPurchased ? 1 : -1;
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _successMessage = null;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  static String? _emptyToNull(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
