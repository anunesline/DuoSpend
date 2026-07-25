import '../../../home/data/models/wallet_model.dart';
import '../../../home/data/repositories/wallet_repository.dart';
import '../../../merchants/data/merchant_memory_repository.dart';
import '../../../merchants/domain/merchant_model.dart';
import '../../../transactions/data/models/transaction_item_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../services/financial_split_engine.dart';
import '../services/financial_split_rules.dart';
import '../services/purchase_service.dart';

class SavePurchaseUseCase implements PurchaseService {
  SavePurchaseUseCase({
    TransactionRepository? transactionRepository,
    WalletRepository? walletRepository,
    MerchantMemoryRepository? merchantMemoryRepository,
    FinancialSplitEngine? financialSplitEngine,
  }) : _transactionRepository =
           transactionRepository ?? TransactionRepository(),
       _walletRepository =
           walletRepository ?? WalletRepository(),
       _merchantMemoryRepository =
           merchantMemoryRepository ??
           MerchantMemoryRepository(),
       _financialSplitEngine =
           financialSplitEngine ??
           const FinancialSplitEngine();

  final TransactionRepository _transactionRepository;
  final WalletRepository _walletRepository;
  final MerchantMemoryRepository
      _merchantMemoryRepository;
  final FinancialSplitEngine _financialSplitEngine;

  @override
  Future<void> savePurchase({
    required String walletId,
    String? consumerId,
    String? purchaseDestination,
    String? splitType,
    Map<String, double>? customShares,
    required MerchantModel merchant,
    required double totalValue,
    required String financialCategory,
    required String financialSubcategory,
    required List<TransactionItemModel> items,
  }) async {
    final normalizedWalletId = walletId.trim();
    final currentUserId =
        _walletRepository.currentUserId;

    if (normalizedWalletId.isEmpty) {
      throw Exception(
        'Carteira da compra não informada.',
      );
    }

    if (currentUserId == null ||
        currentUserId.trim().isEmpty) {
      throw Exception(
        'Usuário pagador não identificado.',
      );
    }

    if (!totalValue.isFinite || totalValue <= 0) {
      throw Exception(
        'O valor total da compra precisa ser maior que zero.',
      );
    }

    final normalizedCurrentUserId =
        currentUserId.trim();

    final transactionWallet =
        await _walletRepository.getWalletById(
          normalizedWalletId,
        );

    if (transactionWallet == null) {
      throw Exception(
        'Não foi possível localizar a carteira da compra.',
      );
    }

    if (transactionWallet.id.trim() !=
        normalizedWalletId) {
      throw Exception(
        'A carteira localizada não corresponde ao walletId da compra.',
      );
    }

    _validateWalletAccess(
      wallet: transactionWallet,
      currentUserId: normalizedCurrentUserId,
    );

    final payerWallet =
        await _walletRepository
            .getFinancialWalletForMember(
              normalizedCurrentUserId,
            );

    if (payerWallet == null) {
      throw Exception(
        'Não foi possível localizar a carteira financeira do pagador.',
      );
    }

    if (!payerWallet.isIndividual) {
      throw Exception(
        'A origem financeira da compra precisa ser uma carteira individual.',
      );
    }

    final partnerMemberId = _resolvePartnerMemberId(
      wallet: transactionWallet,
      currentUserId: normalizedCurrentUserId,
    );

    final resolvedPurchaseDestination =
        _resolvePurchaseDestination(
          isSharedWallet: transactionWallet.isShared,
          currentUserId: normalizedCurrentUserId,
          partnerMemberId: partnerMemberId,
          consumerId: consumerId,
          purchaseDestination:
              purchaseDestination,
        );

    final resolvedSplitType = _resolveSplitType(
      isSharedWallet: transactionWallet.isShared,
      purchaseDestination:
          resolvedPurchaseDestination,
      splitType: splitType,
    );

    final decision = _financialSplitEngine.resolve(
      isSharedWallet: transactionWallet.isShared,
      currentUserMemberId:
          normalizedCurrentUserId,
      paidByMemberId: normalizedCurrentUserId,
      partnerMemberId: partnerMemberId,
      purchaseDestination:
          resolvedPurchaseDestination,
      splitType: resolvedSplitType,
      customShares: customShares,
    );

    final monetaryMemberShares =
        _convertSharesToMonetaryValues(
          proportionalShares:
              decision.memberShares,
          totalValue: totalValue,
        );

    final transactionId =
        DateTime.now()
            .millisecondsSinceEpoch
            .toString();

    final transaction = TransactionModel(
      id: transactionId,
      description: merchant.name,
      value: totalValue,
      type: 'expense',
      date: DateTime.now(),
      walletId: transactionWallet.id,
      consumerId: decision.consumerId,
      paidByMemberId:
          decision.paidByMemberId,
      purchaseFor:
          decision.purchaseDestination,
      splitType: decision.splitType,
      memberShares: monetaryMemberShares,
      category: financialCategory,
      subcategory: financialSubcategory,
      items: items
          .map(
            (item) => item.copyWith(
              transactionId: transactionId,
            ),
          )
          .toList(),
    );

    await _transactionRepository.addTransaction(
      transaction,
      wallet: transactionWallet,
    );

    await _walletRepository.decrementBalance(
      totalValue,
      walletId: payerWallet.id,
    );

    await _merchantMemoryRepository
        .updateAfterPurchase(
          merchantId: merchant.id,
          merchantName: merchant.name,
          purchaseValue: totalValue,
          productNames: items
              .map((item) => item.name)
              .toList(),
        );
  }

  void _validateWalletAccess({
    required WalletModel wallet,
    required String currentUserId,
  }) {
    if (!wallet.isShared) {
      return;
    }

    if (!wallet.memberIds.contains(currentUserId)) {
      throw Exception(
        'O usuário não pertence à carteira compartilhada selecionada.',
      );
    }
  }

  String? _resolvePartnerMemberId({
    required WalletModel wallet,
    required String currentUserId,
  }) {
    if (!wallet.isShared) {
      return null;
    }

    for (final memberId in wallet.memberIds) {
      final normalizedMemberId = memberId.trim();

      if (normalizedMemberId.isNotEmpty &&
          normalizedMemberId != currentUserId) {
        return normalizedMemberId;
      }
    }

    return null;
  }

  String _resolvePurchaseDestination({
    required bool isSharedWallet,
    required String currentUserId,
    required String? partnerMemberId,
    required String? consumerId,
    required String? purchaseDestination,
  }) {
    if (!isSharedWallet) {
      return FinancialSplitRules.purchaseForSelf;
    }

    final normalizedPurchaseDestination =
        purchaseDestination?.trim();

    if (normalizedPurchaseDestination != null &&
        normalizedPurchaseDestination.isNotEmpty) {
      return normalizedPurchaseDestination;
    }

    final normalizedConsumerId =
        consumerId?.trim();

    if (normalizedConsumerId == null ||
        normalizedConsumerId.isEmpty) {
      return FinancialSplitRules.purchaseForBoth;
    }

    if (normalizedConsumerId == currentUserId) {
      return FinancialSplitRules.purchaseForSelf;
    }

    if (partnerMemberId != null &&
        normalizedConsumerId == partnerMemberId) {
      return FinancialSplitRules.purchaseForPartner;
    }

    throw Exception(
      'O consumidor informado não pertence à carteira selecionada.',
    );
  }

  String _resolveSplitType({
    required bool isSharedWallet,
    required String purchaseDestination,
    required String? splitType,
  }) {
    if (!isSharedWallet) {
      return FinancialSplitRules.splitTypeNone;
    }

    final normalizedSplitType = splitType?.trim();

    if (normalizedSplitType != null &&
        normalizedSplitType.isNotEmpty) {
      return normalizedSplitType;
    }

    if (purchaseDestination ==
        FinancialSplitRules.purchaseForBoth) {
      return FinancialSplitRules.splitTypeEqual;
    }

    return FinancialSplitRules.splitTypeNone;
  }

  Map<String, double>
      _convertSharesToMonetaryValues({
    required Map<String, double>
        proportionalShares,
    required double totalValue,
  }) {
    if (proportionalShares.isEmpty) {
      return const {};
    }

    final monetaryShares = <String, double>{};
    final entries =
        proportionalShares.entries.toList();

    var distributedValue = 0.0;

    for (var index = 0;
        index < entries.length;
        index++) {
      final entry = entries[index];
      final isLastEntry =
          index == entries.length - 1;

      final monetaryValue = isLastEntry
          ? totalValue - distributedValue
          : totalValue * entry.value;

      monetaryShares[entry.key] =
          monetaryValue;

      distributedValue += monetaryValue;
    }

    return Map<String, double>.unmodifiable(
      monetaryShares,
    );
  }
}