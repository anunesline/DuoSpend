class BalanceSettlementModel {
  static const String pendingStatus = 'pending';
  static const String awaitingConfirmationStatus =
      'awaiting_confirmation';
  static const String settledStatus = 'settled';

  final String id;
  final String walletId;
  final String fromMemberId;
  final String toMemberId;
  final double amount;

  /// Carteira individual escolhida pelo devedor como origem
  /// do pagamento declarado.
  final String? payerWalletId;

  /// Carteira individual escolhida pelo credor como destino
  /// do valor recebido.
  final String? receiverWalletId;

  /// Momento em que o acerto foi criado.
  final DateTime createdAt;

  /// Momento em que o pagamento foi definitivamente confirmado.
  final DateTime? settledAt;

  /// Status possíveis:
  /// - pending;
  /// - awaiting_confirmation;
  /// - settled.
  final String status;

  /// Observação opcional relacionada ao acerto.
  final String? notes;

  /// Momento em que o devedor declarou ter realizado o pagamento.
  final DateTime? paymentDeclaredAt;

  /// Membro que declarou ter realizado o pagamento.
  final String? paymentDeclaredByMemberId;

  /// Momento em que o credor confirmou o recebimento.
  final DateTime? receiptConfirmedAt;

  /// Membro que confirmou o recebimento.
  final String? receiptConfirmedByMemberId;

  /// Transação criada no histórico para representar
  /// o pagamento confirmado.
  final String? settlementTransactionId;

  const BalanceSettlementModel({
    required this.id,
    required this.walletId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    this.payerWalletId,
    this.receiverWalletId,
    required this.createdAt,
    this.settledAt,
    this.status = pendingStatus,
    this.notes,
    this.paymentDeclaredAt,
    this.paymentDeclaredByMemberId,
    this.receiptConfirmedAt,
    this.receiptConfirmedByMemberId,
    this.settlementTransactionId,
  });

  bool get isPending {
    return status == pendingStatus;
  }

  bool get isAwaitingConfirmation {
    return status == awaitingConfirmationStatus;
  }

  bool get isSettled {
    return status == settledStatus;
  }

  bool get hasPaymentDeclaration {
    return paymentDeclaredAt != null &&
        paymentDeclaredByMemberId != null &&
        paymentDeclaredByMemberId!.trim().isNotEmpty;
  }

  bool get hasReceiptConfirmation {
    return receiptConfirmedAt != null &&
        receiptConfirmedByMemberId != null &&
        receiptConfirmedByMemberId!.trim().isNotEmpty;
  }

  bool get hasSettlementTransaction {
    return settlementTransactionId != null &&
        settlementTransactionId!.trim().isNotEmpty;
  }

  BalanceSettlementModel declarePayment({
    required String declaredByMemberId,
    required DateTime declaredAt,
    required String payerWalletId,
    String? notes,
  }) {
    final normalizedMemberId = declaredByMemberId.trim();

    if (normalizedMemberId.isEmpty) {
      throw ArgumentError.value(
        declaredByMemberId,
        'declaredByMemberId',
        'O membro que declarou o pagamento não pode ficar vazio.',
      );
    }

    if (normalizedMemberId != fromMemberId.trim()) {
      throw StateError(
        'Somente o membro devedor pode declarar o pagamento.',
      );
    }

    final normalizedPayerWalletId = payerWalletId.trim();

    if (normalizedPayerWalletId.isEmpty) {
      throw ArgumentError.value(
        payerWalletId,
        'payerWalletId',
        'A carteira usada no pagamento não pode ficar vazia.',
      );
    }

    if (!isPending) {
      throw StateError(
        'Somente um acerto pendente pode ser declarado como pago.',
      );
    }

    return copyWith(
      status: awaitingConfirmationStatus,
      paymentDeclaredAt: declaredAt,
      paymentDeclaredByMemberId: normalizedMemberId,
      payerWalletId: normalizedPayerWalletId,
      notes: notes ?? this.notes,
    );
  }

  BalanceSettlementModel cancelPaymentDeclaration({
    required String cancelledByMemberId,
  }) {
    final normalizedMemberId = cancelledByMemberId.trim();

    if (normalizedMemberId.isEmpty) {
      throw ArgumentError.value(
        cancelledByMemberId,
        'cancelledByMemberId',
        'O membro que cancelou a declaração não pode ficar vazio.',
      );
    }

    if (!isAwaitingConfirmation) {
      throw StateError(
        'Não existe uma declaração de pagamento aguardando confirmação.',
      );
    }

    if (normalizedMemberId != fromMemberId.trim()) {
      throw StateError(
        'Somente o membro devedor pode cancelar a declaração de pagamento.',
      );
    }

    return BalanceSettlementModel(
      id: id,
      walletId: walletId,
      fromMemberId: fromMemberId,
      toMemberId: toMemberId,
      amount: amount,
      payerWalletId: null,
      receiverWalletId: null,
      createdAt: createdAt,
      settledAt: null,
      status: pendingStatus,
      notes: notes,
      paymentDeclaredAt: null,
      paymentDeclaredByMemberId: null,
      receiptConfirmedAt: null,
      receiptConfirmedByMemberId: null,
      settlementTransactionId: null,
    );
  }

  BalanceSettlementModel confirmReceipt({
    required String confirmedByMemberId,
    required DateTime confirmedAt,
    required String transactionId,
    required String receiverWalletId,
    String? notes,
  }) {
    final normalizedMemberId = confirmedByMemberId.trim();
    final normalizedTransactionId = transactionId.trim();
    final normalizedReceiverWalletId =
        receiverWalletId.trim();

    if (normalizedMemberId.isEmpty) {
      throw ArgumentError.value(
        confirmedByMemberId,
        'confirmedByMemberId',
        'O membro que confirmou o recebimento não pode ficar vazio.',
      );
    }

    if (normalizedTransactionId.isEmpty) {
      throw ArgumentError.value(
        transactionId,
        'transactionId',
        'O ID da transação do acerto não pode ficar vazio.',
      );
    }

    if (normalizedReceiverWalletId.isEmpty) {
      throw ArgumentError.value(
        receiverWalletId,
        'receiverWalletId',
        'A carteira que recebeu o pagamento não pode ficar vazia.',
      );
    }

    if (payerWalletId == null ||
        payerWalletId!.trim().isEmpty) {
      throw StateError(
        'O pagamento não possui uma carteira de origem informada.',
      );
    }

    if (!isAwaitingConfirmation) {
      throw StateError(
        'O pagamento precisa ser declarado antes da confirmação.',
      );
    }

    if (normalizedMemberId != toMemberId.trim()) {
      throw StateError(
        'Somente o membro credor pode confirmar o recebimento.',
      );
    }

    return copyWith(
      status: settledStatus,
      settledAt: confirmedAt,
      receiptConfirmedAt: confirmedAt,
      receiptConfirmedByMemberId: normalizedMemberId,
      settlementTransactionId: normalizedTransactionId,
      receiverWalletId: normalizedReceiverWalletId,
      notes: notes ?? this.notes,
    );
  }

  /// Mantido temporariamente para compatibilidade
  /// com partes antigas do fluxo.
  BalanceSettlementModel markAsSettled({
    required DateTime settledAt,
    String? notes,
  }) {
    return copyWith(
      status: settledStatus,
      settledAt: settledAt,
      receiptConfirmedAt: settledAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'walletId': walletId,
      'fromMemberId': fromMemberId,
      'toMemberId': toMemberId,
      'amount': amount,
      'payerWalletId': payerWalletId,
      'receiverWalletId': receiverWalletId,
      'createdAt': createdAt.toIso8601String(),
      'settledAt': settledAt?.toIso8601String(),
      'status': status,
      'notes': notes,
      'paymentDeclaredAt':
          paymentDeclaredAt?.toIso8601String(),
      'paymentDeclaredByMemberId':
          paymentDeclaredByMemberId,
      'receiptConfirmedAt':
          receiptConfirmedAt?.toIso8601String(),
      'receiptConfirmedByMemberId':
          receiptConfirmedByMemberId,
      'settlementTransactionId':
          settlementTransactionId,
    };
  }

  factory BalanceSettlementModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return BalanceSettlementModel(
      id: map['id']?.toString() ?? '',
      walletId: map['walletId']?.toString() ?? '',
      fromMemberId:
          map['fromMemberId']?.toString() ?? '',
      toMemberId: map['toMemberId']?.toString() ?? '',
      amount: _parseDouble(map['amount']),
      payerWalletId: _parseNullableString(
        map['payerWalletId'],
      ),
      receiverWalletId: _parseNullableString(
        map['receiverWalletId'],
      ),
      createdAt: _parseDateTime(map['createdAt']) ??
          DateTime.now(),
      settledAt: _parseDateTime(map['settledAt']),
      status: map['status']?.toString() ?? pendingStatus,
      notes: map['notes']?.toString(),
      paymentDeclaredAt:
          _parseDateTime(map['paymentDeclaredAt']),
      paymentDeclaredByMemberId:
          map['paymentDeclaredByMemberId']?.toString(),
      receiptConfirmedAt:
          _parseDateTime(map['receiptConfirmedAt']),
      receiptConfirmedByMemberId:
          map['receiptConfirmedByMemberId']?.toString(),
      settlementTransactionId:
          map['settlementTransactionId']?.toString(),
    );
  }

  BalanceSettlementModel copyWith({
    String? id,
    String? walletId,
    String? fromMemberId,
    String? toMemberId,
    double? amount,
    String? payerWalletId,
    String? receiverWalletId,
    bool clearPayerWalletId = false,
    bool clearReceiverWalletId = false,
    DateTime? createdAt,
    DateTime? settledAt,
    String? status,
    String? notes,
    DateTime? paymentDeclaredAt,
    String? paymentDeclaredByMemberId,
    DateTime? receiptConfirmedAt,
    String? receiptConfirmedByMemberId,
    String? settlementTransactionId,
  }) {
    return BalanceSettlementModel(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      fromMemberId: fromMemberId ?? this.fromMemberId,
      toMemberId: toMemberId ?? this.toMemberId,
      amount: amount ?? this.amount,
      payerWalletId: clearPayerWalletId
          ? null
          : payerWalletId ?? this.payerWalletId,
      receiverWalletId: clearReceiverWalletId
          ? null
          : receiverWalletId ?? this.receiverWalletId,
      createdAt: createdAt ?? this.createdAt,
      settledAt: settledAt ?? this.settledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      paymentDeclaredAt:
          paymentDeclaredAt ?? this.paymentDeclaredAt,
      paymentDeclaredByMemberId:
          paymentDeclaredByMemberId ??
          this.paymentDeclaredByMemberId,
      receiptConfirmedAt:
          receiptConfirmedAt ?? this.receiptConfirmedAt,
      receiptConfirmedByMemberId:
          receiptConfirmedByMemberId ??
          this.receiptConfirmedByMemberId,
      settlementTransactionId:
          settlementTransactionId ??
          this.settlementTransactionId,
    );
  }

  static String? _parseNullableString(dynamic value) {
    final normalizedValue = value?.toString().trim();

    if (normalizedValue == null ||
        normalizedValue.isEmpty) {
      return null;
    }

    return normalizedValue;
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
}