import 'dart:typed_data';

import 'package:app/features/receipt_scanner/domain/models/receipt_capture_source.dart';
import 'package:app/features/receipt_scanner/domain/models/receipt_scan_image.dart';
import 'package:app/features/receipt_scanner/domain/repositories/receipt_image_capture_provider.dart';
import 'package:app/features/receipt_scanner/domain/repositories/receipt_text_recognition_provider.dart';
import 'package:app/features/receipt_scanner/domain/usecases/recognize_receipt_usecase.dart';
import 'package:app/features/receipt_scanner/presentation/controllers/receipt_scanner_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCaptureProvider implements ReceiptImageCaptureProvider {
  final ReceiptScanImage? image;

  const _FakeCaptureProvider(this.image);

  @override
  Future<ReceiptScanImage?> capture(ReceiptCaptureSource source) async => image;
}

class _FakeRecognitionProvider implements ReceiptTextRecognitionProvider {
  @override
  Future<String> recognizeText(ReceiptScanImage image) async {
    return 'MERCADO DUO\nTOTAL 12,00';
  }
}

void main() {
  ReceiptScannerController createController(ReceiptScanImage? image) {
    return ReceiptScannerController(
      captureProvider: _FakeCaptureProvider(image),
      recognizeReceiptUseCase: RecognizeReceiptUseCase(
        recognitionProvider: _FakeRecognitionProvider(),
      ),
    );
  }

  test('cancelar captura não produz rascunho nem qualquer persistência', () async {
    final controller = createController(null);

    final draft = await controller.captureAndRecognize(
      ReceiptCaptureSource.gallery,
    );

    expect(draft, isNull);
    expect(controller.state, ReceiptScannerState.idle);
    expect(controller.result, isNull);
  });

  test('OCR válido termina em revisão com rascunho temporário', () async {
    final controller = createController(
      ReceiptScanImage(
        bytes: Uint8List.fromList([1]),
        mimeType: 'image/jpeg',
      ),
    );

    final draft = await controller.captureAndRecognize(
      ReceiptCaptureSource.camera,
    );

    expect(controller.state, ReceiptScannerState.reviewing);
    expect(draft?.description, 'MERCADO DUO');
    expect(draft?.amount, 12.0);
  });
}
