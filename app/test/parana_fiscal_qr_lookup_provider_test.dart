import 'package:app/features/receipt_scanner/data/providers/parana_fiscal_qr_lookup_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final provider = ParanaFiscalQrLookupProvider();
  final prQr = Uri.parse(
    'http://www.fazenda.pr.gov.br/nfce/qrcode?'
    'p=41123456789012345678901234567890123456789012%7C3%7C1',
  );

  test('reconhece QR oficial de NFC-e do Paraná', () {
    expect(provider.supports(prQr), isTrue);
  });

  test('QR de outra UF não é assumido pelo provider do Paraná', () {
    final otherStateQr = Uri.parse(
      'https://www.nfce.fazenda.sp.gov.br/qrcode?'
      'p=35123456789012345678901234567890123456789012%7C3%7C1',
    );

    expect(provider.supports(otherStateQr), isFalse);
  });

  test('consulta PR sem API estruturada preserva fallback OCR/manual',
      () async {
    expect(await provider.lookup(prQr), isNull);
  });
}
