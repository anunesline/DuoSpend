import 'financial_split_rules.dart';

class FinancialSplitValidator {
  const FinancialSplitValidator._();

  /// Valida o valor total de uma transação.
  static void validateTransactionValue(double value) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(
        value,
        'value',
        'O valor da transação deve ser válido e não negativo.',
      );
    }
  }

  /// Valida um identificador de membro.
  static void validateMemberId(
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

  /// Valida o destino informado para a compra.
  static void validatePurchaseFor(String purchaseFor) {
    if (!FinancialSplitRules.isValidPurchaseDestination(
      purchaseFor,
    )) {
      throw ArgumentError.value(
        purchaseFor,
        'purchaseFor',
        'Use self, partner ou both.',
      );
    }
  }

  /// Valida o tipo de divisão financeira.
  static void validateSplitType(String splitType) {
    if (!FinancialSplitRules.isValidSplitType(splitType)) {
      throw ArgumentError.value(
        splitType,
        'splitType',
        'Use none, equal ou custom.',
      );
    }
  }

  /// Retorna o identificador normalizado do parceiro.
  ///
  /// Lança erro quando:
  /// - o parceiro não foi informado;
  /// - o parceiro possui o mesmo identificador do pagador.
  static String requirePartnerMemberId({
    required String payerMemberId,
    required String? partnerMemberId,
  }) {
    validateMemberId(
      payerMemberId,
      fieldName: 'payerMemberId',
    );

    final partnerId = partnerMemberId?.trim() ?? '';

    if (partnerId.isEmpty) {
      throw ArgumentError(
        'O membro parceiro é obrigatório para esta divisão.',
      );
    }

    if (partnerId == payerMemberId.trim()) {
      throw ArgumentError(
        'O pagador e o parceiro não podem ser o mesmo membro.',
      );
    }

    return partnerId;
  }

  /// Valida uma divisão personalizada.
  ///
  /// Confirma se:
  /// - o valor da transação é válido;
  /// - existem membros na divisão;
  /// - os identificadores são válidos;
  /// - os valores são finitos e não negativos;
  /// - não existem membros repetidos após normalização;
  /// - a soma das partes corresponde ao valor da transação.
  static bool isValidCustomSplit({
    required double transactionValue,
    required Map<String, double> memberShares,
  }) {
    if (!transactionValue.isFinite ||
        transactionValue < 0 ||
        memberShares.isEmpty) {
      return false;
    }

    final normalizedMemberIds = <String>{};
    var totalShares = 0.0;

    for (final entry in memberShares.entries) {
      final normalizedMemberId = entry.key.trim();
      final share = entry.value;

      if (normalizedMemberId.isEmpty ||
          !share.isFinite ||
          share < 0) {
        return false;
      }

      if (!normalizedMemberIds.add(normalizedMemberId)) {
        return false;
      }

      totalShares += share;
    }

    return _roundCurrency(totalShares) ==
        _roundCurrency(transactionValue);
  }

  /// Valida uma divisão personalizada e lança erro quando inválida.
  static void validateCustomSplit({
    required double transactionValue,
    required Map<String, double> memberShares,
  }) {
    if (!isValidCustomSplit(
      transactionValue: transactionValue,
      memberShares: memberShares,
    )) {
      throw ArgumentError(
        'A divisão personalizada é inválida ou não corresponde '
        'ao valor total da transação.',
      );
    }
  }

  static double _roundCurrency(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}