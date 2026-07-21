class FinancialSplitRules {
  const FinancialSplitRules._();

  static const String purchaseForSelf = 'self';
  static const String purchaseForPartner = 'partner';
  static const String purchaseForBoth = 'both';

  static const String splitTypeNone = 'none';
  static const String splitTypeEqual = 'equal';
  static const String splitTypeCustom = 'custom';

  static const Set<String> validPurchaseDestinations = {
    purchaseForSelf,
    purchaseForPartner,
    purchaseForBoth,
  };

  static const Set<String> validSplitTypes = {
    splitTypeNone,
    splitTypeEqual,
    splitTypeCustom,
  };

  /// Retorna se o destino da compra é reconhecido pelo domínio.
  static bool isValidPurchaseDestination(String purchaseFor) {
    return validPurchaseDestinations.contains(purchaseFor);
  }

  /// Retorna se o tipo de divisão é reconhecido pelo domínio.
  static bool isValidSplitType(String splitType) {
    return validSplitTypes.contains(splitType);
  }

  /// Determina o tipo de divisão automática correspondente
  /// ao destino da compra.
  ///
  /// Compras destinadas somente a uma pessoa não precisam
  /// de divisão entre membros.
  ///
  /// Compras destinadas aos dois membros usam, por padrão,
  /// uma divisão igualitária.
  static String automaticSplitTypeForPurchase(String purchaseFor) {
    if (!isValidPurchaseDestination(purchaseFor)) {
      throw ArgumentError.value(
        purchaseFor,
        'purchaseFor',
        'Use self, partner ou both.',
      );
    }

    if (purchaseFor == purchaseForBoth) {
      return splitTypeEqual;
    }

    return splitTypeNone;
  }

  /// Indica se o destino da compra exige a existência
  /// de um segundo membro na carteira.
  static bool requiresPartner(String purchaseFor) {
    if (!isValidPurchaseDestination(purchaseFor)) {
      throw ArgumentError.value(
        purchaseFor,
        'purchaseFor',
        'Use self, partner ou both.',
      );
    }

    return purchaseFor == purchaseForPartner ||
        purchaseFor == purchaseForBoth;
  }

  /// Indica se o tipo de divisão depende de valores
  /// informados manualmente para cada membro.
  static bool requiresCustomShares(String splitType) {
    if (!isValidSplitType(splitType)) {
      throw ArgumentError.value(
        splitType,
        'splitType',
        'Use none, equal ou custom.',
      );
    }

    return splitType == splitTypeCustom;
  }

  /// Indica se uma divisão representa responsabilidade
  /// financeira compartilhada entre membros.
  static bool isSharedFinancialResponsibility(String splitType) {
    if (!isValidSplitType(splitType)) {
      throw ArgumentError.value(
        splitType,
        'splitType',
        'Use none, equal ou custom.',
      );
    }

    return splitType == splitTypeEqual ||
        splitType == splitTypeCustom;
  }
}