import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/models/receipt_scan_image.dart';
import '../../domain/repositories/receipt_text_recognition_provider.dart';

class GoogleMlKitReceiptTextRecognitionProvider
    implements ReceiptTextRecognitionProvider {
  @override
  Future<String> recognizeText(ReceiptScanImage image) async {
    final filePath = image.filePath;
    if (filePath == null || filePath.isEmpty) {
      throw StateError('A imagem selecionada não possui caminho local para OCR.');
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final recognizedText = await recognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      await recognizer.close();
    }
  }
}
