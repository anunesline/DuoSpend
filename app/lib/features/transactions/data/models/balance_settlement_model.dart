class BalanceSettlementModel {
  final String id;
  final String walletId;
  final String fromMemberId;
  final String toMemberId;
  final double amount;

  /// Momento em que o acerto foi registrado.
  final DateTime createdAt;

  /// Momento em que o pagamento foi confirmado.
  ///
  /// Permanece nulo enquanto o acerto estiver pendente.
  final DateTime? settledAt;

  /// Status esperado:
  /// - pending
  /// - settled
  final String status;

  /// Observação opcional sobre o pagamento.
  final String? notes;

  const BalanceSettlementModel({
    required this.id,
    required this.walletId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.createdAt,
    this.settledAt,
    this.status = 'pending',
    this.notes,
  });

  bool get isPending {
    return status == 'pending';
  }

  bool get isSettled {
    return status == 'settled';
  }

  BalanceSettlementModel markAsSettled({
    required DateTime settledAt,
    String? notes,
  }) {
    return copyWith(
      status: 'settled',
      settledAt: settledAt,
      notes: notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'walletId': walletId,
      'fromMemberId': fromMemberId,
      'toMemberId': toMemberId,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'settledAt': settledAt?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory BalanceSettlementModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return BalanceSettlementModel(
      id: map['id']?.toString() ?? '',
      walletId: map['walletId']?.toString() ?? '',
      fromMemberId: map['fromMemberId']?.toString() ?? '',
      toMemberId: map['toMemberId']?.toString() ?? '',
      amount: _parseDouble(map['amount']),
      createdAt: DateTime.tryParse(
            map['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      settledAt: DateTime.tryParse(
        map['settledAt']?.toString() ?? '',
      ),
      status: map['status']?.toString() ?? 'pending',
      notes: map['notes']?.toString(),
    );
  }

  BalanceSettlementModel copyWith({
    String? id,
    String? walletId,
    String? fromMemberId,
    String? toMemberId,
    double? amount,
    DateTime? createdAt,
    DateTime? settledAt,
    String? status,
    String? notes,
  }) {
    return BalanceSettlementModel(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      fromMemberId: fromMemberId ?? this.fromMemberId,
      toMemberId: toMemberId ?? this.toMemberId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      settledAt: settledAt ?? this.settledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}