import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/household_routine.dart';
import '../../domain/models/household_task.dart';
import '../../domain/repositories/household_routine_repository.dart';
import '../../domain/repositories/household_task_repository.dart';
import '../../domain/services/household_routine_service.dart';

class HouseholdRoutinesController extends ChangeNotifier {
  final HouseholdTaskRepository taskRepository;
  final HouseholdRoutineRepository routineRepository;
  final HouseholdRoutineService routineService;
  final Uuid uuid;

  HouseholdRoutinesController({required this.taskRepository, required this.routineRepository, required this.routineService, this.uuid = const Uuid()});

  final List<HouseholdTask> _tasks = [];
  final List<HouseholdRoutine> _routines = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<HouseholdTask> get tasks => List.unmodifiable(_tasks);
  List<HouseholdRoutine> get routines => List.unmodifiable(_routines);
  List<HouseholdTask> get pendingTasks => List.unmodifiable(_tasks.where((task) => task.isPending).toList()..sort((a, b) {
    final aDue = a.dueAt; final bDue = b.dueAt;
    if (aDue == null && bDue == null) return 0;
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    return aDue.compareTo(bDue);
  }));
  List<HouseholdTask> get completedTasks => List.unmodifiable(_tasks.where((task) => task.isCompleted).toList()..sort((a, b) => (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt)));
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load(String scopeId) async {
    _setLoading(true);
    try {
      _errorMessage = null;
      final results = await Future.wait([taskRepository.getTasksByScope(scopeId), routineRepository.getRoutinesByScope(scopeId)]);
      _tasks..clear()..addAll(results[0] as List<HouseholdTask>);
      _routines..clear()..addAll(results[1] as List<HouseholdRoutine>);
    } catch (_) { _errorMessage = 'Não foi possível carregar as rotinas da casa.'; }
    finally { _setLoading(false); }
  }

  Future<HouseholdTask?> createTask({required String scopeId, required HouseholdTaskScope scope, required String title, String? notes, String? assigneeId, DateTime? dueAt}) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) { _setError('Informe o nome da tarefa.'); return null; }
    final now = DateTime.now();
    final task = HouseholdTask(id: uuid.v4(), scopeId: scopeId, scope: scope, title: normalizedTitle, notes: _emptyToNull(notes), assigneeId: _emptyToNull(assigneeId), status: HouseholdTaskStatus.pending, dueAt: dueAt, createdAt: now, updatedAt: now);
    try { _errorMessage = null; await taskRepository.saveTask(task); _tasks.add(task); notifyListeners(); return task; }
    catch (_) { _setError('Não foi possível criar a tarefa.'); return null; }
  }

  Future<HouseholdRoutine?> createRoutine({required String scopeId, required HouseholdTaskScope scope, required String name, required List<HouseholdRoutineStep> steps, required DateTime startsAt, int? repeatEveryDays}) async {
    final normalizedName = name.trim();
    final normalizedSteps = steps.where((step) => step.title.trim().isNotEmpty).map((step) => HouseholdRoutineStep(title: step.title.trim(), notes: _emptyToNull(step.notes), delayAfterPrevious: step.delayAfterPrevious, assigneeId: _emptyToNull(step.assigneeId))).toList();
    if (normalizedName.isEmpty) { _setError('Informe o nome da rotina.'); return null; }
    if (normalizedSteps.isEmpty) { _setError('Adicione pelo menos uma etapa à rotina.'); return null; }
    if (normalizedSteps.any((step) => step.delayAfterPrevious.isNegative)) { _setError('O tempo entre etapas não pode ser negativo.'); return null; }
    if (repeatEveryDays != null && repeatEveryDays <= 0) { _setError('A recorrência deve ser maior que zero dias.'); return null; }
    final now = DateTime.now();
    final routine = HouseholdRoutine(id: uuid.v4(), scopeId: scopeId, name: normalizedName, steps: normalizedSteps, repeatEveryDays: repeatEveryDays, createdAt: now, updatedAt: now);
    try {
      _errorMessage = null; await routineRepository.saveRoutine(routine);
      final firstTask = await routineService.startRoutine(routine: routine, scope: scope, startsAt: startsAt);
      _routines.add(routine); _replaceTask(firstTask); notifyListeners(); return routine;
    } catch (_) { _setError('Não foi possível criar a rotina.'); return null; }
  }

  Future<HouseholdTask?> startRoutine({required HouseholdRoutine routine, required HouseholdTaskScope scope, DateTime? startsAt}) async {
    try { _errorMessage = null; final task = await routineService.startRoutine(routine: routine, scope: scope, startsAt: startsAt ?? DateTime.now()); _replaceTask(task); notifyListeners(); return task; }
    catch (_) { _setError('Não foi possível iniciar a rotina.'); return null; }
  }

  Future<HouseholdTask?> completeTask(String taskId) async {
    try {
      _errorMessage = null; final nextTask = await routineService.completeTask(taskId: taskId, completedAt: DateTime.now());
      final current = await taskRepository.getTaskById(taskId); if (current != null) _replaceTask(current); if (nextTask != null) _replaceTask(nextTask); notifyListeners(); return nextTask;
    } catch (_) { _setError('Não foi possível concluir a tarefa.'); return null; }
  }

  Future<void> cancelTask(String taskId) async {
    try { _errorMessage = null; await routineService.cancelTask(taskId: taskId, cancelledAt: DateTime.now()); final current = await taskRepository.getTaskById(taskId); if (current != null) _replaceTask(current); notifyListeners(); }
    catch (_) { _setError('Não foi possível cancelar a tarefa.'); }
  }

  void _replaceTask(HouseholdTask task) { final index = _tasks.indexWhere((item) => item.id == task.id); if (index == -1) { _tasks.add(task); } else { _tasks[index] = task; } }
  void _setLoading(bool value) { _isLoading = value; notifyListeners(); }
  void _setError(String message) { _errorMessage = message; notifyListeners(); }
  static String? _emptyToNull(String? value) { final normalized = value?.trim(); return normalized == null || normalized.isEmpty ? null : normalized; }
}
