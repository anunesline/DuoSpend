import 'package:flutter/foundation.dart';

import '../../features/home/data/models/wallet_model.dart';

class WalletContext extends ChangeNotifier {
  List<WalletModel> _wallets = [];

  WalletModel? _selectedWallet;

  List<WalletModel> get wallets => List.unmodifiable(_wallets);

  WalletModel? get selectedWallet => _selectedWallet;

  bool get hasWallet => _selectedWallet != null;

  String? get walletId => _selectedWallet?.id;

  void initialize({
    required List<WalletModel> wallets,
    WalletModel? selectedWallet,
  }) {
    _wallets = List.from(wallets);

    if (_wallets.isEmpty) {
      _selectedWallet = null;
      notifyListeners();
      return;
    }

    if (selectedWallet != null) {
      final exists = _wallets.any(
        (wallet) => wallet.id == selectedWallet.id,
      );

      _selectedWallet = exists ? selectedWallet : _wallets.first;
    } else {
      _selectedWallet = _wallets.first;
    }

    notifyListeners();
  }

  void updateWallets(List<WalletModel> wallets) {
    _wallets = List.from(wallets);

    if (_wallets.isEmpty) {
      _selectedWallet = null;
      notifyListeners();
      return;
    }

    if (_selectedWallet == null) {
      _selectedWallet = _wallets.first;
      notifyListeners();
      return;
    }

    final updatedWallet = _wallets.cast<WalletModel?>().firstWhere(
          (wallet) => wallet?.id == _selectedWallet?.id,
          orElse: () => null,
        );

    _selectedWallet = updatedWallet ?? _wallets.first;

    notifyListeners();
  }

  void selectWallet(String walletId) {
    final wallet = _wallets.cast<WalletModel?>().firstWhere(
          (wallet) => wallet?.id == walletId,
          orElse: () => null,
        );

    if (wallet == null) {
      return;
    }

    if (_selectedWallet?.id == wallet.id) {
      return;
    }

    _selectedWallet = wallet;

    notifyListeners();
  }

  void updateSelectedWallet(WalletModel wallet) {
    final index = _wallets.indexWhere(
      (item) => item.id == wallet.id,
    );

    if (index != -1) {
      _wallets[index] = wallet;
    }

    _selectedWallet = wallet;

    notifyListeners();
  }

  void clear() {
    _wallets = [];
    _selectedWallet = null;

    notifyListeners();
  }
}