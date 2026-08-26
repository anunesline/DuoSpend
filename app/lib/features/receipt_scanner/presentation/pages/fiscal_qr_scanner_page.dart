import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Lê somente o conteúdo do QR. A consulta fiscal e qualquer fluxo
/// financeiro acontecem depois desta tela.
class FiscalQrScannerPage extends StatefulWidget {
  const FiscalQrScannerPage({super.key});

  @override
  State<FiscalQrScannerPage> createState() => _FiscalQrScannerPageState();
}

class _FiscalQrScannerPageState extends State<FiscalQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _hasReadCode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasReadCode) return;
    String? rawValue;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        rawValue = value;
        break;
      }
    }
    if (rawValue == null || rawValue.trim().isEmpty) return;

    _hasReadCode = true;
    Navigator.pop(context, rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler QR fiscal')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          const IgnorePointer(
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.white, width: 3),
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: SizedBox(width: 230, height: 230),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Text(
              'Aponte para o QR Code da nota fiscal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
