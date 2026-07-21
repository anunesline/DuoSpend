import 'package:flutter/foundation.dart';

import '../../features/home/data/models/wallet_model.dart';

enum WalletUsageMode {
  solo,
  couple,
}

class WalletContext extends ChangeNotifier {
  List<WalletModel> _wallets = [];

  final Set<String> _sharedWalletIds = {};

  WalletModel? _selectedWallet;

  WalletUsageMode _usageMode = WalletUsageMode.solo;

  List<WalletModel> get wallets => List.unmodifiable(_wallets);

  List<WalletModel> get sharedWallets => List.unmodifiable(
        _wallets.where(
          (wallet) => _sharedWalletIds.contains(wallet.id),
        ),
      );

  List<WalletModel> get soloWallets => List.unmodifiable(
        _wallets.where(
          (wallet) => !_sharedWalletIds.contains(wallet.id),
        ),
      );

  WalletModel? get selectedWallet => _selectedWallet;

  WalletUsageMode get usageMode => _usageMode;

  bool get hasWallet => _selectedWallet != null;

  bool get hasSharedWallet => sharedWallets.isNotEmpty;

  bool get isSoloMode => _usageMode == WalletUsageMode.solo;

  bool get isCoupleMode => _usageMode == WalletUsageMode.couple;

  bool get selectedWalletIsShared {
    final selectedWalletId = _selectedWallet?.id;

    if (selectedWalletId == null) {
      return false;
    }

    return _sharedWalletIds.contains(selectedWalletId);
  }

  String? get walletId => _selectedWallet?.id;

  void initialize({
    required List<WalletModel> wallets,
    WalletModel? selectedWallet,
    Set<String> sharedWalletIds = const {},
  }) {
    _wallets = List.from(wallets);

    _sharedWalletIds
      ..clear()
      ..addAll(sharedWalletIds);

    _removeUnknownSharedWalletIds();

    if (_wallets.isEmpty) {
      _selectedWallet = null;
      _usageMode = WalletUsageMode.solo;
      notifyListeners();
      return;
    }

    if (selectedWallet != null) {
      final selectedWalletFromList = _findWalletById(selectedWallet.id);

      _selectedWallet = selectedWalletFromList ?? _wallets.first;
    } else {
      _selectedWallet = _wallets.first;
    }

    _synchronizeUsageMode();

    notifyListeners();
  }

  void updateWallets(List<WalletModel> wallets) {
    _wallets = List.from(wallets);

    _removeUnknownSharedWalletIds();

    if (_wallets.isEmpty) {
      _selectedWallet = null;
      _usageMode = WalletUsageMode.solo;
      notifyListeners();
      return;
    }

    final selectedWalletId = _selectedWallet?.id;

    if (selectedWalletId == null) {
      _selectedWallet = _wallets.first;
      _synchronizeUsageMode();
      notifyListeners();
      return;
    }

    _selectedWallet =
        _findWalletById(selectedWalletId) ?? _wallets.first;

    _synchronizeUsageMode();

    notifyListeners();
  }

  void selectWallet(String walletId) {
    final wallet = _findWalletById(walletId);

    if (wallet == null) {
      return;
    }

    if (_selectedWallet?.id == wallet.id) {
      return;
    }

    _selectedWallet = wallet;
    _synchronizeUsageMode();

    notifyListeners();
  }

  void updateSelectedWallet(WalletModel wallet) {
    final index = _wallets.indexWhere(
      (item) => item.id == wallet.id,
    );

    if (index == -1) {
      _wallets.add(wallet);
    } else {
      _wallets[index] = wallet;
    }

    _selectedWallet = wallet;
    _synchronizeUsageMode();

    notifyListeners();
  }

  void registerSharedWallet(WalletModel wallet) {
    final index = _wallets.indexWhere(
      (item) => item.id == wallet.id,
    );

    if (index == -1) {
      _wallets.add(wallet);
    } else {
      _wallets[index] = wallet;
    }

    _sharedWalletIds.add(wallet.id);
    _selectedWallet = wallet;
    _usageMode = WalletUsageMode.couple;

    notifyListeners();
  }

  void markWalletAsShared(String walletId) {
    final wallet = _findWalletById(walletId);

    if (wallet == null) {
      return;
    }

    final changed = _sharedWalletIds.add(walletId);

    if (_selectedWallet?.id == walletId) {
      _usageMode = WalletUsageMode.couple;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void markWalletAsSolo(String walletId) {
    final changed = _sharedWalletIds.remove(walletId);

    if (_selectedWallet?.id == walletId) {
      _usageMode = WalletUsageMode.solo;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void useSoloMode() {
    final wallet = soloWallets.firstOrNull;

    if (wallet == null) {
      return;
    }

    if (_selectedWallet?.id == wallet.id && isSoloMode) {
      return;
    }

    _selectedWallet = wallet;
    _usageMode = WalletUsageMode.solo;

    notifyListeners();
  }

  void useCoupleMode() {
    final wallet = sharedWallets.firstOrNull;

    if (wallet == null) {
      return;
    }

    if (_selectedWallet?.id == wallet.id && isCoupleMode) {
      return;
    }

    _selectedWallet = wallet;
    _usageMode = WalletUsageMode.couple;

    notifyListeners();
  }

  void clear() {
    _wallets = [];
    _sharedWalletIds.clear();
    _selectedWallet = null;
    _usageMode = WalletUsageMode.solo;

    notifyListeners();
  }

  WalletModel? _findWalletById(String walletId) {
    for (final wallet in _wallets) {
      if (wallet.id == walletId) {
        return wallet;
      }
    }

    return null;
  }

  void _removeUnknownSharedWalletIds() {
    final availableWalletIds = _wallets.map(
      (wallet) => wallet.id,
    );

    _sharedWalletIds.retainAll(availableWalletIds);
  }

  void _synchronizeUsageMode() {
    _usageMode = selectedWalletIsShared
        ? WalletUsageMode.couple
        : WalletUsageMode.solo;
  }
}

extension WalletModelListExtension on List<WalletModel> {
  WalletModel? get firstOrNull {
    if (isEmpty) {
      return null;
    }

    return first;
  }
}