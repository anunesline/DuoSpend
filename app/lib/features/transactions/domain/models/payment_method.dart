enum PaymentMethod {
  cash(
    value: 'cash',
    label: 'Dinheiro',
    affectsBalanceImmediately: true,
    requiresPaymentSource: false,
    representsCreditObligation: false,
  ),
  pix(
    value: 'pix',
    label: 'Pix',
    affectsBalanceImmediately: true,
    requiresPaymentSource: true,
    representsCreditObligation: false,
  ),
  debitCard(
    value: 'debitCard',
    label: 'Cartão de débito',
    affectsBalanceImmediately: true,
    requiresPaymentSource: true,
    representsCreditObligation: false,
  ),
  creditCard(
    value: 'creditCard',
    label: 'Cartão de crédito',
    affectsBalanceImmediately: false,
    requiresPaymentSource: true,
    representsCreditObligation: true,
  ),
  boleto(
    value: 'boleto',
    label: 'Boleto',
    affectsBalanceImmediately: false,
    requiresPaymentSource: false,
    representsCreditObligation: true,
  ),
  carne(
    value: 'carne',
    label: 'Carnê',
    affectsBalanceImmediately: false,
    requiresPaymentSource: false,
    representsCreditObligation: true,
  ),
  other(
    value: 'other',
    label: 'Outro',
    affectsBalanceImmediately: false,
    requiresPaymentSource: false,
    representsCreditObligation: false,
  );

  final String value;
  final String label;

  /// Indica que a transação deve movimentar saldo disponível
  /// no momento em que é registrada.
  final bool affectsBalanceImmediately;

  /// Indica que a forma de pagamento precisa apontar para
  /// uma origem financeira específica em paymentSourceId.
  ///
  /// Exemplos:
  /// - conta usada no Pix;
  /// - conta/cartão de débito;
  /// - cartão de crédito.
  final bool requiresPaymentSource;

  /// Indica que a transação gera uma obrigação financeira
  /// a ser liquidada posteriormente.
  ///
  /// Exemplos:
  /// - fatura de cartão;
  /// - boleto futuro;
  /// - carnê.
  final bool representsCreditObligation;

  const PaymentMethod({
    required this.value,
    required this.label,
    required this.affectsBalanceImmediately,
    required this.requiresPaymentSource,
    required this.representsCreditObligation,
  });

  bool get isCreditCard {
    return this == PaymentMethod.creditCard;
  }

  bool get isDeferredPayment {
    return !affectsBalanceImmediately &&
        representsCreditObligation;
  }

  static PaymentMethod? fromValue(
    String? value,
  ) {
    final normalizedValue = value?.trim();

    if (normalizedValue == null ||
        normalizedValue.isEmpty) {
      return null;
    }

    for (final method in PaymentMethod.values) {
      if (method.value == normalizedValue) {
        return method;
      }
    }

    return null;
  }
}
