import 'financial_split_result.dart';
import 'financial_split_rules.dart';
import 'financial_split_validator.dart';

class FinancialSplitService {
  const FinancialSplitService();

  /// Resolve a divisão financeira conforme o tipo informado.
  ///
  /// Divisões `none` e `equal` são calculadas automaticamente
  /// a partir do destino da compra.
  ///
  /// Divisões `custom` exigem os valores monetários de cada
  /// membro em [customMemberShares].
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

    final expectedAutomaticSplitType =
        FinancialSplitRules.automaticSplitTypeForPurchase(
      purchaseFor,
    );

    if (splitType == FinancialSplitRules.splitTypeCustom) {
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
    }

    if (splitType != expectedAutomaticSplitType) {
      throw ArgumentError(
        'O tipo de divisão não corresponde ao destino da compra.',
      );
    }

    return calculateAutomaticSplit(
      value: value,
      payerMemberId: payerMemberId,
      partnerMemberId: partnerMemberId,
      purchaseFor: purchaseFor,
    );
  }

  /// Calcula automaticamente a responsabilidade financeira
  /// de cada membro da carteira.
  ///
  /// O destino de consumo e a divisão financeira são tratados
  /// separadamente pelo domínio.
  FinancialSplitResult calculateAutomaticSplit({
    required double value,
    required String payerMemberId,
    String? partnerMemberId,
    required String purchaseFor,
  }) {
    FinancialSplitValidator.validateTransactionValue(value);

    FinancialSplitValidator.validateMemberId(
      payerMemberId,
      fieldName: 'payerMemberId',
    );

    FinancialSplitValidator.validatePurchaseFor(purchaseFor);

    final normalizedPayerMemberId = payerMemberId.trim();

    final memberShares = switch (purchaseFor) {
      FinancialSplitRules.purchaseForSelf => {
          normalizedPayerMemberId: value,
        },
      FinancialSplitRules.purchaseForPartner =>
        _calculatePartnerOnlyShares(
          value: value,
          payerMemberId: normalizedPayerMemberId,
          partnerMemberId: partnerMemberId,
        ),
      FinancialSplitRules.purchaseForBoth =>
        _calculateEqualShares(
          value: value,
          payerMemberId: normalizedPayerMemberId,
          partnerMemberId: partnerMemberId,
        ),
      _ => throw StateError(
          'Destino da compra não reconhecido pelo domínio.',
        ),
    };

    return FinancialSplitResult(
      payerMemberId: normalizedPayerMemberId,
      purchaseFor: purchaseFor,
      splitType:
          FinancialSplitRules.automaticSplitTypeForPurchase(
        purchaseFor,
      ),
      memberShares: memberShares,
    );
  }

  /// Cria um resultado de divisão personalizada.
  ///
  /// Este método não tenta corrigir ou redistribuir valores.
  /// A divisão informada deve corresponder exatamente ao valor
  /// total da transação.
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

  Map<String, double> _calculatePartnerOnlyShares({
    required double value,
    required String payerMemberId,
    required String? partnerMemberId,
  }) {
    final partnerId =
        FinancialSplitValidator.requirePartnerMemberId(
      payerMemberId: payerMemberId,
      partnerMemberId: partnerMemberId,
    );

    return {
      partnerId: value,
    };
  }

  Map<String, double> _calculateEqualShares({
    required double value,
    required String payerMemberId,
    required String? partnerMemberId,
  }) {
    final partnerId =
        FinancialSplitValidator.requirePartnerMemberId(
      payerMemberId: payerMemberId,
      partnerMemberId: partnerMemberId,
    );

    final payerShare = _roundCurrency(value / 2);
    final partnerShare = _roundCurrency(value - payerShare);

    return {
      payerMemberId: payerShare,
      partnerId: partnerShare,
    };
  }

  double _roundCurrency(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}