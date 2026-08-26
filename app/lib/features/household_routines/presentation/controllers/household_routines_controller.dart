import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/household_task.dart';
import '../../domain/repositories/household_task_repository.dart';
import '../../domain/services/household_routine_service.dart';

class HouseholdRoutinesController extends ChangeNotifier {
  final HouseholdTaskRepository taskRepository;
  final HouseholdRoutineService routineService;
  final Uuid uuid;

  HouseholdRoutinesController({
    required this.taskRepository,
    required this.routineService,
    this.uuid = const Uuid(),
  });

  final List<HouseholdTask> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<HouseholdTask> get tasks => List.unmodifiable(_tasks);
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
          ..sort((a, b) => (b.completedAt ?? b.updatedAt)
              .compareTo(a.completedAt ?? a.updatedAt)),
      );

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load(String scopeId) async {
    _setLoading(true);
    try {
      _errorMessage = null;
      _tasks
        ..clear()
        ..addAll(await taskRepository.getTasksByScope(scopeId));
    } catch (_) {
      _errorMessage = 'Não foi possível carregar as rotinas da casa.';
    } finally {
      _setLoading(false);
    }
  }

  Future<HouseholdTask?> createTask({
    required String scopeId,
    required HouseholdTaskScope scope,
    required String title,
    String? notes,
    String? assigneeId,
    DateTime? dueAt,
  }) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      _errorMessage = 'Informe o nome da tarefa.';
      notifyListeners();
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
      createdAt: now,
      updatedAt: now,
    );

    try {
      _errorMessage = null;
      await taskRepository.saveTask(task);
      _tasks.add(task);
      notifyListeners();
      return task;
    } catch (_) {
      _errorMessage = 'Não foi possível criar a tarefa.';
      notifyListeners();
      return null;
    }
  }

  Future<HouseholdTask?> completeTask(String taskId) async {
    try {
      _errorMessage = null;
      final nextTask = await routineService.completeTask(
        taskId: taskId,
        completedAt: DateTime.now(),
      );
      final current = await taskRepository.getTaskById(taskId);
      if (current != null) {
        _replaceTask(current);
      }
      if (nextTask != null) {
        _replaceTask(nextTask);
      }
      notifyListeners();
      return nextTask;
    } catch (_) {
      _errorMessage = 'Não foi possível concluir a tarefa.';
      notifyListeners();
      return null;
    }
  }

  Future<void> cancelTask(String taskId) async {
    try {
      _errorMessage = null;
      await routineService.cancelTask(
        taskId: taskId,
        cancelledAt: DateTime.now(),
      );
      final current = await taskRepository.getTaskById(taskId);
      if (current != null) {
        _replaceTask(current);
      }
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Não foi possível cancelar a tarefa.';
      notifyListeners();
    }
  }

  void _replaceTask(HouseholdTask task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  static String? _emptyToNull(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
