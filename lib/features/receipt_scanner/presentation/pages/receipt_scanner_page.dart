import 'package:flutter/material.dart';

import '../../data/providers/google_mlkit_receipt_text_recognition_provider.dart';
import '../../data/providers/image_picker_receipt_image_capture_provider.dart';
import '../../data/providers/parana_fiscal_qr_lookup_provider.dart';
import '../../domain/models/fiscal_qr_lookup_status.dart';
import '../../domain/models/receipt_capture_source.dart';
import '../../domain/models/receipt_transaction_draft.dart';
import '../../domain/usecases/lookup_fiscal_qr_usecase.dart';
import '../../domain/usecases/recognize_receipt_usecase.dart';
import '../controllers/receipt_scanner_controller.dart';
import 'fiscal_qr_scanner_page.dart';
import 'receipt_scan_review_page.dart';

class ReceiptScannerPage extends StatefulWidget {
  const ReceiptScannerPage({super.key});

  @override
  State<ReceiptScannerPage> createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends State<ReceiptScannerPage> {
  late final ReceiptScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReceiptScannerController(
      captureProvider: ImagePickerReceiptImageCaptureProvider(),
      recognizeReceiptUseCase: RecognizeReceiptUseCase(
        recognitionProvider: GoogleMlKitReceiptTextRecognitionProvider(),
      ),
      lookupFiscalQrUseCase: LookupFiscalQrUseCase(
        providers: [ParanaFiscalQrLookupProvider()],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _capture(ReceiptCaptureSource source) async {
    final draft = await _controller.captureAndRecognize(source);
    if (!mounted || draft == null) return;
    await _review(draft);
  }

  Future<void> _scanQr() async {
    final rawValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const FiscalQrScannerPage()),
    );
    if (!mounted || rawValue == null) return;

    final lookup = await _controller.lookupFiscalQr(rawValue);
    if (!mounted) return;
    if (lookup.status == FiscalQrLookupStatus.resolved &&
        _controller.draft != null) {
      await _review(_controller.draft!);
      return;
    }

    final message = lookup.status == FiscalQrLookupStatus.invalid
        ? 'Este QR não parece ser uma nota fiscal consultável.'
        : 'Não há consulta estruturada disponível para este QR. Use uma foto da nota.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _review(ReceiptTransactionDraft draft) async {
    final reviewedDraft = await Navigator.push<ReceiptTransactionDraft>(
      context,
      MaterialPageRoute(builder: (_) => ReceiptScanReviewPage(draft: draft)),
    );
    if (!mounted || reviewedDraft == null) return;
    Navigator.pop(context, reviewedDraft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner fiscal')),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final isLoading = _controller.state == ReceiptScannerState.capturing ||
              _controller.state == ReceiptScannerState.recognizing;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Leia o QR fiscal ou escolha uma imagem da nota. Você poderá revisar tudo antes de criar a transação.',
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: isLoading ? null : _scanQr,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Ler QR fiscal'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => _capture(ReceiptCaptureSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Fotografar nota'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => _capture(ReceiptCaptureSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Escolher da galeria'),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 28),
                  const Center(child: CircularProgressIndicator()),
                ],
                const Spacer(),
                const Text(
                  'O scanner não cria, movimenta ou confirma dinheiro.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
