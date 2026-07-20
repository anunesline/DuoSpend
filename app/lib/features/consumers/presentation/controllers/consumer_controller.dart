import 'package:flutter/foundation.dart';

import '../../../../core/context/wallet_context.dart';
import '../../domain/consumer_profile_entity.dart';
import '../../domain/consumer_type.dart';
import '../../domain/services/consumer_flow_service.dart';

class ConsumerController extends ChangeNotifier {
  final ConsumerFlowService _consumerFlowService;
  final WalletContext _walletContext;

  ConsumerController(
    this._consumerFlowService,
    this._walletContext,
  ) {
    _walletContext.addListener(_handleWalletContextChanged);
  }

  List<ConsumerProfileEntity> _consumers = [];
  ConsumerProfileEntity? _selectedConsumer;

  bool _isLoading = false;
  String? _errorMessage;
  String? _activeWalletId;
  String? _initializingWalletId;

  List<ConsumerProfileEntity> get consumers {
    return List<ConsumerProfileEntity>.unmodifiable(_consumers);
  }

  ConsumerProfileEntity? get selectedConsumer => _selectedConsumer;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get activeWalletId => _activeWalletId;

  Future<void> initializeWallet({
    required String walletId,
  }) async {
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      clear();
      return;
    }

    if (_activeWalletId == normalizedWalletId &&
        _consumers.isNotEmpty &&
        _initializingWalletId == null) {
      return;
    }

    if (_initializingWalletId == normalizedWalletId) {
      return;
    }

    _initializingWalletId = normalizedWalletId;
    _setLoading(true);
    _clearError();

    try {
      await _consumerFlowService.initializeWalletConsumers(
        walletId: normalizedWalletId,
      );

      final loadedConsumers =
          await _consumerFlowService.getWalletConsumers(
        walletId: normalizedWalletId,
      );

      final defaultConsumer = await _consumerFlowService.getDefault(
        walletId: normalizedWalletId,
      );

      if (_walletContext.walletId != normalizedWalletId) {
        return;
      }

      _activeWalletId = normalizedWalletId;
      _consumers = loadedConsumers;
      _selectedConsumer = defaultConsumer;

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao inicializar consumidores da carteira '
        '$normalizedWalletId: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _setError(
        'Não foi possível inicializar os consumidores.',
      );
    } finally {
      if (_initializingWalletId == normalizedWalletId) {
        _initializingWalletId = null;
      }

      _setLoading(false);
    }
  }

  Future<void> loadConsumers({
    required String walletId,
  }) async {
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final loadedConsumers =
          await _consumerFlowService.getWalletConsumers(
        walletId: normalizedWalletId,
      );

      final defaultConsumer = await _consumerFlowService.getDefault(
        walletId: normalizedWalletId,
      );

      if (_walletContext.walletId != normalizedWalletId) {
        return;
      }

      _activeWalletId = normalizedWalletId;
      _consumers = loadedConsumers;

      final selectedConsumerStillExists = _selectedConsumer != null &&
          _consumers.any(
            (consumer) => consumer.id == _selectedConsumer!.id,
          );

      if (!selectedConsumerStillExists) {
        _selectedConsumer = defaultConsumer;
      }

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao carregar consumidores da carteira '
        '$normalizedWalletId: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _setError(
        'Não foi possível carregar os consumidores.',
      );
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
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _consumerFlowService.create(
        walletId: normalizedWalletId,
        name: name,
        type: type,
        icon: icon,
        color: color,
      );

      await loadConsumers(
        walletId: normalizedWalletId,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao criar consumidor: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _setError(
        'Não foi possível criar o consumidor.',
      );
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
      final updated = await _consumerFlowService.save(
        consumer,
      );

      _consumers = _consumers.map((item) {
        if (item.id == updated.id) {
          return updated;
        }

        return item;
      }).toList();

      if (_selectedConsumer?.id == updated.id) {
        _selectedConsumer = updated;
      }

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao salvar consumidor: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _setError(
        'Não foi possível salvar o consumidor.',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> archiveConsumer({
    required String walletId,
    required String id,
  }) async {
    final normalizedWalletId = walletId.trim();

    if (normalizedWalletId.isEmpty) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _consumerFlowService.archive(
        id: id,
      );

      await loadConsumers(
        walletId: normalizedWalletId,
      );

      if (_selectedConsumer?.id == id) {
        _selectedConsumer = await _consumerFlowService.getDefault(
          walletId: normalizedWalletId,
        );

        notifyListeners();
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao arquivar consumidor: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _setError(
        'Não foi possível arquivar o consumidor.',
      );
    } finally {
      _setLoading(false);
    }
  }

  void selectConsumer(
    ConsumerProfileEntity consumer,
  ) {
    final consumerBelongsToActiveWallet = _consumers.any(
      (currentConsumer) => currentConsumer.id == consumer.id,
    );

    if (!consumerBelongsToActiveWallet) {
      return;
    }

    _selectedConsumer = consumer;
    notifyListeners();
  }

  void clearSelectedConsumer() {
    _selectedConsumer = null;
    notifyListeners();
  }

  void clear() {
    _activeWalletId = null;
    _initializingWalletId = null;
    _consumers = [];
    _selectedConsumer = null;
    _errorMessage = null;
    _isLoading = false;

    notifyListeners();
  }

  void _handleWalletContextChanged() {
    final walletId = _walletContext.walletId;

    if (walletId == null || walletId.isEmpty) {
      clear();
      return;
    }

    if (_activeWalletId == walletId ||
        _initializingWalletId == walletId) {
      return;
    }

    initializeWallet(
      walletId: walletId,
    );
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
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _walletContext.removeListener(
      _handleWalletContextChanged,
    );

    super.dispose();
  }
}