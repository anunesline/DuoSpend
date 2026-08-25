class CreditCardModel {
  final String id;

  /// Identificador do membro proprietário/responsável pelo cartão.
  final String ownerMemberId;

  /// Conta/carteira financeira normalmente associada ao cartão.
  ///
  /// Serve como vínculo com a instituição financeira, mas NÃO significa
  /// que compras no crédito devam movimentar o saldo desta conta.
  final String walletId;

  /// Nome exibido para o usuário.
  ///
  /// Exemplo: Inter Gold, Nubank, Visa Itaú.
  final String name;

  /// Últimos dígitos do cartão, quando informados.
  final String? lastFourDigits;

  /// Limite total concedido ao cartão.
  final double creditLimit;

  /// Valor atualmente comprometido por compras/faturas.
  final double usedLimit;

  /// Dia de fechamento da fatura.
  final int closingDay;

  /// Dia de vencimento da fatura.
  final int dueDay;

  /// Permite desativar um cartão sem perder seu histórico.
  final bool isActive;

  const CreditCardModel({
    required this.id,
    required this.ownerMemberId,
    required this.walletId,
    required this.name,
    this.lastFourDigits,
    required this.creditLimit,
    this.usedLimit = 0,
    required this.closingDay,
    required this.dueDay,
    this.isActive = true,
  });

  double get availableLimit {
    final available = creditLimit - usedLimit;

    if (available <= 0) {
      return 0;
    }

    return available;
  }

  bool get hasAvailableLimit {
    return availableLimit > 0;
  }

  bool canPurchase(double value) {
    return value > 0 && value <= availableLimit;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerMemberId': ownerMemberId,
      'walletId': walletId,
      'name': name,
      'lastFourDigits': lastFourDigits,
      'creditLimit': creditLimit,
      'usedLimit': usedLimit,
      'closingDay': closingDay,
      'dueDay': dueDay,
      'isActive': isActive,
    };
  }

  factory CreditCardModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return CreditCardModel(
      id: map['id']?.toString() ?? '',
      ownerMemberId:
          map['ownerMemberId']?.toString() ?? '',
      walletId: map['walletId']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Cartão',
      lastFourDigits:
          _parseNullableString(map['lastFourDigits']),
      creditLimit: _parseDouble(map['creditLimit']),
      usedLimit: _parseDouble(map['usedLimit']),
      closingDay: _parseInt(map['closingDay']),
      dueDay: _parseInt(map['dueDay']),
      isActive: map['isActive'] == null
          ? true
          : _parseBool(map['isActive']),
    );
  }

  CreditCardModel copyWith({
    String? id,
    String? ownerMemberId,
    String? walletId,
    String? name,
    String? lastFourDigits,
    bool clearLastFourDigits = false,
    double? creditLimit,
    double? usedLimit,
    int? closingDay,
    int? dueDay,
    bool? isActive,
  }) {
    return CreditCardModel(
      id: id ?? this.id,
      ownerMemberId:
          ownerMemberId ?? this.ownerMemberId,
      walletId: walletId ?? this.walletId,
      name: name ?? this.name,
      lastFourDigits: clearLastFourDigits
          ? null
          : lastFourDigits ?? this.lastFourDigits,
      creditLimit: creditLimit ?? this.creditLimit,
      usedLimit: usedLimit ?? this.usedLimit,
      closingDay: closingDay ?? this.closingDay,
      dueDay: dueDay ?? this.dueDay,
      isActive: isActive ?? this.isActive,
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

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    return value?.toString().toLowerCase() == 'true';
  }
}
