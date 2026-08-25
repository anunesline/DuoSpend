import '../../../../home/data/models/wallet_model.dart';
import '../../../data/models/balance_settlement_model.dart';
import '../services/balance_settlement_synchronizer.dart';
import '../services/settlement_payment_service.dart';

/// Orquestra o fluxo completo de acerto financeiro
/// entre membros de uma carteira compartilhada.
///
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

  Future<BalanceSettlementModel> declarePayment({
    required BalanceSettlementModel settlement,
    required String payerWalletId,
    DateTime? declaredAt,
    String? notes,
  }) async {
    _validateSettlementContext(settlement);

    return _paymentService.declarePayment(
      settlement: settlement,
      payerWalletId: payerWalletId,
      declaredAt: declaredAt,
      notes: notes,
    );
  }

  Future<BalanceSettlementModel> cancelPaymentDeclaration({
    required BalanceSettlementModel settlement,
  }) async {
    _validateSettlementContext(settlement);

    return _paymentService.cancelPaymentDeclaration(
      settlement: settlement,
    );
  }

  Future<BalanceSettlementModel> confirmReceipt({
    required BalanceSettlementModel settlement,
    required WalletModel wallet,
    required String receiverWalletId,
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
          receiverWalletId: receiverWalletId,
          confirmedAt: confirmedAt,
          notes: notes,
        );

    await _synchronizer.synchronize(
      walletId: wallet.id,
    );

    return confirmedSettlement;
  }

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
