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
  /// ou se é compartilhada.
  final WalletType type;

  /// Usuário responsável pela criação e administração da carteira.
  ///
  /// Em registros antigos, esse valor pode estar vazio até que
  /// a carteira seja associada ao usuário autenticado.
  final String ownerId;

  /// IDs dos usuários que participam da carteira.
  ///
  /// Em uma carteira individual, normalmente contém apenas o proprietário.
  /// Em uma carteira compartilhada, poderá conter o proprietário e o parceiro.
  final List<String> memberIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  WalletModel({
    required this.id,
    required this.name,
    required this.balance,
    this.type = WalletType.individual,
    this.ownerId = '',
    List<String> memberIds = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : memberIds = _normalizeMemberIds(
         memberIds,
         ownerId: ownerId,
       ),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isIndividual {
    return type == WalletType.individual;
  }

  bool get isShared {
    return type == WalletType.shared;
  }

  bool get hasOwner {
    return ownerId.trim().isNotEmpty;
  }

  bool get hasPartner {
    return partnerId != null;
  }

  bool get canInvitePartner {
    return isShared && !hasPartner;
  }

  int get memberCount {
    return memberIds.length;
  }

  /// Retorna o primeiro membro diferente do proprietário.
  ///
  /// Nesta etapa, o DuoSpend considera uma carteira compartilhada
  /// formada pelo proprietário e por um parceiro.
  String? get partnerId {
    for (final memberId in memberIds) {
      if (memberId != ownerId) {
        return memberId;
      }
    }

    return null;
  }

  bool isOwner(String userId) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return false;
    }

    return ownerId == normalizedUserId;
  }

  bool hasMember(String userId) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return false;
    }

    return memberIds.contains(normalizedUserId);
  }

  WalletModel addMember(String userId) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty || hasMember(normalizedUserId)) {
      return this;
    }

    return copyWith(
      memberIds: [
        ...memberIds,
        normalizedUserId,
      ],
      updatedAt: DateTime.now(),
    );
  }

  WalletModel removeMember(String userId) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty ||
        normalizedUserId == ownerId ||
        !hasMember(normalizedUserId)) {
      return this;
    }

    return copyWith(
      memberIds: memberIds
          .where(
            (memberId) => memberId != normalizedUserId,
          )
          .toList(),
      updatedAt: DateTime.now(),
    );
  }

  WalletModel asShared() {
    if (isShared) {
      return this;
    }

    return copyWith(
      type: WalletType.shared,
      updatedAt: DateTime.now(),
    );
  }

  WalletModel asIndividual() {
    if (isIndividual && memberIds.length <= 1) {
      return this;
    }

    return copyWith(
      type: WalletType.individual,
      memberIds: ownerId.isEmpty ? const [] : [ownerId],
      updatedAt: DateTime.now(),
    );
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
    final ownerId = map['ownerId']?.toString().trim() ?? '';

    return WalletModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      balance: _parseDouble(map['balance']),
      type: WalletType.fromValue(map['type']?.toString()),
      ownerId: ownerId,
      memberIds: _parseMemberIds(map['memberIds']),
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

  static List<String> _parseMemberIds(dynamic value) {
    if (value is! Iterable) {
      return const [];
    }

    return value
        .map(
          (memberId) => memberId.toString().trim(),
        )
        .where(
          (memberId) => memberId.isNotEmpty,
        )
        .toList();
  }

  static List<String> _normalizeMemberIds(
    Iterable<String> memberIds, {
    required String ownerId,
  }) {
    final normalizedMemberIds = <String>[];

    final normalizedOwnerId = ownerId.trim();

    if (normalizedOwnerId.isNotEmpty) {
      normalizedMemberIds.add(normalizedOwnerId);
    }

    for (final memberId in memberIds) {
      final normalizedMemberId = memberId.trim();

      if (normalizedMemberId.isEmpty ||
          normalizedMemberIds.contains(normalizedMemberId)) {
        continue;
      }

      normalizedMemberIds.add(normalizedMemberId);
    }

    return List<String>.unmodifiable(normalizedMemberIds);
  }
}