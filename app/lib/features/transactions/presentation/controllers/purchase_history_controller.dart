import 'package:flutter/foundation.dart';

import '../../data/repositories/firebase_purchase_repository.dart';
import '../../domain/purchase/models/purchase_model.dart';
import '../../domain/purchase/repositories/purchase_repository.dart';
import '../../domain/purchase/services/purchase_memory_service.dart';
import '../../domain/purchase/usecases/delete_purchase_usecase.dart';
import '../../domain/purchase/usecases/get_purchase_by_id_usecase.dart';
import '../../domain/purchase/usecases/get_purchases_by_date_range_usecase.dart';
import '../../domain/purchase/usecases/get_purchases_by_merchant_usecase.dart';
import '../../domain/purchase/usecases/get_purchases_by_wallet_usecase.dart';

class PurchaseHistoryController extends ChangeNotifier {
  final PurchaseRepository _purchaseRepository;
  final PurchaseMemoryService _purchaseMemoryService;

  late final GetPurchasesByWalletUseCase _getPurchasesByWalletUseCase;
  late final GetPurchasesByMerchantUseCase _getPurchasesByMerchantUseCase;
  late final GetPurchasesByDateRangeUseCase _getPurchasesByDateRangeUseCase;
  late final GetPurchaseByIdUseCase _getPurchaseByIdUseCase;
  late final DeletePurchaseUseCase _deletePurchaseUseCase;

  PurchaseHistoryController({
    PurchaseRepository? purchaseRepository,
    PurchaseMemoryService? purchaseMemoryService,
  })  : _purchaseRepository =
            purchaseRepository ?? FirebasePurchaseRepository(),
        _purchaseMemoryService =
            purchaseMemoryService ?? const PurchaseMemoryService() {
    _getPurchasesByWalletUseCase = GetPurchasesByWalletUseCase(
      purchaseRepository: _purchaseRepository,
    );

    _getPurchasesByMerchantUseCase = GetPurchasesByMerchantUseCase(
      purchaseRepository: _purchaseRepository,
    );

    _getPurchasesByDateRangeUseCase = GetPurchasesByDateRangeUseCase(
      purchaseRepository: _purchaseRepository,
    );

    _getPurchaseByIdUseCase = GetPurchaseByIdUseCase(
      purchaseRepository: _purchaseRepository,
    );

    _deletePurchaseUseCase = DeletePurchaseUseCase(
      purchaseRepository: _purchaseRepository,
    );
  }

  final List<PurchaseModel> _purchases = [];

  bool _isLoading = false;
  bool _isDeleting = false;
  String? _errorMessage;

  List<PurchaseModel> get purchases => List.unmodifiable(_purchases);

  bool get isLoading => _isLoading;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;

  bool get hasPurchases => _purchases.isNotEmpty;

  double get averagePurchaseTotal {
    return _purchaseMemoryService.getAveragePurchaseTotal(_purchases);
  }

  List<String> get frequentProductNames {
    return _purchaseMemoryService.getFrequentProductNames(_purchases);
  }

  Future<void> loadPurchasesByWallet(String walletId) async {
    await _runLoading(() async {
      final result = await _getPurchasesByWalletUseCase(walletId);

      _purchases
        ..clear()
        ..addAll(_purchaseMemoryService.sortByMostRecent(result));
    });
  }

  Future<void> loadPurchasesByMerchant(String merchantId) async {
    await _runLoading(() async {
      final result = await _getPurchasesByMerchantUseCase(merchantId);

      _purchases
        ..clear()
        ..addAll(_purchaseMemoryService.sortByMostRecent(result));
    });
  }

  Future<void> loadPurchasesByDateRange({
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _runLoading(() async {
      final result = await _getPurchasesByDateRangeUseCase(
        walletId: walletId,
        startDate: startDate,
        endDate: endDate,
      );

      _purchases
        ..clear()
        ..addAll(_purchaseMemoryService.sortByMostRecent(result));
    });
  }

  Future<PurchaseModel?> getPurchaseById(String purchaseId) async {
    try {
      _errorMessage = null;
      notifyListeners();

      return await _getPurchaseByIdUseCase(purchaseId);
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> deletePurchase(String purchaseId) async {
    if (_isDeleting) {
      return;
    }

    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deletePurchaseUseCase(purchaseId);
      _purchases.removeWhere((purchase) => purchase.id == purchaseId);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  List<PurchaseModel> filterCurrentPurchasesByProductName(String productName) {
    return _purchaseMemoryService.filterByProductName(
      purchases: _purchases,
      productName: productName,
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clear() {
    _purchases.clear();
    _isLoading = false;
    _isDeleting = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _runLoading(Future<void> Function() action) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}