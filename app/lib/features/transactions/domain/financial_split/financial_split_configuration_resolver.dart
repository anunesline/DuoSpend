import 'financial_split_configuration.dart';
import 'financial_split_rules.dart';

class FinancialSplitConfigurationResolver {
  const FinancialSplitConfigurationResolver();

  FinancialSplitConfiguration resolveFromMembers({
    required bool isSharedWallet,
    required String currentUserMemberId,
    required Iterable<String> walletMemberIds,
  }) {
    final normalizedCurrentUserMemberId =
        currentUserMemberId.trim();

    final partnerMemberId = _resolvePartnerMemberId(
      isSharedWallet: isSharedWallet,
      currentUserMemberId:
          normalizedCurrentUserMemberId,
      walletMemberIds: walletMemberIds,
    );

    return resolve(
      isSharedWallet: isSharedWallet,
      currentUserMemberId:
          normalizedCurrentUserMemberId,
      partnerMemberId: partnerMemberId,
    );
  }

  FinancialSplitConfiguration resolve({
    // Mantido por compatibilidade com os chamadores atuais.
    // A disponibilidade da divisão não depende mais da carteira
    // atualmente selecionada, e sim da existência de parceiro válido.
    required bool isSharedWallet,
    required String currentUserMemberId,
    required String? partnerMemberId,
  }) {
    final normalizedCurrentUserMemberId =
        currentUserMemberId.trim();

    // O contexto da carteira continua chegando ao resolver porque
    // ainda é útil para os fluxos atuais, mas não bloqueia a divisão.
    final _ = isSharedWallet;

    final normalizedPartnerMemberId =
        partnerMemberId?.trim();

    final hasValidPartner =
        normalizedPartnerMemberId != null &&
        normalizedPartnerMemberId.isNotEmpty &&
        normalizedPartnerMemberId !=
            normalizedCurrentUserMemberId;

    if (!hasValidPartner) {
      return FinancialSplitConfiguration(
        isFinancialSplitAvailable: false,
        hasPartner: false,
        currentUserMemberId:
            normalizedCurrentUserMemberId,
        partnerMemberId: null,
        allowedPayerMemberIds: [
          normalizedCurrentUserMemberId,
        ],
        allowedPurchaseDestinations: [
          FinancialSplitRules.purchaseForSelf,
        ],
        allowedSplitTypes: [
          FinancialSplitRules.splitTypeNone,
        ],
        defaultPayerMemberId:
            normalizedCurrentUserMemberId,
        defaultPurchaseDestination:
            FinancialSplitRules.purchaseForSelf,
        defaultSplitType:
            FinancialSplitRules.splitTypeNone,
      );
    }

    return FinancialSplitConfiguration(
      isFinancialSplitAvailable: true,
      hasPartner: true,
      currentUserMemberId:
          normalizedCurrentUserMemberId,
      partnerMemberId:
          normalizedPartnerMemberId,
      allowedPayerMemberIds: [
        normalizedCurrentUserMemberId,
        normalizedPartnerMemberId,
      ],
      allowedPurchaseDestinations: [
        FinancialSplitRules.purchaseForSelf,
        FinancialSplitRules.purchaseForPartner,
        FinancialSplitRules.purchaseForBoth,
      ],
      allowedSplitTypes: [
        FinancialSplitRules.splitTypeNone,
        FinancialSplitRules.splitTypeEqual,
        FinancialSplitRules.splitTypeCustom,
      ],
      defaultPayerMemberId:
          normalizedCurrentUserMemberId,
      defaultPurchaseDestination:
          FinancialSplitRules.purchaseForSelf,
      defaultSplitType:
          FinancialSplitRules.splitTypeNone,
    );
  }

  String? _resolvePartnerMemberId({
    required bool isSharedWallet,
    required String currentUserMemberId,
    required Iterable<String> walletMemberIds,
  }) {
    if (!isSharedWallet) {
      return null;
    }

    for (final memberId in walletMemberIds) {
      final normalizedMemberId = memberId.trim();

      if (normalizedMemberId.isNotEmpty &&
          normalizedMemberId != currentUserMemberId) {
        return normalizedMemberId;
      }
    }

    return null;
  }
}