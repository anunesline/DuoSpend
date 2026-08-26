enum HouseholdTaskStatus {
  pending,
  completed,
  cancelled,
}

enum HouseholdTaskScope {
  personal,
  shared,
}

class HouseholdTask {
  final String id;
  final String scopeId;
  final HouseholdTaskScope scope;
  final String title;
  final String? notes;
  final String? assigneeId;
  final HouseholdTaskStatus status;
  final DateTime? dueAt;
  final int? repeatEveryDays;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? routineId;
  final int? routineStepIndex;
  final String? previousTaskId;

  const HouseholdTask({
    required this.id,
    required this.scopeId,
    required this.scope,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.assigneeId,
    this.dueAt,
    this.repeatEveryDays,
    this.completedAt,
    this.routineId,
    this.routineStepIndex,
    this.previousTaskId,
  });

  bool get isPending => status == HouseholdTaskStatus.pending;
  bool get isCompleted => status == HouseholdTaskStatus.completed;
  bool get isCancelled => status == HouseholdTaskStatus.cancelled;
  bool get belongsToRoutine => routineId != null && routineStepIndex != null;
  bool get isRecurring => repeatEveryDays != null && repeatEveryDays! > 0;

  HouseholdTask complete(DateTime completedAt) {
    if (!isPending) return this;
    return copyWith(
      status: HouseholdTaskStatus.completed,
      completedAt: completedAt,
      updatedAt: completedAt,
    );
  }

  HouseholdTask cancel(DateTime cancelledAt) {
    if (!isPending) return this;
    return copyWith(
      status: HouseholdTaskStatus.cancelled,
      updatedAt: cancelledAt,
    );
  }

  HouseholdTask copyWith({
    String? id,
    String? scopeId,
    HouseholdTaskScope? scope,
    String? title,
    String? notes,
    String? assigneeId,
    HouseholdTaskStatus? status,
    DateTime? dueAt,
    int? repeatEveryDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? routineId,
    int? routineStepIndex,
    String? previousTaskId,
  }) {
    return HouseholdTask(
      id: id ?? this.id,
      scopeId: scopeId ?? this.scopeId,
      scope: scope ?? this.scope,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      assigneeId: assigneeId ?? this.assigneeId,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      repeatEveryDays: repeatEveryDays ?? this.repeatEveryDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      routineId: routineId ?? this.routineId,
      routineStepIndex: routineStepIndex ?? this.routineStepIndex,
      previousTaskId: previousTaskId ?? this.previousTaskId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'scopeId': scopeId,
        'scope': scope.name,
        'title': title,
        'notes': notes,
        'assigneeId': assigneeId,
        'status': status.name,
        'dueAt': dueAt?.toIso8601String(),
        'repeatEveryDays': repeatEveryDays,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'routineId': routineId,
        'routineStepIndex': routineStepIndex,
        'previousTaskId': previousTaskId,
      };

  factory HouseholdTask.fromMap(Map<String, dynamic> map) {
    return HouseholdTask(
      id: map['id']?.toString() ?? '',
      scopeId: map['scopeId']?.toString() ?? '',
      scope: _scopeFromValue(map['scope']?.toString()),
      title: map['title']?.toString() ?? '',
      notes: map['notes']?.toString(),
      assigneeId: map['assigneeId']?.toString(),
      status: _statusFromValue(map['status']?.toString()),
      dueAt: _dateFromValue(map['dueAt']),
      repeatEveryDays: _intFromValue(map['repeatEveryDays']),
      createdAt: _dateFromValue(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateFromValue(map['updatedAt']) ?? DateTime.now(),
      completedAt: _dateFromValue(map['completedAt']),
      routineId: map['routineId']?.toString(),
      routineStepIndex: _intFromValue(map['routineStepIndex']),
      previousTaskId: map['previousTaskId']?.toString(),
    );
  }

  static HouseholdTaskScope _scopeFromValue(String? value) =>
      HouseholdTaskScope.values.firstWhere(
        (item) => item.name == value,
        orElse: () => HouseholdTaskScope.personal,
      );

  static HouseholdTaskStatus _statusFromValue(String? value) =>
      HouseholdTaskStatus.values.firstWhere(
        (item) => item.name == value,
        orElse: () => HouseholdTaskStatus.pending,
      );

  static DateTime? _dateFromValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static int? _intFromValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
