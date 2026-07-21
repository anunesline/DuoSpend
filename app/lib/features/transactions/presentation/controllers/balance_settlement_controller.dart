import 'package:flutter/foundation.dart';

import '../../data/models/balance_settlement_model.dart';
import '../../data/repositories/balance_settlement_repository.dart';

class BalanceSettlementController extends ChangeNotifier {
  final BalanceSettlementRepository _repository;

  BalanceSettlementController({
    BalanceSettlementRepository? repository,
  }) : _repository = repository ?? BalanceSettlementRepository();

  List<BalanceSettlementModel> _settlements = [];

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
        (settlement) => settlement.isPending,
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

  Future<void> loadSettlements({
    required String walletId,
  }) async {
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      _setError('Não foi possível identificar a carteira.');
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

    final existingSettlement = _findPendingSettlement(
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

  Future<bool> markAsSettled({
    required BalanceSettlementModel settlement,
    DateTime? settledAt,
    String? notes,
  }) async {
    if (!settlement.isPending) {
      return true;
    }

    _setLoading(true);

    try {
      final paymentDate = settledAt ?? DateTime.now();

      await _repository.markAsSettled(
        settlement: settlement,
        settledAt: paymentDate,
        notes: notes,
      );

      final updatedSettlement = settlement.markAsSettled(
        settledAt: paymentDate,
        notes: notes,
      );

      _replaceSettlement(updatedSettlement);
      _clearError();
      notifyListeners();

      return true;
    } catch (error) {
      _setError(
        'Não foi possível marcar o acerto como pago.',
      );

      debugPrint(
        'Erro ao concluir acerto: $error',
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteSettlement(
    BalanceSettlementModel settlement,
  ) async {
    _setLoading(true);

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
      _setLoading(false);
    }
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  BalanceSettlementModel? _findPendingSettlement({
    required String walletId,
    required String fromMemberId,
    required String toMemberId,
  }) {
    for (final settlement in _settlements) {
      final isSameSettlement =
          settlement.walletId == walletId &&
          settlement.fromMemberId == fromMemberId &&
          settlement.toMemberId == toMemberId &&
          settlement.isPending;

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
      (settlement) => settlement.id == updatedSettlement.id,
    );

    if (index == -1) {
      _settlements.insert(0, updatedSettlement);
      return;
    }

    _settlements[index] = updatedSettlement;
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