enum HouseholdListType { general, shopping }

enum HouseholdListStatus { active, archived }

class HouseholdList {
  final String id;
  final String scopeId;
  final String name;
  final HouseholdListType type;
  final HouseholdListStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Reserved for an explicit future association with a financial record.
  /// It is never populated or consumed by the routines module today.
  final String? financialReferenceId;

  const HouseholdList({
    required this.id,
    required this.scopeId,
    required this.name,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.financialReferenceId,
  });

  bool get isActive => status == HouseholdListStatus.active;
  bool get isShopping => type == HouseholdListType.shopping;

  HouseholdList copyWith({
    String? name,
    HouseholdListType? type,
    HouseholdListStatus? status,
    DateTime? updatedAt,
    String? financialReferenceId,
  }) =>
      HouseholdList(
        id: id,
        scopeId: scopeId,
        name: name ?? this.name,
        type: type ?? this.type,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        financialReferenceId: financialReferenceId ?? this.financialReferenceId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'scopeId': scopeId,
        'name': name,
        'type': type.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'financialReferenceId': financialReferenceId,
      };

  factory HouseholdList.fromMap(Map<String, dynamic> map) => HouseholdList(
        id: map['id']?.toString() ?? '',
        scopeId: map['scopeId']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        type: HouseholdListType.values.firstWhere(
          (value) => value.name == map['type']?.toString(),
          orElse: () => HouseholdListType.general,
        ),
        status: HouseholdListStatus.values.firstWhere(
          (value) => value.name == map['status']?.toString(),
          orElse: () => HouseholdListStatus.active,
        ),
        createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
        updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
        financialReferenceId: map['financialReferenceId']?.toString(),
      );
}

DateTime? householdListDateFromValue(Object? value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}

DateTime? _readDate(Object? value) => householdListDateFromValue(value);
