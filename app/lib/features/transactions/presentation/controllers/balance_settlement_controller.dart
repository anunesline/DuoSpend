import 'package:flutter/foundation.dart';

import '../../../home/data/models/wallet_model.dart';
import '../../data/models/balance_settlement_model.dart';
import '../../data/repositories/balance_settlement_repository.dart';
import '../../domain/purchase/usecases/settle_balance_use_case.dart';

class BalanceSettlementController extends ChangeNotifier {
  final BalanceSettlementRepository _repository;
  final SettleBalanceUseCase _settleBalanceUseCase;

  BalanceSettlementController({
    BalanceSettlementRepository? repository,
    SettleBalanceUseCase? settleBalanceUseCase,
  }) : _repository =
           repository ?? BalanceSettlementRepository(),
       _settleBalanceUseCase =
           settleBalanceUseCase ?? SettleBalanceUseCase();

  List<BalanceSettlementModel> _settlements = [];

  final Set<String> _processingSettlementIds = {};

  bool _isLoading = false;
  String? _errorMessage;
  String? _walletId;

  List<BalanceSettlementModel> get settlements {
    return List<BalanceSettlementModel>.unmodifiable(
      _settlements,
    );
  }

  List<BalanceSettlementModel> get pendingSettlements {
    return List<BalanceSettlementModel>.unmodifiable(
      _settlements.where(
        (settlement) => !settlement.isSettled,
      ),
    );
  }

  List<BalanceSettlementModel> get completedSettlements {
    return List<BalanceSettlementModel>.unmodifiable(
      _settlements.where(
        (settlement) => settlement.isSettled,
      ),
    );
  }

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get walletId => _walletId;

  bool get hasSettlements => _settlements.isNotEmpty;

  bool get hasPendingSettlements {
    return pendingSettlements.isNotEmpty;
  }

  bool get isProcessingAnySettlement {
    return _processingSettlementIds.isNotEmpty;
  }

  bool isProcessing(String settlementId) {
    final normalizedSettlementId = settlementId.trim();

    if (normalizedSettlementId.isEmpty) {
      return false;
    }

    return _processingSettlementIds.contains(
      normalizedSettlementId,
    );
  }

  Future<void> loadSettlements({
    required String walletId,
  }) async {
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      _setError(
        'Não foi possível identificar a carteira.',
      );
      return;
    }

    _walletId = normalizedWalletId;
    _setLoading(true);

    try {
      _settlements = await _repository.getSettlements(
        walletId: normalizedWalletId,
      );

      _clearError();
    } catch (error) {
      _setError(
        'Não foi possível carregar os acertos. '
        'Tente novamente.',
      );

      debugPrint(
        'Erro ao carregar acertos: $error',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createPendingSettlement({
    required String walletId,
    required String fromMemberId,
    required String toMemberId,
    required double amount,
  }) async {
    final normalizedWalletId = walletId.trim();
    final normalizedFromMemberId = fromMemberId.trim();
    final normalizedToMemberId = toMemberId.trim();

    if (normalizedWalletId.isEmpty ||
        normalizedFromMemberId.isEmpty ||
        normalizedToMemberId.isEmpty) {
      _setError(
        'Não foi possível identificar os participantes do acerto.',
      );

      return false;
    }

    if (normalizedFromMemberId == normalizedToMemberId) {
      _setError(
        'O pagador e o recebedor precisam ser pessoas diferentes.',
      );

      return false;
    }

    if (amount <= 0) {
      _setError(
        'O valor do acerto precisa ser maior que zero.',
      );

      return false;
    }

    final existingSettlement = _findActiveSettlement(
      walletId: normalizedWalletId,
      fromMemberId: normalizedFromMemberId,
      toMemberId: normalizedToMemberId,
    );

    if (existingSettlement != null) {
      return true;
    }

    _setLoading(true);

    try {
      final now = DateTime.now();

      final settlement = BalanceSettlementModel(
        id: now.microsecondsSinceEpoch.toString(),
        walletId: normalizedWalletId,
        fromMemberId: normalizedFromMemberId,
        toMemberId: normalizedToMemberId,
        amount: amount,
        createdAt: now,
      );

      await _repository.saveSettlement(settlement);

      _settlements.insert(0, settlement);
      _clearError();
      notifyListeners();

      return true;
    } catch (error) {
      _setError(
        'Não foi possível registrar o acerto pendente.',
      );

      debugPrint(
        'Erro ao registrar acerto: $error',
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> declarePayment({
    required BalanceSettlementModel settlement,
    required String payerWalletId,
    DateTime? declaredAt,
    String? notes,
  }) async {
    if (settlement.isSettled) {
      return true;
    }

    if (!_canProcessSettlement(settlement)) {
      return false;
    }

    _setSettlementProcessing(
      settlement.id,
      true,
    );

    try {
      final updatedSettlement =
          await _settleBalanceUseCase.declarePayment(
            settlement: settlement,
            payerWalletId: payerWalletId,
            declaredAt: declaredAt,
            notes: notes,
          );

      _replaceSettlement(updatedSettlement);
      _clearError();

      await _reloadCurrentWalletSettlements();

      return true;
    } catch (error) {
      _setError(
        'Não foi possível informar o pagamento. '
        'Tente novamente.',
      );

      debugPrint(
        'Erro ao declarar pagamento do acerto: $error',
      );

      return false;
    } finally {
      _setSettlementProcessing(
        settlement.id,
        false,
      );
    }
  }

  Future<bool> cancelPaymentDeclaration({
    required BalanceSettlementModel settlement,
  }) async {
    if (settlement.isSettled) {
      _setError(
        'Este acerto já foi concluído.',
      );
      return false;
    }

    if (!_canProcessSettlement(settlement)) {
      return false;
    }

    _setSettlementProcessing(
      settlement.id,
      true,
    );

    try {
      final updatedSettlement =
          await _settleBalanceUseCase
              .cancelPaymentDeclaration(
                settlement: settlement,
              );

      _replaceSettlement(updatedSettlement);
      _clearError();

      await _reloadCurrentWalletSettlements();

      return true;
    } catch (error) {
      _setError(
        'Não foi possível cancelar o aviso de pagamento. '
        'Tente novamente.',
      );

      debugPrint(
        'Erro ao cancelar declaração de pagamento: $error',
      );

      return false;
    } finally {
      _setSettlementProcessing(
        settlement.id,
        false,
      );
    }
  }

  Future<bool> confirmReceipt({
    required BalanceSettlementModel settlement,
    required WalletModel wallet,
    required String receiverWalletId,
    DateTime? confirmedAt,
    String? notes,
  }) async {
    if (settlement.isSettled) {
      return true;
    }

    if (!_canProcessSettlement(settlement)) {
      return false;
    }

    _setSettlementProcessing(
      settlement.id,
      true,
    );

    try {
      final updatedSettlement =
          await _settleBalanceUseCase.confirmReceipt(
            settlement: settlement,
            wallet: wallet,
            receiverWalletId: receiverWalletId,
            confirmedAt: confirmedAt,
            notes: notes,
          );

      _replaceSettlement(updatedSettlement);
      _clearError();

      await _reloadCurrentWalletSettlements();

      return true;
    } catch (error) {
      _setError(
        'Não foi possível confirmar o recebimento. '
        'Tente novamente.',
      );

      debugPrint(
        'Erro ao confirmar recebimento do acerto: $error',
      );

      return false;
    } finally {
      _setSettlementProcessing(
        settlement.id,
        false,
      );
    }
  }

  Future<bool> hasSettlementTransaction({
    required BalanceSettlementModel settlement,
    required WalletModel wallet,
  }) async {
    try {
      final exists =
          await _settleBalanceUseCase
              .hasSettlementTransaction(
                settlement: settlement,
                wallet: wallet,
              );

      _clearError();

      return exists;
    } catch (error) {
      _setError(
        'Não foi possível verificar a transação do acerto.',
      );

      debugPrint(
        'Erro ao verificar transação de settlement: $error',
      );

      return false;
    }
  }

  Future<bool> deleteSettlement(
    BalanceSettlementModel settlement,
  ) async {
    if (!_canProcessSettlement(settlement)) {
      return false;
    }

    _setSettlementProcessing(
      settlement.id,
      true,
    );

    try {
      await _repository.deleteSettlement(
        walletId: settlement.walletId,
        settlementId: settlement.id,
      );

      _settlements.removeWhere(
        (item) => item.id == settlement.id,
      );

      _clearError();
      notifyListeners();

      return true;
    } catch (error) {
      _setError(
        'Não foi possível excluir o acerto.',
      );

      debugPrint(
        'Erro ao excluir acerto: $error',
      );

      return false;
    } finally {
      _setSettlementProcessing(
        settlement.id,
        false,
      );
    }
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  Future<void> _reloadCurrentWalletSettlements() async {
    final currentWalletId =
        _walletId?.trim().isNotEmpty == true
        ? _walletId!.trim()
        : null;

    if (currentWalletId == null) {
      notifyListeners();
      return;
    }

    try {
      _settlements = await _repository.getSettlements(
        walletId: currentWalletId,
      );

      _clearError();
      notifyListeners();
    } catch (error) {
      debugPrint(
        'Erro ao recarregar acertos após ação: $error',
      );

      notifyListeners();
    }
  }

  bool _canProcessSettlement(
    BalanceSettlementModel settlement,
  ) {
    final normalizedSettlementId = settlement.id.trim();

    if (normalizedSettlementId.isEmpty) {
      _setError(
        'Não foi possível identificar o acerto.',
      );
      return false;
    }

    if (isProcessing(normalizedSettlementId)) {
      return false;
    }

    return true;
  }

  BalanceSettlementModel? _findActiveSettlement({
    required String walletId,
    required String fromMemberId,
    required String toMemberId,
  }) {
    for (final settlement in _settlements) {
      final isSameSettlement =
          settlement.walletId == walletId &&
          settlement.fromMemberId == fromMemberId &&
          settlement.toMemberId == toMemberId &&
          !settlement.isSettled;

      if (isSameSettlement) {
        return settlement;
      }
    }

    return null;
  }

  void _replaceSettlement(
    BalanceSettlementModel updatedSettlement,
  ) {
    final index = _settlements.indexWhere(
      (settlement) =>
          settlement.id == updatedSettlement.id,
    );

    if (index == -1) {
      _settlements.insert(
        0,
        updatedSettlement,
      );
      return;
    }

    _settlements[index] = updatedSettlement;
  }

  void _setSettlementProcessing(
    String settlementId,
    bool isProcessing,
  ) {
    final normalizedSettlementId = settlementId.trim();

    if (normalizedSettlementId.isEmpty) {
      return;
    }

    if (isProcessing) {
      _processingSettlementIds.add(
        normalizedSettlementId,
      );
    } else {
      _processingSettlementIds.remove(
        normalizedSettlementId,
      );
    }

    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}