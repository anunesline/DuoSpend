import '../../../home/data/models/wallet_model.dart';
import '../../../home/data/repositories/wallet_repository.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/financial_split/financial_split_result.dart';
import '../../domain/financial_split/financial_split_rules.dart';
import '../../domain/financial_split/financial_split_service.dart';
import '../../domain/purchase/services/balance_settlement_synchronizer.dart';
import '../../domain/services/shared_transaction_confirmation_service.dart';

class CreateTransactionResult {
  final TransactionModel transaction;
  final WalletModel transactionWallet;
  final WalletModel financialWallet;
  final FinancialSplitResult financialSplit;

  const CreateTransactionResult({
    required this.transaction,
    required this.transactionWallet,
    required this.financialWallet,
    required this.financialSplit,
  });
}

class CreateTransactionUseCase {
  final TransactionRepository _transactionRepository;
  final WalletRepository _walletRepository;
  final FinancialSplitService _financialSplitService;
  final BalanceSettlementSynchronizer _settlementSynchronizer;
  final SharedTransactionConfirmationService
      _confirmationService;

  const CreateTransactionUseCase({
    required TransactionRepository transactionRepository,
    required WalletRepository walletRepository,
    required FinancialSplitService financialSplitService,
    required BalanceSettlementSynchronizer settlementSynchronizer,
    SharedTransactionConfirmationService confirmationService =
        const SharedTransactionConfirmationService(),
  })  : _transactionRepository = transactionRepository,
        _walletRepository = walletRepository,
        _financialSplitService = financialSplitService,
        _settlementSynchronizer = settlementSynchronizer,
        _confirmationService = confirmationService;

  Future<CreateTransactionResult> call({
    required String transactionId,
    required String description,
    required double value,
    required String type,
    required String walletId,
    required String category,
    required String subcategory,
    required String paidByMemberId,
    required String purchaseFor,
    required String? partnerMemberId,
    required List<TransactionItemModel> items,
    String? consumerId,
    String? splitType,
    Map<String, double>? customMemberShares,
    WalletModel? wallet,
  }) async {
    final normalizedTransactionId = transactionId.trim();
    final normalizedDescription = description.trim();
    final normalizedWalletId = walletId.trim();
    final normalizedCategory = category.trim();
    final normalizedSubcategory = subcategory.trim();
    final normalizedPaidByMemberId = paidByMemberId.trim();
    final normalizedConsumerId = consumerId?.trim();

    _validateInput(
      transactionId: normalizedTransactionId,
      description: normalizedDescription,
      value: value,
      type: type,
      walletId: normalizedWalletId,
      category: normalizedCategory,
      subcategory: normalizedSubcategory,
      paidByMemberId: normalizedPaidByMemberId,
    );

    final transactionWallet = await _resolveTransactionWallet(
      walletId: normalizedWalletId,
      wallet: wallet,
    );

    final financialWallet = await _resolveFinancialWallet(
      paidByMemberId: normalizedPaidByMemberId,
    );

    final resolvedSplitType = splitType ??
        FinancialSplitRules.automaticSplitTypeForPurchase(
          purchaseFor,
        );

    final financialSplit = _financialSplitService.calculateSplit(
      value: value,
      payerMemberId: normalizedPaidByMemberId,
      partnerMemberId: partnerMemberId,
      purchaseFor: purchaseFor,
      splitType: resolvedSplitType,
      customMemberShares: customMemberShares,
    );

    final hasFinancialSplit =
        financialSplit.splitType != 'none' &&
            financialSplit.memberShares.isNotEmpty;

    final confirmationDecision = _confirmationService.resolve(
      wallet: transactionWallet,
      transactionType: type,
      hasFinancialSplit: hasFinancialSplit,
      isSettlement: false,
    );

    final transaction = TransactionModel(
      id: normalizedTransactionId,
      description: normalizedDescription,
      value: value,
      type: type,
      date: DateTime.now(),
      walletId: transactionWallet.id,
      consumerId:
          normalizedConsumerId == null ||
                  normalizedConsumerId.isEmpty
              ? null
              : normalizedConsumerId,
      category: normalizedCategory,
      subcategory: normalizedSubcategory,
      paidByMemberId: normalizedPaidByMemberId,
      purchaseFor: financialSplit.purchaseFor,
      splitType: financialSplit.splitType,
      memberShares: financialSplit.memberShares,
      confirmationStatus: confirmationDecision.status,
      confirmationRequestedAt:
          confirmationDecision.requestedAt,
      items: items
          .map(
            (item) => item.copyWith(
              transactionId: normalizedTransactionId,
            ),
          )
          .toList(),
    );

    await _transactionRepository.addTransaction(
      transaction,
      wallet: transactionWallet,
    );

    await _updateFinancialWalletBalance(
      wallet: financialWallet,
      transactionType: type,
      transactionValue: value,
    );

    if (transactionWallet.isShared &&
        confirmationDecision.shouldSynchronizeSettlement) {
      await _settlementSynchronizer.synchronize(
        walletId: transactionWallet.id,
      );
    }

    return CreateTransactionResult(
      transaction: transaction,
      transactionWallet: transactionWallet,
      financialWallet: financialWallet,
      financialSplit: financialSplit,
    );
  }

  Future<WalletModel> _resolveTransactionWallet({
    required String walletId,
    required WalletModel? wallet,
  }) async {
    final resolvedWallet =
        wallet ??
        await _walletRepository.getWalletById(
          walletId,
        );

    if (resolvedWallet == null) {
      throw Exception(
        'Não foi possível localizar a carteira da transação.',
      );
    }

    if (resolvedWallet.id.trim() != walletId) {
      throw Exception(
        'A carteira informada não corresponde ao walletId da transação.',
      );
    }

    return resolvedWallet;
  }

  Future<WalletModel> _resolveFinancialWallet({
    required String paidByMemberId,
  }) async {
    final financialWallet =
        await _walletRepository.getFinancialWalletForMember(
          paidByMemberId,
        );

    if (financialWallet == null) {
      throw Exception(
        'Não foi possível localizar a carteira financeira do pagador.',
      );
    }

    if (!financialWallet.isIndividual) {
      throw Exception(
        'A origem financeira da transação precisa ser uma carteira individual.',
      );
    }

    return financialWallet;
  }

  Future<void> _updateFinancialWalletBalance({
    required WalletModel wallet,
    required String transactionType,
    required double transactionValue,
  }) async {
    if (transactionType == 'income') {
      await _walletRepository.incrementBalance(
        transactionValue,
        walletId: wallet.id,
      );

      return;
    }

    if (transactionType == 'expense') {
      await _walletRepository.decrementBalance(
        transactionValue,
        walletId: wallet.id,
      );

      return;
    }

    throw Exception(
      'Tipo de transação inválido: $transactionType.',
    );
  }

  void _validateInput({
    required String transactionId,
    required String description,
    required double value,
    required String type,
    required String walletId,
    required String category,
    required String subcategory,
    required String paidByMemberId,
  }) {
    if (transactionId.isEmpty) {
      throw Exception('A transação precisa ter um ID.');
    }

    if (description.isEmpty) {
      throw Exception('Informe a descrição da transação.');
    }

    if (value <= 0) {
      throw Exception(
        'O valor da transação deve ser maior que zero.',
      );
    }

    if (type != 'income' && type != 'expense') {
      throw Exception(
        'Tipo de transação inválido: $type.',
      );
    }

    if (walletId.isEmpty) {
      throw Exception(
        'Carteira da transação não informada.',
      );
    }

    if (category.isEmpty) {
      throw Exception(
        'Categoria financeira não informada.',
      );
    }

    if (subcategory.isEmpty) {
      throw Exception(
        'Subcategoria financeira não informada.',
      );
    }

    if (paidByMemberId.isEmpty) {
      throw Exception(
        'Pagador da transação não informado.',
      );
    }
  }
}