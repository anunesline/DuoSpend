import '../models/receipt_scan_result.dart';

/// Adapter de consulta de QR fiscal. Cada UF/portal pode ter uma
/// implementação própria fora do domínio do scanner e do domínio financeiro.
abstract class FiscalQrLookupProvider {
  bool supports(Uri uri);

  Future<ReceiptScanResult?> lookup(Uri uri);
}
