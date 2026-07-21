import '../../../data/models/balance_settlement_model.dart';
import '../../../data/repositories/balance_settlement_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import 'balance_engine.dart';

/// Mantém os acertos pendentes sincronizados com o saldo
/// calculado a partir das transações da carteira.
class BalanceSettlementSynchronizer {
  static const double _minimumAmount = 0.01;

  final TransactionRepository _transactionRepository;
  final BalanceSettlementRepository _settlementRepository;
  final BalanceEngine _balanceEngine;

  BalanceSettlementSynchronizer({
    TransactionRepository? transactionRepository,
    BalanceSettlementRepository? settlementRepository,
    BalanceEngine? balanceEngine,
  }) : _transactionRepository =
           transactionRepository ?? TransactionRepository(),
       _settlementRepository =
           settlementRepository ?? BalanceSettlementRepository(),
       _balanceEngine = balanceEngine ?? const BalanceEngine();

  Future<void> synchronize({
    required String walletId,
  }) async {
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      return;
    }

    final transactions =
        await _transactionRepository.getTransactionsByWallet(
          normalizedWalletId,
        );

    final balanceResult = _balanceEngine.calculate(
      transactions: transactions,
      walletId: normalizedWalletId,
    );

    final validTransfers = balanceResult.transfers.where((transfer) {
      final fromMemberId = transfer.fromMemberId.trim();
      final toMemberId = transfer.toMemberId.trim();
      final amount = _roundCurrency(transfer.amount);

      return fromMemberId.isNotEmpty &&
          toMemberId.isNotEmpty &&
          fromMemberId != toMemberId &&
          amount >= _minimumAmount;
    }).toList(growable: false);

    /// Uma carteira individual não gera transferências entre membros.
    ///
    /// Nesse caso, não precisamos acessar o repositório de acertos.
    /// Isso também impede que o salvamento de uma transação individual
    /// seja bloqueado pela estrutura de settlements.
    if (validTransfers.isEmpty) {
      return;
    }

    final pendingSettlements =
        await _settlementRepository.getPendingSettlements(
          walletId: normalizedWalletId,
        );

    final unmatchedPendingSettlements = [
      ...pendingSettlements,
    ];

    for (final transfer in validTransfers) {
      final fromMemberId = transfer.fromMemberId.trim();
      final toMemberId = transfer.toMemberId.trim();
      final amount = _roundCurrency(transfer.amount);

      final existingSettlement = _findMatchingSettlement(
        settlements: unmatchedPendingSettlements,
        fromMemberId: fromMemberId,
        toMemberId: toMemberId,
      );

      if (existingSettlement != null) {
        unmatchedPendingSettlements.remove(existingSettlement);

        if (_hasSameAmount(
          existingSettlement.amount,
          amount,
        )) {
          continue;
        }

        final updatedSettlement = BalanceSettlementModel(
          id: existingSettlement.id,
          walletId: normalizedWalletId,
          fromMemberId: fromMemberId,
          toMemberId: toMemberId,
          amount: amount,
          createdAt: existingSettlement.createdAt,
          settledAt: null,
          status: 'pending',
          notes: existingSettlement.notes,
        );

        await _settlementRepository.saveSettlement(
          updatedSettlement,
        );

        continue;
      }

      final now = DateTime.now();

      final newSettlement = BalanceSettlementModel(
        id: _createSettlementId(
          walletId: normalizedWalletId,
          fromMemberId: fromMemberId,
          toMemberId: toMemberId,
          createdAt: now,
        ),
        walletId: normalizedWalletId,
        fromMemberId: fromMemberId,
        toMemberId: toMemberId,
        amount: amount,
        createdAt: now,
        settledAt: null,
        status: 'pending',
        notes: null,
      );

      await _settlementRepository.saveSettlement(
        newSettlement,
      );
    }

    /// Remove pendências que não aparecem mais no cálculo atual.
    ///
    /// Isso pode acontecer quando:
    /// - novas transações compensam a dívida;
    /// - o sentido da dívida é invertido;
    /// - uma transação é editada ou excluída.
    for (final obsoleteSettlement in unmatchedPendingSettlements) {
      await _settlementRepository.deleteSettlement(
        walletId: normalizedWalletId,
        settlementId: obsoleteSettlement.id,
      );
    }
  }

  BalanceSettlementModel? _findMatchingSettlement({
    required List<BalanceSettlementModel> settlements,
    required String fromMemberId,
    required String toMemberId,
  }) {
    for (final settlement in settlements) {
      if (settlement.fromMemberId.trim() == fromMemberId &&
          settlement.toMemberId.trim() == toMemberId) {
        return settlement;
      }
    }

    return null;
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

  String _createSettlementId({
    required String walletId,
    required String fromMemberId,
    required String toMemberId,
    required DateTime createdAt,
  }) {
    return '${walletId}_'
        '${fromMemberId}_'
        '${toMemberId}_'
        '${createdAt.microsecondsSinceEpoch}';
  }

  double _roundCurrency(double value) {
    final rounded = (value * 100).roundToDouble() / 100;

    if (rounded.abs() < _minimumAmount) {
      return 0;
    }

    return rounded;
  }
}