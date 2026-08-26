import 'package:flutter/foundation.dart';

import '../../domain/models/fiscal_qr_lookup_result.dart';
import '../../domain/models/receipt_capture_source.dart';
import '../../domain/models/receipt_scan_result.dart';
import '../../domain/models/receipt_transaction_draft.dart';
import '../../domain/repositories/receipt_image_capture_provider.dart';
import '../../domain/usecases/lookup_fiscal_qr_usecase.dart';
import '../../domain/usecases/recognize_receipt_usecase.dart';

enum ReceiptScannerState {
  idle,
  capturing,
  recognizing,
  reviewing,
  error,
}

/// Mantém somente o estado efêmero de captura e revisão.
/// Nenhuma regra financeira ou persistência existe neste controller.
class ReceiptScannerController extends ChangeNotifier {
  final ReceiptImageCaptureProvider _captureProvider;
  final RecognizeReceiptUseCase _recognizeReceiptUseCase;
  final LookupFiscalQrUseCase _lookupFiscalQrUseCase;

  ReceiptScannerController({
    required ReceiptImageCaptureProvider captureProvider,
    required RecognizeReceiptUseCase recognizeReceiptUseCase,
    LookupFiscalQrUseCase lookupFiscalQrUseCase =
        const LookupFiscalQrUseCase(),
  })  : _captureProvider = captureProvider,
        _recognizeReceiptUseCase = recognizeReceiptUseCase,
        _lookupFiscalQrUseCase = lookupFiscalQrUseCase;

  ReceiptScannerState _state = ReceiptScannerState.idle;
  ReceiptScanResult? _result;
  String? _errorMessage;

  ReceiptScannerState get state => _state;
  ReceiptScanResult? get result => _result;
  ReceiptTransactionDraft? get draft =>
      _result == null ? null : ReceiptTransactionDraft.fromScanResult(_result!);
  String? get errorMessage => _errorMessage;

  Future<ReceiptTransactionDraft?> captureAndRecognize(
    ReceiptCaptureSource source,
  ) async {
    _setState(ReceiptScannerState.capturing);
    try {
      final image = await _captureProvider.capture(source);
      if (image == null) {
        _setState(ReceiptScannerState.idle);
        return null;
      }

      _setState(ReceiptScannerState.recognizing);
      _result = await _recognizeReceiptUseCase(image);
      _setState(ReceiptScannerState.reviewing);
      return draft;
    } catch (_) {
      _errorMessage = 'Não foi possível ler esta imagem.';
      _setState(ReceiptScannerState.error);
      return null;
    }
  }

  Future<FiscalQrLookupResult> lookupFiscalQr(String rawValue) async {
    _setState(ReceiptScannerState.recognizing);
    try {
      final lookup = await _lookupFiscalQrUseCase(rawValue);
      if (lookup.receipt != null) {
        _result = lookup.receipt;
        _setState(ReceiptScannerState.reviewing);
      } else {
        _setState(ReceiptScannerState.idle);
      }
      return lookup;
    } catch (_) {
      _errorMessage = 'Não foi possível consultar este QR fiscal.';
      _setState(ReceiptScannerState.error);
      rethrow;
    }
  }

  void dismissError() {
    _errorMessage = null;
    _setState(ReceiptScannerState.idle);
  }

  void reset() {
    _result = null;
    _errorMessage = null;
    _setState(ReceiptScannerState.idle);
  }

  void _setState(ReceiptScannerState value) {
    _state = value;
    notifyListeners();
  }
}
