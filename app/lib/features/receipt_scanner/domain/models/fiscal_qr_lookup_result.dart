import 'fiscal_qr_lookup_status.dart';
import 'receipt_scan_result.dart';

class FiscalQrLookupResult {
  final FiscalQrLookupStatus status;
  final Uri? uri;
  final ReceiptScanResult? receipt;

  const FiscalQrLookupResult._({
    required this.status,
    this.uri,
    this.receipt,
  });

  const FiscalQrLookupResult.invalid() : this._(status: FiscalQrLookupStatus.invalid);

  const FiscalQrLookupResult.unavailable(Uri uri)
      : this._(
          status: FiscalQrLookupStatus.unavailable,
          uri: uri,
        );

  const FiscalQrLookupResult.resolved({
    required Uri uri,
    required ReceiptScanResult receipt,
  }) : this._(
          status: FiscalQrLookupStatus.resolved,
          uri: uri,
          receipt: receipt,
        );
}
