import 'package:flutter/foundation.dart';

import '../../../home/data/models/wallet_model.dart';
import '../../../home/data/repositories/wallet_repository.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/financial_split/financial_split_service.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/purchase/models/item_consumption.dart';
import '../../domain/purchase/services/balance_settlement_synchronizer.dart';
import '../../transaction/usecases/accept_shared_transaction_usecase.dart';
import '../../transaction/usecases/create_transaction_usecase.dart';
import '../../transaction/usecases/reject_shared_transaction_usecase.dart';

class TransactionController extends ChangeNotifier {
  final CreateTransactionUseCase _createTransactionUseCase;
  final AcceptSharedTransactionUseCase
      _acceptSharedTransactionUseCase;
  final RejectSharedTransactionUseCase
      _rejectSharedTransactionUseCase;

  TransactionController({
    CreateTransactionUseCase? createTransactionUseCase,
    AcceptSharedTransactionUseCase?
        acceptSharedTransactionUseCase,
    RejectSharedTransactionUseCase?
        rejectSharedTransactionUseCase,
    TransactionRepository? repository,
    WalletRepository? walletRepository,
    FinancialSplitService? financialSplitService,
    BalanceSettlementSynchronizer? settlementSynchronizer,
  })  : _createTransactionUseCase =
            createTransactionUseCase ??
                CreateTransactionUseCase(
                  transactionRepository:
                      repository ?? TransactionRepository(),
                  walletRepository:
                      walletRepository ?? WalletRepository(),
                  financialSplitService:
                      financialSplitService ??
                          const FinancialSplitService(),
                  settlementSynchronizer:
                      settlementSynchronizer ??
                          BalanceSettlementSynchronizer(),
                ),
        _acceptSharedTransactionUseCase =
            acceptSharedTransactionUseCase ??
                (createTransactionUseCase != null
                    ? _UnavailableAcceptSharedTransactionUseCase()
                    : AcceptSharedTransactionUseCase(
                        transactionRepository:
                            repository ?? TransactionRepository(),
                        settlementSynchronizer:
                            settlementSynchronizer ??
                                BalanceSettlementSynchronizer(),
                      )),
        _rejectSharedTransactionUseCase =
            rejectSharedTransactionUseCase ??
                (createTransactionUseCase != null
                    ? _UnavailableRejectSharedTransactionUseCase()
                    : RejectSharedTransactionUseCase(
                        transactionRepository:
                            repository ?? TransactionRepository(),
                      ));

  final List<TransactionItemModel> _items = [];

  bool _isSaving = false;
  String? _errorMessage;
  CreateTransactionResult? _lastResult;

  List<TransactionItemModel> get items {
    return List.unmodifiable(_items);
  }

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  CreateTransactionResult? get lastResult => _lastResult;

  void addItem(TransactionItemModel item) {
    _items.add(item);
    _clearError();
    notifyListeners();
  }

  void updateItem({
    required String originalItemId,
    required TransactionItemModel updatedItem,
  }) {
    final index = _items.indexWhere(
      (item) => item.id == originalItemId,
    );

    if (index == -1) {
      return;
    }

    _items[index] = updatedItem;

    _clearError();
    notifyListeners();
  }

  void updateItemConsumptions({
    required String itemId,
    required List<ItemConsumption> consumptions,
  }) {
    final index = _items.indexWhere(
      (item) => item.id == itemId,
    );

    if (index == -1) {
      return;
    }

    _items[index] = _items[index].copyWith(
      consumptions: List<ItemConsumption>.unmodifiable(
        consumptions,
      ),
    );

    _clearError();
    notifyListeners();
  }

  void clearItemConsumptions({
    required String itemId,
  }) {
    updateItemConsumptions(
      itemId: itemId,
      consumptions: const [],
    );
  }

  void removeItem(TransactionItemModel item) {
    _items.removeWhere(
      (currentItem) => currentItem.id == item.id,
    );

    _clearError();
    notifyListeners();
  }

  void clearItems() {
    _items.clear();
    notifyListeners();
  }

  Future<CreateTransactionResult> saveTransaction({
    required String transactionId,
    required String description,
    required double value,
    required String type,
    required String walletId,
    String? consumerId,
    required String category,
    required String subcategory,
    required String paidByMemberId,
    required String purchaseFor,
    String? partnerMemberId,
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
    String? financialWalletId,
    PaymentMethod? paymentMethod,
    String? paymentSourceId,
    DateTime? transactionDate,
    String? splitType,
    Map<String, double>? memberShares,
  }) async {
    if (_isSaving) {
      throw StateError(
        'Uma transação já está sendo salva.',
      );
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _createTransactionUseCase(
        transactionId: transactionId,
        description: description,
        value: value,
        type: type,
        walletId: walletId,
        wallet: wallet,
        consumerId: consumerId,
        category: category,
        subcategory: subcategory,
        paidByMemberId: paidByMemberId,
        purchaseFor: purchaseFor,
        partnerMemberId: partnerMemberId,
        items: List.unmodifiable(_items),
        isRecurring: isRecurring,
        recurringFrequency: recurringFrequency,
        recurringStartDate: recurringStartDate,
        recurringEndDate: recurringEndDate,
        recurringNeverEnds: recurringNeverEnds,
        isInstallment: isInstallment,
        installmentCount: installmentCount,
        firstInstallmentDate: firstInstallmentDate,
        notes: notes,
        financialWalletId: financialWalletId,
        paymentMethod: paymentMethod,
        paymentSourceId: paymentSourceId,
        transactionDate: transactionDate,
      );

      _lastResult = result;
      _items.clear();

      return result;
    } catch (error) {
      _errorMessage = _formatError(error);
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<TransactionModel> acceptSharedTransaction({
    required TransactionModel transaction,
    required WalletModel wallet,
    required String respondingMemberId,
  }) async {
    if (_isSaving) {
      throw StateError(
        'Uma operação de transação já está em andamento.',
      );
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _acceptSharedTransactionUseCase(
        transaction: transaction,
        wallet: wallet,
        respondingMemberId: respondingMemberId,
      );
    } catch (error) {
      _errorMessage = _formatError(error);
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<TransactionModel> rejectSharedTransaction({
    required TransactionModel transaction,
    required WalletModel wallet,
    required String respondingMemberId,
  }) async {
    if (_isSaving) {
      throw StateError(
        'Uma operação de transação já está em andamento.',
      );
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _rejectSharedTransactionUseCase(
        transaction: transaction,
        wallet: wallet,
        respondingMemberId: respondingMemberId,
      );
    } catch (error) {
      _errorMessage = _formatError(error);
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearState() {
    _items.clear();
    _isSaving = false;
    _errorMessage = null;
    _lastResult = null;

    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
    }
  }

  String _formatError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(
        'Exception: '.length,
      );
    }

    if (message.startsWith('Bad state: ')) {
      return message.substring(
        'Bad state: '.length,
      );
    }

    return message;
  }
}

class _UnavailableAcceptSharedTransactionUseCase
    implements AcceptSharedTransactionUseCase {
  @override
  Future<TransactionModel> call({
    required TransactionModel transaction,
    required WalletModel wallet,
    required String respondingMemberId,
  }) {
    throw StateError('Fluxo de aceite compartilhado não configurado.');
  }
}

class _UnavailableRejectSharedTransactionUseCase
    implements RejectSharedTransactionUseCase {
  @override
  Future<TransactionModel> call({
    required TransactionModel transaction,
    required WalletModel wallet,
    required String respondingMemberId,
  }) {
    throw StateError('Fluxo de rejeição compartilhado não configurado.');
  }
}
