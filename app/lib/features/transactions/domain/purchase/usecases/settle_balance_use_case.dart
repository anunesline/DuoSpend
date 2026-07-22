import '../../../../home/data/models/wallet_model.dart';
import '../../../data/models/balance_settlement_model.dart';
import '../services/balance_settlement_synchronizer.dart';
import '../services/settlement_payment_service.dart';

/// Orquestra o fluxo completo de acerto financeiro
/// entre membros de uma carteira compartilhada.
///
/// Responsabilidades:
/// - validar o contexto geral do caso de uso;
/// - delegar as operações de pagamento ao
///   SettlementPaymentService;
/// - sincronizar os acertos após mudanças financeiras;
/// - entregar um ponto único de entrada para o Controller.
///
/// As regras operacionais de criação da transação pertencem
/// ao SettlementPaymentService.
///
/// O cálculo e a reconstrução dos acertos pertencem ao
/// BalanceSettlementSynchronizer.
class SettleBalanceUseCase {
  final SettlementPaymentService _paymentService;
  final BalanceSettlementSynchronizer _synchronizer;

  SettleBalanceUseCase({
    SettlementPaymentService? paymentService,
    BalanceSettlementSynchronizer? synchronizer,
  }) : _paymentService =
           paymentService ?? SettlementPaymentService(),
       _synchronizer =
           synchronizer ?? BalanceSettlementSynchronizer();

  /// Registra que o membro devedor declarou
  /// ter realizado o pagamento.
  ///
  /// O acerto passa de:
  ///
  /// pending
  ///
  /// para:
  ///
  /// awaiting_confirmation
  ///
  /// Essa operação ainda não cria uma transação financeira,
  /// pois o pagamento precisa ser confirmado pelo credor.
  Future<BalanceSettlementModel> declarePayment({
    required BalanceSettlementModel settlement,
    DateTime? declaredAt,
    String? notes,
  }) async {
    _validateSettlementContext(settlement);

    return _paymentService.declarePayment(
      settlement: settlement,
      declaredAt: declaredAt,
      notes: notes,
    );
  }

  /// Cancela uma declaração de pagamento enquanto
  /// o membro credor ainda não confirmou o recebimento.
  ///
  /// O acerto retorna de:
  ///
  /// awaiting_confirmation
  ///
  /// para:
  ///
  /// pending
  Future<BalanceSettlementModel> cancelPaymentDeclaration({
    required BalanceSettlementModel settlement,
  }) async {
    _validateSettlementContext(settlement);

    return _paymentService.cancelPaymentDeclaration(
      settlement: settlement,
    );
  }

  /// Confirma definitivamente o recebimento do pagamento.
  ///
  /// Fluxo:
  ///
  /// 1. valida carteira e settlement;
  /// 2. cria ou recupera a transação do acerto;
  /// 3. confirma o recebimento;
  /// 4. marca o settlement como concluído;
  /// 5. recalcula e sincroniza os acertos da carteira.
  ///
  /// A sincronização acontece somente após a confirmação
  /// definitiva do credor.
  Future<BalanceSettlementModel> confirmReceipt({
    required BalanceSettlementModel settlement,
    required WalletModel wallet,
    DateTime? confirmedAt,
    String? notes,
  }) async {
    _validateSettlementContext(settlement);
    _validateWalletContext(
      settlement: settlement,
      wallet: wallet,
    );

    final confirmedSettlement =
        await _paymentService.confirmReceipt(
          settlement: settlement,
          wallet: wallet,
          confirmedAt: confirmedAt,
          notes: notes,
        );

    await _synchronizer.synchronize(
      walletId: wallet.id,
    );

    return confirmedSettlement;
  }

  /// Tenta localizar a transação financeira que representa
  /// o pagamento de um acerto específico.
  ///
  /// Útil para:
  /// - auditoria;
  /// - recuperação após interrupções;
  /// - exibição no histórico;
  /// - prevenção de duplicidade.
  Future<bool> hasSettlementTransaction({
    required BalanceSettlementModel settlement,
    required WalletModel wallet,
  }) async {
    _validateSettlementContext(settlement);
    _validateWalletContext(
      settlement: settlement,
      wallet: wallet,
    );

    final transaction =
        await _paymentService.findSettlementTransaction(
          settlement: settlement,
          wallet: wallet,
        );

    return transaction != null;
  }

  void _validateSettlementContext(
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
        'O ID da carteira do acerto não pode ficar vazio.',
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
        'O devedor e o credor do acerto '
        'não podem ser a mesma pessoa.',
      );
    }

    if (settlement.amount <= 0) {
      throw StateError(
        'O valor do acerto precisa ser maior que zero.',
      );
    }
  }

  void _validateWalletContext({
    required BalanceSettlementModel settlement,
    required WalletModel wallet,
  }) {
    if (!wallet.isShared) {
      throw StateError(
        'Acertos financeiros só podem ser realizados '
        'em carteiras compartilhadas.',
      );
    }

    if (wallet.id.trim().isEmpty) {
      throw ArgumentError.value(
        wallet.id,
        'wallet.id',
        'O ID da carteira não pode ficar vazio.',
      );
    }

    if (wallet.id.trim() != settlement.walletId.trim()) {
      throw StateError(
        'O acerto não pertence à carteira informada.',
      );
    }

    if (!_containsMember(
      wallet: wallet,
      memberId: settlement.fromMemberId,
    )) {
      throw StateError(
        'O membro devedor não participa desta carteira.',
      );
    }

    if (!_containsMember(
      wallet: wallet,
      memberId: settlement.toMemberId,
    )) {
      throw StateError(
        'O membro credor não participa desta carteira.',
      );
    }
  }

  bool _containsMember({
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
}