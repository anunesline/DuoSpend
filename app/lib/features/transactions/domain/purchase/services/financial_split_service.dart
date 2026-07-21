class FinancialSplitService {
  const FinancialSplitService._();

  static const String purchaseForSelf = 'self';
  static const String purchaseForPartner = 'partner';
  static const String purchaseForBoth = 'both';

  static const String splitTypeNone = 'none';
  static const String splitTypeEqual = 'equal';
  static const String splitTypeCustom = 'custom';

  /// Calcula automaticamente quanto da transação pertence
  /// a cada membro da carteira.
  ///
  /// [value] é o valor total da transação.
  /// [payerMemberId] é o identificador de quem realizou o pagamento.
  /// [partnerMemberId] é o identificador do outro membro da carteira.
  /// [purchaseFor] aceita:
  /// - self;
  /// - partner;
  /// - both.
  static Map<String, double> calculateAutomaticShares({
    required double value,
    required String payerMemberId,
    String? partnerMemberId,
    required String purchaseFor,
  }) {
    _validateValue(value);
    _validateMemberId(payerMemberId, fieldName: 'payerMemberId');
    _validatePurchaseFor(purchaseFor);

    switch (purchaseFor) {
      case purchaseForSelf:
        return {
          payerMemberId: value,
        };

      case purchaseForPartner:
        final partnerId = _requirePartnerMemberId(
          payerMemberId: payerMemberId,
          partnerMemberId: partnerMemberId,
        );

        return {
          partnerId: value,
        };

      case purchaseForBoth:
        final partnerId = _requirePartnerMemberId(
          payerMemberId: payerMemberId,
          partnerMemberId: partnerMemberId,
        );

        final payerShare = _roundCurrency(value / 2);
        final partnerShare = _roundCurrency(value - payerShare);

        return {
          payerMemberId: payerShare,
          partnerId: partnerShare,
        };

      default:
        throw ArgumentError.value(
          purchaseFor,
          'purchaseFor',
          'Destino da compra inválido.',
        );
    }
  }

  /// Retorna o tipo de divisão correspondente ao destino da compra.
  ///
  /// Compras destinadas apenas a uma pessoa não precisam
  /// de divisão financeira.
  ///
  /// Compras destinadas aos dois membros usam divisão igualitária.
  static String splitTypeForPurchase(String purchaseFor) {
    _validatePurchaseFor(purchaseFor);

    if (purchaseFor == purchaseForBoth) {
      return splitTypeEqual;
    }

    return splitTypeNone;
  }

  /// Valida uma divisão personalizada.
  ///
  /// O método confirma se:
  /// - existem membros na divisão;
  /// - os identificadores são válidos;
  /// - nenhum valor é negativo;
  /// - a soma das partes corresponde ao total da transação.
  static bool isValidCustomSplit({
    required double transactionValue,
    required Map<String, double> memberShares,
  }) {
    if (transactionValue < 0 || memberShares.isEmpty) {
      return false;
    }

    var totalShares = 0.0;

    for (final entry in memberShares.entries) {
      if (entry.key.trim().isEmpty || entry.value < 0) {
        return false;
      }

      totalShares += entry.value;
    }

    return _roundCurrency(totalShares) ==
        _roundCurrency(transactionValue);
  }

  /// Retorna quanto um membro deve ao pagador.
  ///
  /// Caso o próprio membro seja o pagador, o valor devido é zero.
  static double amountOwedToPayer({
    required String memberId,
    required String payerMemberId,
    required Map<String, double> memberShares,
  }) {
    if (memberId == payerMemberId) {
      return 0;
    }

    return _roundCurrency(memberShares[memberId] ?? 0);
  }

  /// Retorna quanto o pagador desembolsou em benefício
  /// dos outros membros.
  static double amountPaidForOthers({
    required String payerMemberId,
    required Map<String, double> memberShares,
  }) {
    var total = 0.0;

    for (final entry in memberShares.entries) {
      if (entry.key != payerMemberId) {
        total += entry.value;
      }
    }

    return _roundCurrency(total);
  }

  /// Retorna a parte da transação atribuída a um membro.
  static double shareForMember({
    required String memberId,
    required Map<String, double> memberShares,
  }) {
    return _roundCurrency(memberShares[memberId] ?? 0);
  }

  static String _requirePartnerMemberId({
    required String payerMemberId,
    required String? partnerMemberId,
  }) {
    final partnerId = partnerMemberId?.trim() ?? '';

    if (partnerId.isEmpty) {
      throw ArgumentError(
        'O membro parceiro é obrigatório para esta divisão.',
      );
    }

    if (partnerId == payerMemberId) {
      throw ArgumentError(
        'O pagador e o parceiro não podem ser o mesmo membro.',
      );
    }

    return partnerId;
  }

  static void _validateValue(double value) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(
        value,
        'value',
        'O valor da transação deve ser válido e não negativo.',
      );
    }
  }

  static void _validateMemberId(
    String memberId, {
    required String fieldName,
  }) {
    if (memberId.trim().isEmpty) {
      throw ArgumentError.value(
        memberId,
        fieldName,
        'O identificador do membro não pode estar vazio.',
      );
    }
  }

  static void _validatePurchaseFor(String purchaseFor) {
    const validValues = {
      purchaseForSelf,
      purchaseForPartner,
      purchaseForBoth,
    };

    if (!validValues.contains(purchaseFor)) {
      throw ArgumentError.value(
        purchaseFor,
        'purchaseFor',
        'Use self, partner ou both.',
      );
    }
  }

  static double _roundCurrency(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}