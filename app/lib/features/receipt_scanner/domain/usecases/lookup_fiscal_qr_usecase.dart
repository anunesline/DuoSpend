import '../models/fiscal_qr_lookup_result.dart';
import '../repositories/fiscal_qr_lookup_provider.dart';

class LookupFiscalQrUseCase {
  final List<FiscalQrLookupProvider> _providers;

  const LookupFiscalQrUseCase({
    List<FiscalQrLookupProvider> providers = const [],
  }) : _providers = providers;

  Future<FiscalQrLookupResult> call(String rawValue) async {
    final uri = Uri.tryParse(rawValue.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return const FiscalQrLookupResult.invalid();
    }

    for (final provider in _providers) {
      if (!provider.supports(uri)) continue;

      final receipt = await provider.lookup(uri);
      if (receipt != null) {
        return FiscalQrLookupResult.resolved(
          uri: uri,
          receipt: receipt,
        );
      }
    }

    return FiscalQrLookupResult.unavailable(uri);
  }
}
