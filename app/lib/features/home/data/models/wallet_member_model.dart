class WalletMemberModel {
  final String id;

  /// UID do usuário no Firebase.
  final String userId;

  /// Nome exibido na carteira.
  final String displayName;

  /// Papel dentro da carteira.
  ///
  /// owner
  /// partner
  /// member
  final String role;

  /// Indica se o membro está ativo na carteira.
  final bool active;

  /// Data de entrada na carteira.
  final DateTime joinedAt;

  const WalletMemberModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.role,
    this.active = true,
    required this.joinedAt,
  });

  bool get isOwner => role == 'owner';

  bool get isPartner => role == 'partner';

  bool get isRegularMember => role == 'member';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'displayName': displayName,
      'role': role,
      'active': active,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory WalletMemberModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return WalletMemberModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      role: map['role']?.toString() ?? 'member',
      active: map['active'] ?? true,
      joinedAt:
          DateTime.tryParse(
            map['joinedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  WalletMemberModel copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? role,
    bool? active,
    DateTime? joinedAt,
  }) {
    return WalletMemberModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      active: active ?? this.active,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}