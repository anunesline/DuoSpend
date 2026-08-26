import '../models/receipt_capture_source.dart';
import '../models/receipt_scan_image.dart';

abstract class ReceiptImageCaptureProvider {
  /// Retorna null quando a pessoa cancela a câmera ou a galeria.
  Future<ReceiptScanImage?> capture(ReceiptCaptureSource source);
}
