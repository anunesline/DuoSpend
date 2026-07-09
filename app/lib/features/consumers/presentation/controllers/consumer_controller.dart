import 'package:flutter/foundation.dart';

import '../../domain/consumer_profile_entity.dart';
import '../../domain/consumer_type.dart';
import '../../domain/services/consumer_flow_service.dart';

class ConsumerController extends ChangeNotifier {
  final ConsumerFlowService _consumerFlowService;

  ConsumerController(this._consumerFlowService);

  List<ConsumerProfileEntity> _consumers = [];
  ConsumerProfileEntity? _selectedConsumer;
  bool _isLoading = false;
  String? _errorMessage;

  List<ConsumerProfileEntity> get consumers => List.unmodifiable(_consumers);
  ConsumerProfileEntity? get selectedConsumer => _selectedConsumer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initializeWallet({
    required String walletId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _consumerFlowService.initializeWalletConsumers(
        walletId: walletId,
      );

      await loadConsumers(walletId: walletId);

      _selectedConsumer = await _consumerFlowService.getDefault(
        walletId: walletId,
      );
    } catch (error) {
      _setError('Não foi possível inicializar os consumidores.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadConsumers({
    required String walletId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _consumers = await _consumerFlowService.getWalletConsumers(
        walletId: walletId,
      );

      _selectedConsumer ??= await _consumerFlowService.getDefault(
        walletId: walletId,
      );
    } catch (error) {
      _setError('Não foi possível carregar os consumidores.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createConsumer({
    required String walletId,
    required String name,
    required ConsumerType type,
    String? icon,
    String? color,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _consumerFlowService.create(
        walletId: walletId,
        name: name,
        type: type,
        icon: icon,
        color: color,
      );

      await loadConsumers(walletId: walletId);
    } catch (error) {
      _setError('Não foi possível criar o consumidor.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveConsumer(
    ConsumerProfileEntity consumer,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final updated = await _consumerFlowService.save(consumer);

      _consumers = _consumers
          .map(
            (item) => item.id == updated.id ? updated : item,
          )
          .toList();

      if (_selectedConsumer?.id == updated.id) {
        _selectedConsumer = updated;
      }
    } catch (error) {
      _setError('Não foi possível salvar o consumidor.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> archiveConsumer({
    required String walletId,
    required String id,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _consumerFlowService.archive(id: id);
      await loadConsumers(walletId: walletId);

      if (_selectedConsumer?.id == id) {
        _selectedConsumer = await _consumerFlowService.getDefault(
          walletId: walletId,
        );
      }
    } catch (error) {
      _setError('Não foi possível arquivar o consumidor.');
    } finally {
      _setLoading(false);
    }
  }

  void selectConsumer(
    ConsumerProfileEntity consumer,
  ) {
    _selectedConsumer = consumer;
    notifyListeners();
  }

  void clearSelectedConsumer() {
    _selectedConsumer = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}