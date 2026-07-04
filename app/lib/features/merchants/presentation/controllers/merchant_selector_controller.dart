import 'package:flutter/foundation.dart';

import '../../data/merchant_repository.dart';
import '../../domain/merchant_model.dart';

class MerchantSelectorController extends ChangeNotifier {
  MerchantSelectorController({
    MerchantRepository? repository,
  }) : _repository = repository ?? MerchantRepository();

  final MerchantRepository _repository;

  final List<MerchantModel> _suggestions = [];

  MerchantModel? _selectedMerchant;
  String _query = '';
  bool _isLoading = false;

  List<MerchantModel> get suggestions => List.unmodifiable(_suggestions);

  MerchantModel? get selectedMerchant => _selectedMerchant;

  String get query => _query;

  bool get isLoading => _isLoading;

  bool get hasQuery => _query.trim().isNotEmpty;

  bool get hasSuggestions => _suggestions.isNotEmpty;

  bool get hasSelectedMerchant => _selectedMerchant != null;

  Future<void> search(String value) async {
    _query = value;

    final normalizedQuery = value.trim();

    if (normalizedQuery.isEmpty) {
      _suggestions.clear();
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    final results = await _repository.searchWithMemory(normalizedQuery);

    if (_query.trim() != normalizedQuery) {
      return;
    }

    _suggestions
      ..clear()
      ..addAll(results);

    _isLoading = false;
    notifyListeners();
  }

  void selectMerchant(MerchantModel merchant) {
    _selectedMerchant = merchant;
    _query = merchant.name;

    _suggestions.clear();

    notifyListeners();
  }

  void clearSelection() {
    _selectedMerchant = null;
    _query = '';
    _suggestions.clear();
    _isLoading = false;

    notifyListeners();
  }

  Future<MerchantModel?> findBestMatch(String value) async {
    final results = await _repository.searchWithMemory(value);

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }
}