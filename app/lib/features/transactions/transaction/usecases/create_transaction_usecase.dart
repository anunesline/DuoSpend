import '../../../home/data/models/wallet_model.dart';
import '../../../home/data/repositories/credit_card_repository.dart';
import '../../../home/data/repositories/wallet_repository.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/financial_split/financial_split_result.dart';
import '../../domain/financial_split/financial_split_rules.dart';
import '../../domain/financial_split/financial_split_service.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/purchase/services/balance_settlement_synchronizer.dart';
import '../../domain/services/shared_transaction_confirmation_service.dart';
import '../../domain/services/recurring_transaction_service.dart';
import '../../domain/usecases/create_installment_transactions_usecase.dart';
import '../../domain/usecases/create_recurring_transaction_usecase.dart';

class CreateTransactionResult {
  final TransactionModel transaction;
  final WalletModel transactionWallet;
  final WalletModel financialWallet;
  final FinancialSplitResult financialSplit;
  final List<TransactionModel> transactions;

  const CreateTransactionResult({
    required this.transaction,
    required this.transactionWallet,
    required this.financialWallet,
    required this.financialSplit,
    this.transactions = const [],
  });
}

class CreateTransactionUseCase {
  final TransactionRepository _transactionRepository;
  final WalletRepository _walletRepository;
  final CreditCardRepository _creditCardRepository;
  final FinancialSplitService _financialSplitService;
  final BalanceSettlementSynchronizer _settlementSynchronizer;
  final SharedTransactionConfirmationService
      _confirmationService;
  final CreateRecurringTransactionUseCase?
      _createRecurringTransactionUseCase;
  final CreateInstallmentTransactionsUseCase
      _createInstallmentTransactionsUseCase;

  CreateTransactionUseCase({
    required TransactionRepository transactionRepository,
    required WalletRepository walletRepository,
    CreditCardRepository? creditCardRepository,
    required FinancialSplitService financialSplitService,
    required BalanceSettlementSynchronizer settlementSynchronizer,
    SharedTransactionConfirmationService confirmationService =
        const SharedTransactionConfirmationService(),
    CreateRecurringTransactionUseCase?
        createRecurringTransactionUseCase,
    CreateInstallmentTransactionsUseCase
        createInstallmentTransactionsUseCase =
            const CreateInstallmentTransactionsUseCase(),
  })  : _transactionRepository = transactionRepository,
        _walletRepository = walletRepository,
        _creditCardRepository =
            creditCardRepository ?? CreditCardRepository(),
        _financialSplitService = financialSplitService,
        _settlementSynchronizer = settlementSynchronizer,
        _confirmationService = confirmationService,
        _createRecurringTransactionUseCase =
            createRecurringTransactionUseCase,
        _createInstallmentTransactionsUseCase =
            createInstallmentTransactionsUseCase;

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
    bool isRecurring = false,
    String? recurringFrequency,
    DateTime? recurringStartDate,
    DateTime? recurringEndDate,
    bool recurringNeverEnds = true,
    bool isInstallment = false,
    int installmentCount = 2,
    DateTime? firstInstallmentDate,
    String? notes,
    PaymentMethod? paymentMethod,
    String? paymentSourceId,
    String? financialWalletId,
  }) async {
    final normalizedTransactionId = transactionId.trim();
    final normalizedDescription = description.trim();
    final normalizedWalletId = walletId.trim();
    final normalizedCategory = category.trim();
    final normalizedSubcategory = subcategory.trim();
    final normalizedPaidByMemberId = paidByMemberId.trim();
    final normalizedConsumerId = consumerId?.trim();
    final normalizedNotes = notes?.trim();
    final normalizedPaymentSourceId =
        paymentSourceId?.trim();
    final normalizedFinancialWalletId =
        financialWalletId?.trim();

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

    _validatePaymentConfiguration(
      paymentMethod: paymentMethod,
      paymentSourceId: normalizedPaymentSourceId,
    );

    if (isRecurring && isInstallment) {
      throw Exception(
        'Uma transação não pode ser recorrente e parcelada ao mesmo tempo.',
      );
    }

    final transactionWallet = await _resolveTransactionWallet(
      walletId: normalizedWalletId,
      wallet: wallet,
    );

    final financialWallet = await _resolveFinancialWallet(
      paidByMemberId: normalizedPaidByMemberId,
      financialWalletId: normalizedFinancialWalletId,
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

    final baseTransaction = TransactionModel(
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
      isRecurring: isRecurring,
      recurringFrequency: recurringFrequency,
      recurringStartDate: recurringStartDate,
      recurringEndDate: recurringEndDate,
      recurringNeverEnds: recurringNeverEnds,
      paymentMethod: paymentMethod?.value,
      paymentSourceId: _resolvePersistedPaymentSourceId(
        paymentSourceId: normalizedPaymentSourceId,
        financialWalletId: normalizedFinancialWalletId,
      ),
      notes: normalizedNotes == null || normalizedNotes.isEmpty
          ? null
          : normalizedNotes,
      items: items
          .map(
            (item) => item.copyWith(
              transactionId: normalizedTransactionId,
            ),
          )
          .toList(),
    );

    final recurringUseCase =
        _createRecurringTransactionUseCase ??
            CreateRecurringTransactionUseCase(
              recurringService:
                  const RecurringTransactionService(),
            );

    final generatedTransactions = isInstallment
        ? _createInstallmentTransactionsUseCase.execute(
            transaction: baseTransaction,
            installmentCount: installmentCount,
            firstInstallmentDate:
                firstInstallmentDate ?? DateTime.now(),
          )
        : <TransactionModel>[
            recurringUseCase.execute(baseTransaction),
          ];
    final transactionsWithShares = isInstallment
        ? _applyInstallmentShares(
            transactions: generatedTransactions,
            totalShares: financialSplit.memberShares,
          )
        : generatedTransactions;
    final transactions = _applyFinancialStatuses(
      transactions: transactionsWithShares,
      paymentMethod: paymentMethod,
    );
    final transaction = transactions.first;

    if (paymentMethod?.isCreditCard ?? false) {
      // Cada parcela é idempotente pelo próprio transactionId.
      // O limite total fica comprometido e cada parcela entra
      // na fatura correspondente à sua data.
      for (final installment in transactions) {
        await _creditCardRepository.registerPurchase(
          cardId: normalizedPaymentSourceId!,
          transactionModel: installment,
          transactionWallet: transactionWallet,
        );
      }
    } else {
      await _transactionRepository.addTransactions(
        transactions,
        wallet: transactionWallet,
      );
    }

    if (transaction.isFinanciallySettled) {
      await _applyImmediateFinancialImpact(
        paymentMethod: paymentMethod,
        financialWallet: financialWallet,
        transactionType: type,
        transactionValue: transaction.value,
      );
    }

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
      transactions: List<TransactionModel>.unmodifiable(transactions),
    );
  }

  List<TransactionModel> _applyFinancialStatuses({
    required List<TransactionModel> transactions,
    required PaymentMethod? paymentMethod,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return List<TransactionModel>.unmodifiable(
      transactions.map((transaction) {
        if (paymentMethod?.isCreditCard ?? false) {
          return transaction.copyWith(
            financialStatus: 'invoice',
            clearFinancialSettledAt: true,
          );
        }

        final effectiveDate = transaction.isRecurring
            ? transaction.recurringStartDate ?? transaction.date
            : transaction.date;
        final transactionDay = DateTime(
          effectiveDate.year,
          effectiveDate.month,
          effectiveDate.day,
        );
        final isDeferred = paymentMethod != null &&
            !paymentMethod.affectsBalanceImmediately;
        final isFuture = transactionDay.isAfter(today);
        final isLaterInstallment = transaction.isInstallment &&
            (transaction.installmentNumber ?? 1) > 1;

        if (isDeferred || isFuture || isLaterInstallment) {
          return transaction.copyWith(
            financialStatus: 'pending',
            clearFinancialSettledAt: true,
          );
        }

        return transaction.copyWith(
          financialStatus: 'settled',
          financialSettledAt: now,
        );
      }),
    );
  }

  List<TransactionModel> _applyInstallmentShares({
    required List<TransactionModel> transactions,
    required Map<String, double> totalShares,
  }) {
    if (transactions.isEmpty || totalShares.isEmpty) {
      return transactions;
    }

    final memberIds = totalShares.keys.toList(growable: false);
    final remainingByMember = <String, int>{
      for (final memberId in memberIds)
        memberId: ((totalShares[memberId] ?? 0) * 100).round(),
    };
    final totalInCents = transactions.fold<int>(
      0,
      (sum, transaction) =>
          sum + (transaction.value * 100).round(),
    );
    var processedInCents = 0;
    final result = <TransactionModel>[];

    for (var index = 0; index < transactions.length; index++) {
      final transaction = transactions[index];
      final installmentInCents =
          (transaction.value * 100).round();
      final isLast = index == transactions.length - 1;
      final shares = <String, double>{};
      var allocatedInCents = 0;

      for (var memberIndex = 0;
          memberIndex < memberIds.length;
          memberIndex++) {
        final memberId = memberIds[memberIndex];
        final isLastMember =
            memberIndex == memberIds.length - 1;
        final remaining =
            remainingByMember[memberId] ?? 0;
        final memberCents = isLast
            ? remaining
            : isLastMember
                ? installmentInCents - allocatedInCents
                : ((totalShares[memberId] ?? 0) *
                            100 *
                            installmentInCents /
                            totalInCents)
                        .round()
                        .clamp(0, remaining)
                        .toInt();

        shares[memberId] = memberCents / 100;
        remainingByMember[memberId] =
            remaining - memberCents;
        allocatedInCents += memberCents;
      }

      processedInCents += installmentInCents;
      result.add(transaction.copyWith(memberShares: shares));
    }

    if (processedInCents != totalInCents) {
      throw StateError('Falha ao distribuir as parcelas.');
    }

    return List<TransactionModel>.unmodifiable(result);
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
    required String? financialWalletId,
  }) async {
    final hasSelectedWallet =
        financialWalletId != null &&
        financialWalletId.isNotEmpty;

    final financialWallet = hasSelectedWallet
        ? await _walletRepository.getWalletById(
            financialWalletId,
          )
        : await _walletRepository.getFinancialWalletForMember(
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

    if (hasSelectedWallet &&
        financialWallet.ownerId.trim() !=
            paidByMemberId.trim()) {
      throw Exception(
        'A carteira financeira selecionada não pertence ao pagador.',
      );
    }

    return financialWallet;
  }

  String? _resolvePersistedPaymentSourceId({
    required String? paymentSourceId,
    required String? financialWalletId,
  }) {
    if (paymentSourceId != null && paymentSourceId.isNotEmpty) {
      return paymentSourceId;
    }

    if (financialWalletId != null &&
        financialWalletId.isNotEmpty) {
      return financialWalletId;
    }

    return null;
  }

  Future<void> _applyImmediateFinancialImpact({
    required PaymentMethod? paymentMethod,
    required WalletModel financialWallet,
    required String transactionType,
    required double transactionValue,
  }) async {
    // Compatibilidade com os fluxos anteriores à introdução
    // de formas de pagamento: sem paymentMethod informado,
    // mantém o comportamento financeiro já existente.
    if (paymentMethod == null) {
      await _updateFinancialWalletBalance(
        wallet: financialWallet,
        transactionType: transactionType,
        transactionValue: transactionValue,
      );

      return;
    }

    // Dinheiro, Pix e débito representam liquidação imediata:
    // o valor efetivamente sai/entra na carteira financeira agora.
    if (paymentMethod.affectsBalanceImmediately) {
      await _updateFinancialWalletBalance(
        wallet: financialWallet,
        transactionType: transactionType,
        transactionValue: transactionValue,
      );

      return;
    }

    // Crédito, boleto e carnê NÃO movimentam a conta bancária
    // no momento do registro.
    //
    // Crédito fica vinculado ao paymentSourceId do cartão e deverá
    // movimentar a carteira/fatura do cartão quando o domínio de
    // cartões estiver conectado.
    //
    // Boleto e carnê permanecem como obrigação pendente.
    //
    // Em ambos os casos, a conta bancária somente será movimentada
    // quando houver confirmação/liquidação do pagamento.
  }

  void _validatePaymentConfiguration({
    required PaymentMethod? paymentMethod,
    required String? paymentSourceId,
  }) {
    if (paymentMethod == null) {
      return;
    }

    if (paymentMethod.requiresPaymentSource &&
        (paymentSourceId == null ||
            paymentSourceId.isEmpty)) {
      throw Exception(
        'Selecione a origem financeira para ${paymentMethod.label}.',
      );
    }
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