import '../models/receipt_scan_image.dart';

/// Porta para OCR de nota/cupom.
///
/// Implementações de câmera, galeria ou OCR nativo ficam fora do domínio
/// financeiro e só devolvem texto reconhecido para revisão do usuário.
abstract class ReceiptTextRecognitionProvider {
  Future<String> recognizeText(ReceiptScanImage image);
}
