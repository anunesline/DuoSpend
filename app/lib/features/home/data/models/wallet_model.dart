enum WalletType {
  individual,
  shared;

  String get value {
    return name;
  }

  static WalletType fromValue(String? value) {
    return WalletType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => WalletType.individual,
    );
  }
}

class WalletModel {
  final String id;
  final String name;
  final double balance;

  /// Define se a carteira pertence somente a um usuário
  /// ou se é compartilhada entre vários usuários.
  final WalletType type;

  /// Usuário responsável pela criação e administração da carteira.
  ///
  /// Em registros antigos, esse valor pode estar vazio até que
  /// a carteira seja associada ao usuário autenticado.
  final String ownerId;

  /// IDs dos usuários que participam da carteira.
  ///
  /// Em uma carteira individual, normalmente contém apenas o ownerId.
  /// Em uma carteira compartilhada, contém o ownerId e os demais membros.
  final List<String> memberIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  WalletModel({
    required this.id,
    required this.name,
    required this.balance,
    this.type = WalletType.individual,
    this.ownerId = '',
    this.memberIds = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isIndividual {
    return type == WalletType.individual;
  }

  bool get isShared {
    return type == WalletType.shared;
  }

  bool hasMember(String userId) {
    if (userId.isEmpty) {
      return false;
    }

    return ownerId == userId || memberIds.contains(userId);
  }

  WalletModel copyWith({
    String? id,
    String? name,
    double? balance,
    WalletType? type,
    String? ownerId,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'type': type.value,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    final ownerId = map['ownerId']?.toString() ?? '';

    final memberIds = _parseMemberIds(map['memberIds'], ownerId: ownerId);

    return WalletModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      balance: _parseDouble(map['balance']),
      type: WalletType.fromValue(map['type']?.toString()),
      ownerId: ownerId,
      memberIds: memberIds,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  static List<String> _parseMemberIds(
    dynamic value, {
    required String ownerId,
  }) {
    final parsedMemberIds = <String>[];

    if (value is Iterable) {
      for (final memberId in value) {
        final normalizedMemberId = memberId.toString().trim();

        if (normalizedMemberId.isNotEmpty &&
            !parsedMemberIds.contains(normalizedMemberId)) {
          parsedMemberIds.add(normalizedMemberId);
        }
      }
    }

    if (ownerId.isNotEmpty && !parsedMemberIds.contains(ownerId)) {
      parsedMemberIds.insert(0, ownerId);
    }

    return List<String>.unmodifiable(parsedMemberIds);
  }
}
