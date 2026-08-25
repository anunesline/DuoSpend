import '../../../../home/data/models/wallet_model.dart';
import '../../../data/models/balance_settlement_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/balance_settlement_repository.dart';
import '../../../data/repositories/transaction_repository.dart';

/// Executa as operações financeiras relacionadas ao pagamento
/// de acertos entre membros de uma carteira compartilhada.
///
/// Responsabilidades:
/// - registrar que o devedor declarou o pagamento;
/// - cancelar uma declaração de pagamento;
/// - criar a transação financeira do acerto;
/// - impedir transações duplicadas;
/// - confirmar definitivamente o recebimento.
///
/// A sincronização dos saldos não pertence a este serviço.
/// Ela será coordenada pelo SettleBalanceUseCase.
class SettlementPaymentService {
  static const double _minimumAmount = 0.01;

  final TransactionRepository _transactionRepository;
  final BalanceSettlementRepository _settlementRepository;

  SettlementPaymentService({
    TransactionRepository? transactionRepository,
    BalanceSettlementRepository? settlementRepository,
  }) : _transactionRepository =
           transactionRepository ?? TransactionRepository(),
       _settlementRepository =
           settlementRepository ?? BalanceSettlementRepository();

  /// Registra que o membro devedor informou ter realizado
  /// o pagamento do acerto.
  ///
  /// O próprio modelo valida se o usuário autenticado
  /// corresponde ao membro devedor.
  Future<BalanceSettlementModel> declarePayment({
    required BalanceSettlementModel settlement,
    required String payerWalletId,
    DateTime? declaredAt,
    String? notes,
  }) async {
    _validateSettlement(settlement);

    if (!settlement.isPending) {
      throw StateError(
        'Somente um acerto pendente pode ser declarado como pago.',
      );
    }

    return _settlementRepository.declarePayment(
      settlement: settlement,
      payerWalletId: payerWalletId,
      declaredAt: declaredAt,
      notes: _normalizeOptionalText(notes),
    );
  }

  /// Cancela a declaração de pagamento enquanto o credor
  /// ainda não confirmou o recebimento.
  Future<BalanceSettlementModel> cancelPaymentDeclaration({
    required BalanceSettlementModel settlement,
  }) async {
    _validateSettlement(settlement);

    if (!settlement.isAwaitingConfirmation) {
      throw StateError(
        'Este acerto não possui um pagamento aguardando confirmação.',
      );
    }

    return _settlementRepository.cancelPaymentDeclaration(
      settlement: settlement,
    );
  }

  /// Confirma o recebimento do pagamento e registra
  /// a movimentação no histórico financeiro.
  ///
  /// Ordem utilizada:
  ///
  /// 1. verifica se já existe uma transação para o acerto;
  /// 2. cria a transação quando necessário;
  /// 3. confirma definitivamente o settlement.
  ///
  /// A transação é criada antes da confirmação para permitir
  /// recuperação segura caso o processo seja interrompido.
  ///
  /// Em uma nova tentativa, a transação existente será
  /// reutilizada e não haverá duplicidade.
  Future<BalanceSettlementModel> confirmReceipt({
    required BalanceSettlementModel settlement,
    required WalletModel wallet,
    required String receiverWalletId,
    DateTime? confirmedAt,
    String? notes,
  }) async {
    _validateSettlement(settlement);
    _validateSharedWallet(
      settlement: settlement,
      wallet: wallet,
    );

    final confirmationDate = confirmedAt ?? DateTime.now();

    final existingTransaction =
        await _transactionRepository.findSettlementTransaction(
          walletId: settlement.walletId,
          settlementId: settlement.id,
          wallet: wallet,
        );

    if (settlement.isSettled) {
      if (existingTransaction == null) {
        throw StateError(
          'O acerto está concluído, mas sua transação financeira '
          'não foi encontrada.',
        );
      }

      return settlement;
    }

    if (!settlement.isAwaitingConfirmation) {
      throw StateError(
        'O devedor precisa declarar o pagamento antes '
        'da confirmação do recebimento.',
      );
    }

    final transaction =
        existingTransaction ??
        _createSettlementTransaction(
          settlement: settlement,
          confirmationDate: confirmationDate,
        );

    if (existingTransaction != null) {
      _validateExistingTransaction(
        transaction: existingTransaction,
        settlement: settlement,
      );
    } else {
      await _transactionRepository.addTransaction(
        transaction,
        wallet: wallet,
      );
    }

    return _settlementRepository.confirmReceipt(
      settlement: settlement,
      transactionId: transaction.id,
      receiverWalletId: receiverWalletId,
      confirmedAt: confirmationDate,
      notes: _normalizeOptionalText(notes),
    );
  }

  /// Procura a transação financeira vinculada ao acerto.
  ///
  /// Pode ser utilizado pela camada de aplicação para
  /// auditoria ou recuperação de estado.
  Future<TransactionModel?> findSettlementTransaction({
    required BalanceSettlementModel settlement,
    required WalletModel wallet,
  }) async {
    _validateSettlement(settlement);
    _validateSharedWallet(
      settlement: settlement,
      wallet: wallet,
    );

    return _transactionRepository.findSettlementTransaction(
      walletId: settlement.walletId,
      settlementId: settlement.id,
      wallet: wallet,
    );
  }

  TransactionModel _createSettlementTransaction({
    required BalanceSettlementModel settlement,
    required DateTime confirmationDate,
  }) {
    final transactionId = _createTransactionId(
      settlementId: settlement.id,
    );

    return TransactionModel(
      id: transactionId,
      description: 'Acerto de contas',
      value: _roundCurrency(settlement.amount),
      type: 'expense',
      date: confirmationDate,
      walletId: settlement.walletId.trim(),
      consumerId: null,

      /// O devedor é quem efetivamente realizou
      /// o pagamento para o outro membro.
      paidByMemberId: settlement.fromMemberId.trim(),

      /// O pagamento foi destinado ao parceiro credor.
      purchaseFor: 'partner',

      /// O valor inteiro é atribuído ao membro que recebeu.
      ///
      /// Dessa forma, o BalanceEngine registra que o devedor
      /// pagou esse valor em benefício do credor, compensando
      /// a dívida financeira anterior.
      splitType: 'custom',
      memberShares: {
        settlement.toMemberId.trim(): _roundCurrency(
          settlement.amount,
        ),
      },
      isSettlement: true,
      settlementId: settlement.id.trim(),
      category: 'Acerto de contas',
      subcategory: 'Pagamento entre membros',
      items: const [],
    );
  }

  /// Usa um ID determinístico.
  ///
  /// Mesmo que duas confirmações sejam disparadas quase
  /// simultaneamente, ambas tentarão salvar o mesmo documento
  /// no Firestore, evitando duas transações diferentes.
  String _createTransactionId({
    required String settlementId,
  }) {
    return 'settlement_payment_${settlementId.trim()}';
  }

  void _validateSettlement(
    BalanceSettlementModel settlement,
  ) {
    if (settlement.id.trim().isEmpty) {
      throw ArgumentError.value(
        settlement.id,
        'settlement.id',
        'O ID do acerto não pode ficar vazio.',
      );
    }

    if (settlement.walletId.trim().isEmpty) {
      throw ArgumentError.value(
        settlement.walletId,
        'settlement.walletId',
        'O ID da carteira não pode ficar vazio.',
      );
    }

    if (settlement.fromMemberId.trim().isEmpty) {
      throw ArgumentError.value(
        settlement.fromMemberId,
        'settlement.fromMemberId',
        'O membro devedor não pode ficar vazio.',
      );
    }

    if (settlement.toMemberId.trim().isEmpty) {
      throw ArgumentError.value(
        settlement.toMemberId,
        'settlement.toMemberId',
        'O membro credor não pode ficar vazio.',
      );
    }

    if (settlement.fromMemberId.trim() ==
        settlement.toMemberId.trim()) {
      throw StateError(
        'O membro devedor e o membro credor '
        'não podem ser a mesma pessoa.',
      );
    }

    if (_roundCurrency(settlement.amount) < _minimumAmount) {
      throw StateError(
        'O valor do acerto precisa ser maior que zero.',
      );
    }
  }

  void _validateSharedWallet({
    required BalanceSettlementModel settlement,
    required WalletModel wallet,
  }) {
    if (!wallet.isShared) {
      throw StateError(
        'Acertos financeiros exigem uma carteira compartilhada.',
      );
    }

    if (wallet.id.trim() != settlement.walletId.trim()) {
      throw StateError(
        'O acerto não pertence à carteira compartilhada informada.',
      );
    }

    if (!_walletContainsMember(
      wallet: wallet,
      memberId: settlement.fromMemberId,
    )) {
      throw StateError(
        'O membro devedor não participa desta carteira.',
      );
    }

    if (!_walletContainsMember(
      wallet: wallet,
      memberId: settlement.toMemberId,
    )) {
      throw StateError(
        'O membro credor não participa desta carteira.',
      );
    }
  }

  void _validateExistingTransaction({
    required TransactionModel transaction,
    required BalanceSettlementModel settlement,
  }) {
    if (!transaction.isSettlement) {
      throw StateError(
        'A transação encontrada não representa um acerto financeiro.',
      );
    }

    if (transaction.settlementId?.trim() != settlement.id.trim()) {
      throw StateError(
        'A transação encontrada pertence a outro acerto financeiro.',
      );
    }

    if (transaction.walletId.trim() != settlement.walletId.trim()) {
      throw StateError(
        'A transação do acerto pertence a outra carteira.',
      );
    }

    if (transaction.paidByMemberId?.trim() !=
        settlement.fromMemberId.trim()) {
      throw StateError(
        'O pagador da transação não corresponde ao devedor do acerto.',
      );
    }

    if (!_hasSameAmount(
      transaction.value,
      settlement.amount,
    )) {
      throw StateError(
        'O valor da transação existente não corresponde '
        'ao valor atual do acerto.',
      );
    }
  }

  bool _walletContainsMember({
    required WalletModel wallet,
    required String memberId,
  }) {
    final normalizedMemberId = memberId.trim();

    if (normalizedMemberId.isEmpty) {
      return false;
    }

    if (wallet.ownerId.trim() == normalizedMemberId) {
      return true;
    }

    return wallet.memberIds.any(
      (walletMemberId) =>
          walletMemberId.trim() == normalizedMemberId,
    );
  }

  bool _hasSameAmount(
    double firstAmount,
    double secondAmount,
  ) {
    return (_roundCurrency(firstAmount) -
                _roundCurrency(secondAmount))
            .abs() <
        _minimumAmount;
  }

  double _roundCurrency(double value) {
    final rounded = (value * 100).roundToDouble() / 100;

    if (rounded.abs() < _minimumAmount) {
      return 0;
    }

    return rounded;
  }

  String? _normalizeOptionalText(String? value) {
    final normalizedValue = value?.trim();

    if (normalizedValue == null || normalizedValue.isEmpty) {
      return null;
    }

    return normalizedValue;
  }
}