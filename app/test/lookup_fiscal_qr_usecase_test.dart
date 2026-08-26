import 'package:app/features/receipt_scanner/domain/models/fiscal_qr_lookup_status.dart';
import 'package:app/features/receipt_scanner/domain/models/receipt_scan_result.dart';
import 'package:app/features/receipt_scanner/domain/repositories/fiscal_qr_lookup_provider.dart';
import 'package:app/features/receipt_scanner/domain/usecases/lookup_fiscal_qr_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFiscalQrProvider implements FiscalQrLookupProvider {
  final ReceiptScanResult? result;

  const _FakeFiscalQrProvider(this.result);

  @override
  bool get canResolveStructuredReceipt => false;

  @override
  Future<ReceiptScanResult?> lookup(Uri uri) async => result;

  @override
  bool supports(Uri uri) => uri.host == 'nfce.exemplo.gov.br';
}

class _FailingFiscalQrProvider implements FiscalQrLookupProvider {
  @override
  bool get canResolveStructuredReceipt => false;

  @override
  Future<ReceiptScanResult?> lookup(Uri uri) async {
    throw StateError('Portal temporariamente indisponível');
  }

  @override
  bool supports(Uri uri) => uri.host == 'nfce.exemplo.gov.br';
}

class _StructuredFiscalQrProvider extends _FakeFiscalQrProvider {
  const _StructuredFiscalQrProvider(super.result);

  @override
  bool get canResolveStructuredReceipt => true;
}

void main() {
  test('reconhece QR fiscal válido com dados estruturados', () async {
    final useCase = LookupFiscalQrUseCase(
      providers: [
        _StructuredFiscalQrProvider(
          const ReceiptScanResult(
            rawText: '',
            merchant: 'Mercado fiscal',
            totalAmount: 18.90,
          ),
        ),
      ],
    );

    final result = await useCase('https://nfce.exemplo.gov.br/nota/123');

    expect(result.status, FiscalQrLookupStatus.resolved);
    expect(result.receipt?.merchant, 'Mercado fiscal');
  });

  test('rejeita QR que não é URL fiscal consultável', () async {
    final result = await const LookupFiscalQrUseCase().call('nota aleatória');

    expect(result.status, FiscalQrLookupStatus.invalid);
    expect(result.receipt, isNull);
  });

  test('mantém fallback quando não há provider estruturado para o QR', () async {
    final result = await const LookupFiscalQrUseCase()(
      'https://nfce.exemplo.gov.br/nota/123',
    );

    expect(result.status, FiscalQrLookupStatus.unavailable);
    expect(result.receipt, isNull);
  });

  test('falha de provider mantém QR disponível para fallback OCR/manual',
      () async {
    final result = await LookupFiscalQrUseCase(
      providers: [_FailingFiscalQrProvider()],
    )('https://nfce.exemplo.gov.br/nota/123');

    expect(result.status, FiscalQrLookupStatus.unavailable);
    expect(result.receipt, isNull);
  });

  test('só provider estruturado habilita a entrada de QR na UI', () {
    expect(
      const LookupFiscalQrUseCase(
        providers: [_FakeFiscalQrProvider(null)],
      ).hasStructuredProvider,
      isFalse,
    );
    expect(
      const LookupFiscalQrUseCase(
        providers: [_StructuredFiscalQrProvider(null)],
      ).hasStructuredProvider,
      isTrue,
    );
  });
}
