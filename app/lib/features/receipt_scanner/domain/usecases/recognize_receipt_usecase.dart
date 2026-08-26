import '../models/receipt_scan_image.dart';
import '../models/receipt_scan_result.dart';
import '../repositories/receipt_text_recognition_provider.dart';
import '../services/receipt_text_parser.dart';

/// Orquestra somente reconhecimento e parsing para a prévia editável.
/// A confirmação financeira continua sendo responsabilidade do fluxo normal
/// de criação de transação.
class RecognizeReceiptUseCase {
  final ReceiptTextRecognitionProvider _recognitionProvider;
  final ReceiptTextParser _textParser;

  const RecognizeReceiptUseCase({
    required ReceiptTextRecognitionProvider recognitionProvider,
    ReceiptTextParser textParser = const ReceiptTextParser(),
  })  : _recognitionProvider = recognitionProvider,
        _textParser = textParser;

  Future<ReceiptScanResult> call(ReceiptScanImage image) async {
    final text = await _recognitionProvider.recognizeText(image);
    return _textParser.parse(text);
  }
}
