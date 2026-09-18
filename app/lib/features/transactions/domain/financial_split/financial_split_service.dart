import 'financial_split_result.dart';
import 'financial_split_rules.dart';
import 'financial_split_validator.dart';

class FinancialSplitService {
  const FinancialSplitService();

  /// Resolve a divisão financeira sem acoplar a responsabilidade ao destino
  /// de consumo. `purchaseFor` informa quem consumiu; `splitType` informa
  /// quem assume financeiramente o valor.
  FinancialSplitResult calculateSplit({
    required double value,
    required String payerMemberId,
    String? partnerMemberId,
    required String purchaseFor,
    required String splitType,
    Map<String, double>? customMemberShares,
  }) {
    FinancialSplitValidator.validateTransactionValue(value);
    FinancialSplitValidator.validateMemberId(
      payerMemberId,
      fieldName: 'payerMemberId',
    );
    FinancialSplitValidator.validatePurchaseFor(purchaseFor);

    if (!FinancialSplitRules.isValidSplitType(splitType)) {
      throw ArgumentError.value(
        splitType,
        'splitType',
        'Use none, equal ou custom.',
      );
    }

    switch (splitType) {
      case FinancialSplitRules.splitTypeNone:
        return calculateNoSplit(
          value: value,
          payerMemberId: payerMemberId,
          purchaseFor: purchaseFor,
        );
      case FinancialSplitRules.splitTypeEqual:
        return calculateEqualSplit(
          value: value,
          payerMemberId: payerMemberId,
          partnerMemberId: partnerMemberId,
          purchaseFor: purchaseFor,
        );
      case FinancialSplitRules.splitTypeCustom:
        if (customMemberShares == null) {
          throw ArgumentError(
            'A divisão personalizada precisa informar os valores de cada membro.',
          );
        }
        return calculateCustomSplit(
          value: value,
          payerMemberId: payerMemberId,
          purchaseFor: purchaseFor,
          memberShares: customMemberShares,
        );
      default:
        throw StateError('Tipo de divisão não reconhecido.');
    }
  }

  FinancialSplitResult calculateNoSplit({
    required double value,
    required String payerMemberId,
    required String purchaseFor,
  }) {
    FinancialSplitValidator.validateTransactionValue(value);
    FinancialSplitValidator.validateMemberId(
      payerMemberId,
      fieldName: 'payerMemberId',
    );
    FinancialSplitValidator.validatePurchaseFor(purchaseFor);

    final payerId = payerMemberId.trim();
    return FinancialSplitResult(
      payerMemberId: payerId,
      purchaseFor: purchaseFor,
      splitType: FinancialSplitRules.splitTypeNone,
      memberShares: {payerId: value},
    );
  }

  FinancialSplitResult calculateEqualSplit({
    required double value,
    required String payerMemberId,
    required String? partnerMemberId,
    required String purchaseFor,
  }) {
    FinancialSplitValidator.validateTransactionValue(value);
    FinancialSplitValidator.validateMemberId(
      payerMemberId,
      fieldName: 'payerMemberId',
    );
    FinancialSplitValidator.validatePurchaseFor(purchaseFor);

    final payerId = payerMemberId.trim();
    final partnerId = FinancialSplitValidator.requirePartnerMemberId(
      payerMemberId: payerId,
      partnerMemberId: partnerMemberId,
    );
    final payerShare = _roundCurrency(value / 2);
    final partnerShare = _roundCurrency(value - payerShare);

    return FinancialSplitResult(
      payerMemberId: payerId,
      purchaseFor: purchaseFor,
      splitType: FinancialSplitRules.splitTypeEqual,
      memberShares: {
        payerId: payerShare,
        partnerId: partnerShare,
      },
    );
  }

  /// Mantido para compatibilidade com chamadas existentes.
  FinancialSplitResult calculateAutomaticSplit({
    required double value,
    required String payerMemberId,
    String? partnerMemberId,
    required String purchaseFor,
  }) {
    final splitType = FinancialSplitRules.automaticSplitTypeForPurchase(
      purchaseFor,
    );
    return calculateSplit(
      value: value,
      payerMemberId: payerMemberId,
      partnerMemberId: partnerMemberId,
      purchaseFor: purchaseFor,
      splitType: splitType,
    );
  }

  FinancialSplitResult calculateCustomSplit({
    required double value,
    required String payerMemberId,
    required String purchaseFor,
    required Map<String, double> memberShares,
  }) {
    FinancialSplitValidator.validateTransactionValue(value);
    FinancialSplitValidator.validateMemberId(
      payerMemberId,
      fieldName: 'payerMemberId',
    );
    FinancialSplitValidator.validatePurchaseFor(purchaseFor);
    FinancialSplitValidator.validateCustomSplit(
      transactionValue: value,
      memberShares: memberShares,
    );

    final normalizedShares = <String, double>{};
    for (final entry in memberShares.entries) {
      normalizedShares[entry.key.trim()] = entry.value;
    }

    final normalizedPayerMemberId = payerMemberId.trim();
    if (!normalizedShares.containsKey(normalizedPayerMemberId)) {
      throw ArgumentError(
        'O pagador precisa fazer parte da divisão financeira.',
      );
    }

    return FinancialSplitResult(
      payerMemberId: normalizedPayerMemberId,
      purchaseFor: purchaseFor,
      splitType: FinancialSplitRules.splitTypeCustom,
      memberShares: normalizedShares,
    );
  }

  double _roundCurrency(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
