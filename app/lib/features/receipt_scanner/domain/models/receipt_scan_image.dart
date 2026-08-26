import 'dart:typed_data';

/// Imagem fornecida ao reconhecimento. Não representa uma transação nem é
/// persistida pelo fluxo do scanner.
class ReceiptScanImage {
  final Uint8List bytes;
  final String mimeType;

  const ReceiptScanImage({
    required this.bytes,
    required this.mimeType,
  });
}
