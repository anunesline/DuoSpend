import '../../domain/models/receipt_scan_result.dart';
import '../../domain/repositories/fiscal_qr_lookup_provider.dart';

/// Reconhece a URL oficial de QR Code de NFC-e do Paraná.
///
/// A SEFA/PR oferece uma página pública de consulta ao consumidor, mas não uma
/// resposta estruturada e estável para consumo por aplicativo. Por isso este
/// adapter deliberadamente não faz scraping do HTML: devolve `null` para que o
/// caso de uso mantenha OCR e revisão manual como fallback seguro.
///
/// Quando a SEFA/PR disponibilizar uma API autorizada, a chamada e a
/// normalização para [ReceiptScanResult] devem ser implementadas aqui, sem
/// contaminar o domínio financeiro.
class ParanaFiscalQrLookupProvider implements FiscalQrLookupProvider {
  static const _hosts = {
    'fazenda.pr.gov.br',
    'www.fazenda.pr.gov.br',
  };

  @override
  bool supports(Uri uri) {
    if (!_hosts.contains(uri.host.toLowerCase())) return false;
    if (!uri.path.toLowerCase().contains('/nfce/qrcode')) return false;

    final rawParameters = uri.queryParameters['p'];
    if (rawParameters == null) return false;
    final parts = rawParameters.split('|');
    return parts.length >= 3 &&
        RegExp(r'^\d{44}$').hasMatch(parts[0]) &&
        parts[1] == '3' &&
        (parts[2] == '1' || parts[2] == '2');
  }

  @override
  Future<ReceiptScanResult?> lookup(Uri uri) async {
    // Não existe payload público estruturado da consulta QR da SEFA/PR.
    // Nunca substituir este retorno por parsing da página HTML do consumidor.
    return null;
  }
}
