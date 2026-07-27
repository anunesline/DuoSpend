class FinancialResponsibility {
  final String memberId;
  final double amount;
  final bool isPayer;

  FinancialResponsibility({
    required String memberId,
    required double amount,
    required this.isPayer,
  })  : memberId = _normalizeMemberId(memberId),
        amount = _normalizeAmount(amount);

  bool get owesPayer {
    return !isPayer && amount > 0;
  }

  FinancialResponsibility copyWith({
    String? memberId,
    double? amount,
    bool? isPayer,
  }) {
    return FinancialResponsibility(
      memberId: memberId ?? this.memberId,
      amount: amount ?? this.amount,
      isPayer: isPayer ?? this.isPayer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'amount': amount,
      'isPayer': isPayer,
    };
  }

  factory FinancialResponsibility.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawAmount = map['amount'];

    if (rawAmount is! num) {
      throw ArgumentError(
        'O valor da responsabilidade financeira é inválido.',
      );
    }

    return FinancialResponsibility(
      memberId: map['memberId']?.toString() ?? '',
      amount: rawAmount.toDouble(),
      isPayer: map['isPayer'] == true,
    );
  }

  static String _normalizeMemberId(String value) {
    final normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      throw ArgumentError(
        'O responsável financeiro precisa ter um memberId.',
      );
    }

    return normalizedValue;
  }

  static double _normalizeAmount(double value) {
    if (!value.isFinite) {
      throw ArgumentError(
        'O valor da responsabilidade financeira precisa ser finito.',
      );
    }

    if (value < 0) {
      throw ArgumentError(
        'O valor da responsabilidade financeira não pode ser negativo.',
      );
    }

    return _roundCurrency(value);
  }

  static double _roundCurrency(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is FinancialResponsibility &&
        other.memberId == memberId &&
        other.amount == amount &&
        other.isPayer == isPayer;
  }

  @override
  int get hashCode {
    return Object.hash(
      memberId,
      amount,
      isPayer,
    );
  }

  @override
  String toString() {
    return 'FinancialResponsibility('
        'memberId: $memberId, '
        'amount: $amount, '
        'isPayer: $isPayer'
        ')';
  }
}