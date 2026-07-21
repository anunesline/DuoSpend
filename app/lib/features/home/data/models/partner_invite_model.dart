enum PartnerInviteStatus {
  pending,
  accepted,
  declined,
  cancelled,
  expired;

  String get value {
    return name;
  }

  static PartnerInviteStatus fromValue(String? value) {
    return PartnerInviteStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PartnerInviteStatus.pending,
    );
  }
}

class PartnerInviteModel {
  final String id;

  /// Carteira compartilhada relacionada ao convite.
  final String walletId;

  /// Usuário que criou e enviou o convite.
  final String inviterUserId;

  /// E-mail informado para localizar o parceiro.
  final String invitedEmail;

  /// ID do usuário convidado.
  ///
  /// Pode permanecer vazio enquanto o parceiro ainda não possuir
  /// uma conta no DuoSpend ou enquanto o convite não for aceito.
  final String invitedUserId;

  final PartnerInviteStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Momento em que o convite foi aceito.
  ///
  /// Permanece nulo enquanto o convite não tiver sido aceito.
  final DateTime? acceptedAt;

  /// Data limite para utilização do convite.
  ///
  /// Nesta primeira versão, poderá permanecer nula.
  final DateTime? expiresAt;

  PartnerInviteModel({
    required this.id,
    required this.walletId,
    required this.inviterUserId,
    required this.invitedEmail,
    this.invitedUserId = '',
    this.status = PartnerInviteStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.acceptedAt,
    this.expiresAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isPending {
    return status == PartnerInviteStatus.pending;
  }

  bool get isAccepted {
    return status == PartnerInviteStatus.accepted;
  }

  bool get isDeclined {
    return status == PartnerInviteStatus.declined;
  }

  bool get isCancelled {
    return status == PartnerInviteStatus.cancelled;
  }

  bool get isExpired {
    if (status == PartnerInviteStatus.expired) {
      return true;
    }

    final expirationDate = expiresAt;

    if (expirationDate == null) {
      return false;
    }

    return DateTime.now().isAfter(expirationDate);
  }

  bool get canBeAccepted {
    return isPending && !isExpired;
  }

  bool get hasInvitedUser {
    return invitedUserId.trim().isNotEmpty;
  }

  String get normalizedInvitedEmail {
    return invitedEmail.trim().toLowerCase();
  }

  bool wasCreatedBy(String userId) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return false;
    }

    return inviterUserId == normalizedUserId;
  }

  bool belongsToInvitedUser(String userId) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return false;
    }

    return invitedUserId == normalizedUserId;
  }

  bool belongsToEmail(String email) {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      return false;
    }

    return normalizedInvitedEmail == normalizedEmail;
  }

  PartnerInviteModel accept({
    required String userId,
  }) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'O ID do usuário convidado não pode ficar vazio.',
      );
    }

    if (!canBeAccepted) {
      throw StateError(
        'Este convite não está disponível para aceite.',
      );
    }

    final now = DateTime.now();

    return copyWith(
      invitedUserId: normalizedUserId,
      status: PartnerInviteStatus.accepted,
      acceptedAt: now,
      updatedAt: now,
    );
  }

  PartnerInviteModel decline() {
    if (!isPending) {
      throw StateError(
        'Somente convites pendentes podem ser recusados.',
      );
    }

    return copyWith(
      status: PartnerInviteStatus.declined,
      updatedAt: DateTime.now(),
    );
  }

  PartnerInviteModel cancel() {
    if (!isPending) {
      throw StateError(
        'Somente convites pendentes podem ser cancelados.',
      );
    }

    return copyWith(
      status: PartnerInviteStatus.cancelled,
      updatedAt: DateTime.now(),
    );
  }

  PartnerInviteModel expire() {
    if (!isPending) {
      return this;
    }

    return copyWith(
      status: PartnerInviteStatus.expired,
      updatedAt: DateTime.now(),
    );
  }

  PartnerInviteModel copyWith({
    String? id,
    String? walletId,
    String? inviterUserId,
    String? invitedEmail,
    String? invitedUserId,
    PartnerInviteStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? expiresAt,
    bool clearAcceptedAt = false,
    bool clearExpiresAt = false,
  }) {
    return PartnerInviteModel(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      inviterUserId: inviterUserId ?? this.inviterUserId,
      invitedEmail: invitedEmail ?? this.invitedEmail,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: clearAcceptedAt
          ? null
          : acceptedAt ?? this.acceptedAt,
      expiresAt: clearExpiresAt
          ? null
          : expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'walletId': walletId,
      'inviterUserId': inviterUserId,
      'invitedEmail': normalizedInvitedEmail,
      'invitedUserId': invitedUserId,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory PartnerInviteModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return PartnerInviteModel(
      id: map['id']?.toString() ?? '',
      walletId: map['walletId']?.toString() ?? '',
      inviterUserId: map['inviterUserId']?.toString() ?? '',
      invitedEmail: map['invitedEmail']?.toString() ?? '',
      invitedUserId: map['invitedUserId']?.toString() ?? '',
      status: PartnerInviteStatus.fromValue(
        map['status']?.toString(),
      ),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      acceptedAt: _parseDateTime(map['acceptedAt']),
      expiresAt: _parseDateTime(map['expiresAt']),
    );
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
}