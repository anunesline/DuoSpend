import 'dart:typed_data';

import 'package:duospend/features/receipt_scanner/domain/models/receipt_scan_image.dart';
import 'package:duospend/features/receipt_scanner/domain/repositories/receipt_text_recognition_provider.dart';
import 'package:duospend/features/receipt_scanner/domain/usecases/recognize_receipt_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRecognitionProvider implements ReceiptTextRecognitionProvider {
  ReceiptScanImage? receivedImage;
  final String result;

  _FakeRecognitionProvider(this.result);

  @override
  Future<String> recognizeText(ReceiptScanImage image) async {
    receivedImage = image;
    return result;
  }
}

void main() {
  test('reconhece e converte uma imagem em prévia sem persistir transação', () async {
    final provider = _FakeRecognitionProvider(
      'LOJA DUO\n25/08/2026\nTOTAL 19,90',
    );
    final useCase = RecognizeReceiptUseCase(recognitionProvider: provider);
    final image = ReceiptScanImage(
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/jpeg',
    );

    final result = await useCase(image);

    expect(provider.receivedImage, same(image));
    expect(result.merchant, 'LOJA DUO');
    expect(result.totalAmount, 19.90);
  });
}
