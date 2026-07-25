import '../../../transactions/domain/financial_split/financial_split_rules.dart';

class FinancialSplitEngine {
  const FinancialSplitEngine();

  FinancialSplitDecision resolve({
    required bool isSharedWallet,
    required String currentUserMemberId,
    required String paidByMemberId,
    required String purchaseDestination,
    required String splitType,
    String? partnerMemberId,
    Map<String, double>? customShares,
  }) {
    final normalizedCurrentUserMemberId =
        _normalizeRequiredMemberId(
          currentUserMemberId,
          fieldName: 'currentUserMemberId',
        );

    final normalizedPaidByMemberId =
        _normalizeRequiredMemberId(
          paidByMemberId,
          fieldName: 'paidByMemberId',
        );

    final normalizedPartnerMemberId =
        _normalizeOptionalMemberId(partnerMemberId);

    _validateWalletContext(
      isSharedWallet: isSharedWallet,
      currentUserMemberId: normalizedCurrentUserMemberId,
      partnerMemberId: normalizedPartnerMemberId,
    );

    _validatePayer(
      isSharedWallet: isSharedWallet,
      currentUserMemberId: normalizedCurrentUserMemberId,
      partnerMemberId: normalizedPartnerMemberId,
      paidByMemberId: normalizedPaidByMemberId,
    );

    final normalizedPurchaseDestination =
        purchaseDestination.trim();

    final normalizedSplitType = splitType.trim();

    if (!isSharedWallet ||
        normalizedPartnerMemberId == null) {
      return FinancialSplitDecision(
        paidByMemberId: normalizedPaidByMemberId,
        consumerId: normalizedCurrentUserMemberId,
        purchaseDestination:
            FinancialSplitRules.purchaseForSelf,
        splitType: FinancialSplitRules.splitTypeNone,
        memberShares: {
          normalizedCurrentUserMemberId: 1,
        },
      );
    }

    final consumerId = _resolveConsumerId(
      currentUserMemberId: normalizedCurrentUserMemberId,
      partnerMemberId: normalizedPartnerMemberId,
      purchaseDestination:
          normalizedPurchaseDestination,
    );

    final memberShares = _resolveMemberShares(
      currentUserMemberId: normalizedCurrentUserMemberId,
      partnerMemberId: normalizedPartnerMemberId,
      purchaseDestination:
          normalizedPurchaseDestination,
      splitType: normalizedSplitType,
      customShares: customShares,
    );

    return FinancialSplitDecision(
      paidByMemberId: normalizedPaidByMemberId,
      consumerId: consumerId,
      purchaseDestination:
          normalizedPurchaseDestination,
      splitType: normalizedSplitType,
      memberShares: memberShares,
    );
  }

  void _validateWalletContext({
    required bool isSharedWallet,
    required String currentUserMemberId,
    required String? partnerMemberId,
  }) {
    if (!isSharedWallet) {
      return;
    }

    if (partnerMemberId == null) {
      throw ArgumentError(
        'Uma carteira compartilhada precisa possuir um parceiro válido.',
      );
    }

    if (partnerMemberId == currentUserMemberId) {
      throw ArgumentError(
        'O parceiro não pode ser o mesmo membro do usuário atual.',
      );
    }
  }

  void _validatePayer({
    required bool isSharedWallet,
    required String currentUserMemberId,
    required String? partnerMemberId,
    required String paidByMemberId,
  }) {
    if (!isSharedWallet) {
      if (paidByMemberId != currentUserMemberId) {
        throw ArgumentError(
          'Em uma carteira individual, o pagador precisa ser o usuário atual.',
        );
      }

      return;
    }

    final isCurrentUser = paidByMemberId ==
        currentUserMemberId;

    final isPartner = partnerMemberId != null &&
        paidByMemberId == partnerMemberId;

    if (!isCurrentUser && !isPartner) {
      throw ArgumentError(
        'O pagador precisa pertencer à carteira compartilhada.',
      );
    }
  }

  String? _resolveConsumerId({
    required String currentUserMemberId,
    required String partnerMemberId,
    required String purchaseDestination,
  }) {
    switch (purchaseDestination) {
      case FinancialSplitRules.purchaseForSelf:
        return currentUserMemberId;

      case FinancialSplitRules.purchaseForPartner:
        return partnerMemberId;

      case FinancialSplitRules.purchaseForBoth:
        return null;

      default:
        throw ArgumentError.value(
          purchaseDestination,
          'purchaseDestination',
          'Destino da compra inválido.',
        );
    }
  }

  Map<String, double> _resolveMemberShares({
    required String currentUserMemberId,
    required String partnerMemberId,
    required String purchaseDestination,
    required String splitType,
    required Map<String, double>? customShares,
  }) {
    switch (purchaseDestination) {
      case FinancialSplitRules.purchaseForSelf:
        _validateSingleConsumerSplit(splitType);

        return Map<String, double>.unmodifiable({
          currentUserMemberId: 1,
          partnerMemberId: 0,
        });

      case FinancialSplitRules.purchaseForPartner:
        _validateSingleConsumerSplit(splitType);

        return Map<String, double>.unmodifiable({
          currentUserMemberId: 0,
          partnerMemberId: 1,
        });

      case FinancialSplitRules.purchaseForBoth:
        return _resolveSharedPurchaseShares(
          currentUserMemberId:
              currentUserMemberId,
          partnerMemberId: partnerMemberId,
          splitType: splitType,
          customShares: customShares,
        );

      default:
        throw ArgumentError.value(
          purchaseDestination,
          'purchaseDestination',
          'Destino da compra inválido.',
        );
    }
  }

  void _validateSingleConsumerSplit(String splitType) {
    if (splitType != FinancialSplitRules.splitTypeNone) {
      throw ArgumentError(
        'Compras destinadas a apenas uma pessoa não podem possuir divisão financeira.',
      );
    }
  }

  Map<String, double> _resolveSharedPurchaseShares({
    required String currentUserMemberId,
    required String partnerMemberId,
    required String splitType,
    required Map<String, double>? customShares,
  }) {
    switch (splitType) {
      case FinancialSplitRules.splitTypeEqual:
        return Map<String, double>.unmodifiable({
          currentUserMemberId: 0.5,
          partnerMemberId: 0.5,
        });

      case FinancialSplitRules.splitTypeCustom:
        return _validateAndNormalizeCustomShares(
          currentUserMemberId:
              currentUserMemberId,
          partnerMemberId: partnerMemberId,
          customShares: customShares,
        );

      case FinancialSplitRules.splitTypeNone:
        throw ArgumentError(
          'Uma compra destinada aos dois membros precisa possuir um tipo de divisão.',
        );

      default:
        throw ArgumentError.value(
          splitType,
          'splitType',
          'Tipo de divisão financeira inválido.',
        );
    }
  }

  Map<String, double> _validateAndNormalizeCustomShares({
    required String currentUserMemberId,
    required String partnerMemberId,
    required Map<String, double>? customShares,
  }) {
    if (customShares == null) {
      throw ArgumentError(
        'A divisão personalizada precisa informar a participação de cada membro.',
      );
    }

    final currentUserShare =
        customShares[currentUserMemberId];

    final partnerShare = customShares[partnerMemberId];

    if (currentUserShare == null ||
        partnerShare == null) {
      throw ArgumentError(
        'A divisão personalizada precisa incluir os dois membros da carteira.',
      );
    }

    if (!currentUserShare.isFinite ||
        !partnerShare.isFinite) {
      throw ArgumentError(
        'As participações da divisão personalizada precisam ser números válidos.',
      );
    }

    if (currentUserShare < 0 ||
        partnerShare < 0) {
      throw ArgumentError(
        'As participações da divisão personalizada não podem ser negativas.',
      );
    }

    final totalShare =
        currentUserShare + partnerShare;

    const tolerance = 0.000001;

    if ((totalShare - 1).abs() > tolerance) {
      throw ArgumentError(
        'A soma das participações da divisão personalizada precisa ser igual a 1.',
      );
    }

    return Map<String, double>.unmodifiable({
      currentUserMemberId: currentUserShare,
      partnerMemberId: partnerShare,
    });
  }

  String _normalizeRequiredMemberId(
    String memberId, {
    required String fieldName,
  }) {
    final normalizedMemberId = memberId.trim();

    if (normalizedMemberId.isEmpty) {
      throw ArgumentError.value(
        memberId,
        fieldName,
        'O ID do membro não pode ficar vazio.',
      );
    }

    return normalizedMemberId;
  }

  String? _normalizeOptionalMemberId(
    String? memberId,
  ) {
    final normalizedMemberId = memberId?.trim();

    if (normalizedMemberId == null ||
        normalizedMemberId.isEmpty) {
      return null;
    }

    return normalizedMemberId;
  }
}

class FinancialSplitDecision {
  FinancialSplitDecision({
    required this.paidByMemberId,
    required this.consumerId,
    required this.purchaseDestination,
    required this.splitType,
    required Map<String, double> memberShares,
  }) : memberShares =
           Map<String, double>.unmodifiable(
             memberShares,
           );

  final String paidByMemberId;

  /// Identifica o único consumidor quando a compra
  /// pertence apenas a uma pessoa.
  ///
  /// É null quando a compra pertence aos dois membros.
  final String? consumerId;

  final String purchaseDestination;
  final String splitType;

  /// Participação financeira de cada membro.
  ///
  /// Os valores são proporcionais:
  /// 1 representa 100%;
  /// 0.5 representa 50%.
  final Map<String, double> memberShares;

  bool get isSharedBetweenMembers =>
      consumerId == null &&
      memberShares.values
          .where((share) => share > 0)
          .length >
          1;

  double shareForMember(String memberId) {
    return memberShares[memberId.trim()] ?? 0;
  }
}