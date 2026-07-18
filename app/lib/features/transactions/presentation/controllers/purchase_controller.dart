import 'package:flutter/foundation.dart';

import '../../../consumers/domain/intelligence/consumer_knowledge_payload.dart';
import '../../../consumers/domain/usecases/process_consumer_intelligence_usecase.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/repositories/firebase_purchase_repository.dart';
import '../../domain/purchase/commands/create_purchase_command.dart';
import '../../domain/purchase/mappers/purchase_item_mapper.dart';
import '../../domain/purchase/models/purchase_item_model.dart';
import '../../domain/purchase/models/purchase_model.dart';
import '../../domain/purchase/repositories/purchase_repository.dart';
import '../../domain/purchase/services/purchase_flow_service.dart';
import '../../domain/purchase/usecases/analyze_purchase_usecase.dart';
import '../../domain/purchase/usecases/build_purchase_usecase.dart';
import '../../domain/purchase/usecases/complete_purchase_usecase.dart';
import '../../domain/purchase/usecases/save_purchase_to_repository_usecase.dart';

class PurchaseController extends ChangeNotifier {
  final BuildPurchaseUseCase _buildPurchaseUseCase;
  final PurchaseFlowService _purchaseFlowService;
  final PurchaseItemMapper _purchaseItemMapper;
  final ProcessConsumerIntelligenceUseCase?
      _processConsumerIntelligenceUseCase;

  PurchaseController({
    BuildPurchaseUseCase? buildPurchaseUseCase,
    PurchaseFlowService? purchaseFlowService,
    PurchaseItemMapper? purchaseItemMapper,
    PurchaseRepository? purchaseRepository,
    ProcessConsumerIntelligenceUseCase? processConsumerIntelligenceUseCase,
  })  : _buildPurchaseUseCase =
            buildPurchaseUseCase ?? const BuildPurchaseUseCase(),
        _purchaseItemMapper =
            purchaseItemMapper ?? const PurchaseItemMapper(),
        _processConsumerIntelligenceUseCase =
            processConsumerIntelligenceUseCase,
        _purchaseFlowService = purchaseFlowService ??
            PurchaseFlowService(
              completePurchaseUseCase: CompletePurchaseUseCase(
                analyzePurchaseUseCase: const AnalyzePurchaseUseCase(),
                savePurchaseUseCase: SavePurchaseToRepositoryUseCase(
                  purchaseRepository:
                      purchaseRepository ?? FirebasePurchaseRepository(),
                ),
              ),
            );

  String? _merchantId;
  String _merchantName = '';
  String _financialCategory = 'Sem categoria';
  String _financialSubcategory = 'Sem subcategoria';

  final List<PurchaseItemModel> _items = [];

  bool _isSaving = false;
  String? _errorMessage;
  PurchaseFlowResult? _lastPurchaseFlowResult;

  String? get merchantId => _merchantId;
  String get merchantName => _merchantName;
  String get financialCategory => _financialCategory;
  String get financialSubcategory => _financialSubcategory;

  List<PurchaseItemModel> get items => List.unmodifiable(_items);

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  PurchaseFlowResult? get lastPurchaseFlowResult => _lastPurchaseFlowResult;

  bool get hasMerchant => _merchantName.trim().isNotEmpty;
  bool get hasItems => _items.isNotEmpty;
  int get itemCount => _items.length;

  double get subtotal {
    return _items.fold(
      0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  double get discount => 0;

  double get total => subtotal - discount;

  bool get canSave {
    return !_isSaving && hasItems && total > 0;
  }

  void setMerchant({
    String? merchantId,
    required String merchantName,
  }) {
    _merchantId = merchantId;
    _merchantName = merchantName.trim();

    _clearError();
    notifyListeners();
  }

  void setFinancialCategory({
    required String category,
    required String subcategory,
  }) {
    _financialCategory = category.trim().isEmpty
        ? 'Sem categoria'
        : category.trim();

    _financialSubcategory = subcategory.trim().isEmpty
        ? 'Sem subcategoria'
        : subcategory.trim();

    _clearError();
    notifyListeners();
  }

  void addTransactionItem(TransactionItemModel item) {
    final purchaseItem = _purchaseItemMapper.fromTransactionItem(item);

    _items.add(purchaseItem);

    _clearError();
    notifyListeners();
  }

  void addPurchaseItem(PurchaseItemModel item) {
    _items.add(item);

    _clearError();
    notifyListeners();
  }

  void updatePurchaseItem({
    required String originalItemId,
    required PurchaseItemModel updatedItem,
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

  void updateTransactionItem({
    required String originalItemId,
    required TransactionItemModel updatedItem,
  }) {
    final purchaseItem = _purchaseItemMapper.fromTransactionItem(
      updatedItem,
    );

    updatePurchaseItem(
      originalItemId: originalItemId,
      updatedItem: purchaseItem,
    );
  }

  void removeItem(String itemId) {
    _items.removeWhere(
      (item) => item.id == itemId,
    );

    _clearError();
    notifyListeners();
  }

  void clearItems() {
    _items.clear();

    _clearError();
    notifyListeners();
  }

  void clearPurchase() {
    _merchantId = null;
    _merchantName = '';
    _financialCategory = 'Sem categoria';
    _financialSubcategory = 'Sem subcategoria';

    _items.clear();

    _isSaving = false;
    _errorMessage = null;
    _lastPurchaseFlowResult = null;

    notifyListeners();
  }

  PurchaseModel buildPurchase(
    CreatePurchaseCommand command,
  ) {
    command.validate();

    final purchase = _buildPurchaseUseCase(
      id: command.id,
      userId: command.userId,
      walletId: command.walletId,
      merchantId: _merchantId,
      merchantName: _merchantName,
      financialCategory: _financialCategory,
      financialSubcategory: _financialSubcategory,
      items: _items,
      purchaseDate: command.purchaseDate,
      discount: discount,
    );

    _items
      ..clear()
      ..addAll(purchase.items);

    return purchase;
  }

  Future<PurchaseFlowResult?> completePurchase(
    CreatePurchaseCommand command,
  ) async {
    return runSaving(() async {
      final purchase = buildPurchase(command);

      final result = await _purchaseFlowService.completePurchase(
        purchase,
      );

      await _processConsumerIntelligence(
        command: command,
        purchase: result.purchase,
      );

      _lastPurchaseFlowResult = result;

      return result;
    });
  }

  Future<void> _processConsumerIntelligence({
    required CreatePurchaseCommand command,
    required PurchaseModel purchase,
  }) async {
    final consumerId = command.consumerId?.trim();

    if (consumerId == null || consumerId.isEmpty) {
      return;
    }

    final processUseCase = _processConsumerIntelligenceUseCase;

    if (processUseCase == null) {
      return;
    }

    await processUseCase.execute(
      payload: ConsumerKnowledgePayload(
        walletId: command.walletId,
        consumerId: consumerId,
        purchase: purchase,
      ),
    );
  }

  TransactionItemModel toTransactionItem({
    required PurchaseItemModel item,
    required String transactionId,
  }) {
    return _purchaseItemMapper.toTransactionItem(
      item: item,
      transactionId: transactionId,
    );
  }

  List<TransactionItemModel> toTransactionItems({
    required String transactionId,
  }) {
    return _purchaseItemMapper.toTransactionItems(
      items: _items,
      transactionId: transactionId,
    );
  }

  Future<T?> runSaving<T>(
    Future<T> Function() action,
  ) async {
    if (_isSaving) {
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await action();
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
    }
  }
}