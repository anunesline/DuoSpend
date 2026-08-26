class HouseholdRoutineStep {
  final String title;
  final String? notes;
  final Duration delayAfterPrevious;
  final String? assigneeId;

  const HouseholdRoutineStep({
    required this.title,
    this.notes,
    this.delayAfterPrevious = Duration.zero,
    this.assigneeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'notes': notes,
      'delayMinutes': delayAfterPrevious.inMinutes,
      'assigneeId': assigneeId,
    };
  }

  factory HouseholdRoutineStep.fromMap(Map<String, dynamic> map) {
    return HouseholdRoutineStep(
      title: map['title']?.toString() ?? '',
      notes: map['notes']?.toString(),
      delayAfterPrevious: Duration(
        minutes: _intFromValue(map['delayMinutes']) ?? 0,
      ),
      assigneeId: map['assigneeId']?.toString(),
    );
  }

  static int? _intFromValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

class HouseholdRoutine {
  final String id;
  final String scopeId;
  final String name;
  final List<HouseholdRoutineStep> steps;
  final int? repeatEveryDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  HouseholdRoutine({
    required this.id,
    required this.scopeId,
    required this.name,
    required List<HouseholdRoutineStep> steps,
    this.repeatEveryDays,
    required this.createdAt,
    required this.updatedAt,
  }) : steps = List.unmodifiable(steps) {
    if (steps.isEmpty) {
      throw ArgumentError.value(steps, 'steps', 'A routine needs at least one step.');
    }
    if (repeatEveryDays != null && repeatEveryDays! <= 0) {
      throw ArgumentError.value(repeatEveryDays, 'repeatEveryDays', 'Repeat interval must be positive.');
    }
  }

  bool get isRecurring => repeatEveryDays != null;

  HouseholdRoutineStep? stepAt(int index) {
    if (index < 0 || index >= steps.length) return null;
    return steps[index];
  }

  HouseholdRoutineStep? nextStepAfter(int index) => stepAt(index + 1);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scopeId': scopeId,
      'name': name,
      'steps': steps.map((step) => step.toMap()).toList(),
      'repeatEveryDays': repeatEveryDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory HouseholdRoutine.fromMap(Map<String, dynamic> map) {
    final rawSteps = map['steps'];
    return HouseholdRoutine(
      id: map['id']?.toString() ?? '',
      scopeId: map['scopeId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      steps: rawSteps is Iterable
          ? rawSteps.whereType<Map>().map((step) => HouseholdRoutineStep.fromMap(Map<String, dynamic>.from(step))).toList()
          : const [],
      repeatEveryDays: _intFromValue(map['repeatEveryDays']),
      createdAt: _dateFromValue(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateFromValue(map['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static int? _intFromValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
