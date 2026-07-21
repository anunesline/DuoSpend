import 'package:flutter/foundation.dart';

import '../../../home/data/models/wallet_model.dart';
import '../../../home/data/repositories/wallet_repository.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/purchase/services/balance_settlement_synchronizer.dart';

class TransactionController extends ChangeNotifier {
  final TransactionRepository _repository;
  final WalletRepository _walletRepository;
  final BalanceSettlementSynchronizer _settlementSynchronizer;

  TransactionController({
    TransactionRepository? repository,
    WalletRepository? walletRepository,
    BalanceSettlementSynchronizer? settlementSynchronizer,
  })  : _repository = repository ?? TransactionRepository(),
        _walletRepository = walletRepository ?? WalletRepository(),
        _settlementSynchronizer =
            settlementSynchronizer ?? BalanceSettlementSynchronizer();

  final List<TransactionItemModel> _items = [];

  List<TransactionItemModel> get items {
    return List.unmodifiable(_items);
  }

  void addItem(TransactionItemModel item) {
    _items.add(item);
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
    notifyListeners();
  }

  void removeItem(TransactionItemModel item) {
    _items.removeWhere(
      (currentItem) => currentItem.id == item.id,
    );

    notifyListeners();
  }

  void clearItems() {
    _items.clear();
    notifyListeners();
  }

  Future<void> saveTransaction({
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
    required String splitType,
    required Map<String, double> memberShares,
    WalletModel? wallet,
  }) async {
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      throw Exception('Carteira da transação não informada.');
    }

    final resolvedWallet = wallet ??
        await _walletRepository.getWalletById(
          normalizedWalletId,
        );

    if (resolvedWallet == null) {
      throw Exception(
        'Não foi possível localizar a carteira da transação.',
      );
    }

    if (resolvedWallet.id.trim() != normalizedWalletId) {
      throw Exception(
        'A carteira informada não corresponde ao walletId da transação.',
      );
    }

    final transaction = TransactionModel(
      id: transactionId,
      description: description,
      value: value,
      type: type,
      date: DateTime.now(),
      walletId: resolvedWallet.id,
      consumerId: consumerId,
      category: category,
      subcategory: subcategory,
      paidByMemberId: paidByMemberId,
      purchaseFor: purchaseFor,
      splitType: splitType,
      memberShares: memberShares,
      items: _items
          .map(
            (item) => item.copyWith(
              transactionId: transactionId,
            ),
          )
          .toList(),
    );

    await _repository.addTransaction(
      transaction,
      wallet: resolvedWallet,
    );

    await _updateWalletBalance(
      wallet: resolvedWallet,
      transactionType: type,
      transactionValue: value,
    );

    if (resolvedWallet.isShared) {
      await _settlementSynchronizer.synchronize(
        walletId: resolvedWallet.id,
      );
    }

    clearItems();
  }

  Future<void> _updateWalletBalance({
    required WalletModel wallet,
    required String transactionType,
    required double transactionValue,
  }) async {
    var newBalance = wallet.balance;

    if (transactionType == 'income') {
      newBalance += transactionValue;
    } else if (transactionType == 'expense') {
      newBalance -= transactionValue;
    } else {
      throw Exception(
        'Tipo de transação inválido: $transactionType.',
      );
    }

    await _walletRepository.updateBalance(
      newBalance,
      walletId: wallet.id,
    );
  }
}