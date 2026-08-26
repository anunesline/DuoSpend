import '../models/receipt_scan_result.dart';

/// Adapter de consulta de QR fiscal. Cada UF/portal pode ter uma
/// implementação própria fora do domínio do scanner e do domínio financeiro.
abstract class FiscalQrLookupProvider {
  /// Reconhecer uma URL não basta para oferecer QR na UI: somente providers
  /// capazes de devolver dados estruturados devem habilitar essa entrada.
  bool get canResolveStructuredReceipt => false;

  bool supports(Uri uri);

  Future<ReceiptScanResult?> lookup(Uri uri);
}
