import 'package:app/features/receipt_scanner/domain/models/receipt_scan_item.dart';
import 'package:app/features/receipt_scanner/domain/models/receipt_scan_result.dart';
import 'package:app/features/receipt_scanner/domain/models/receipt_transaction_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cria rascunho editável sem transformar OCR em transação persistida', () {
    final result = ReceiptScanResult(
      rawText: 'LOJA DUO',
      merchant: 'LOJA DUO',
      date: DateTime(2026, 8, 25),
      totalAmount: 42.50,
      paymentMethodSuggestion: 'pix',
      items: const [
        ReceiptScanItem(description: 'Produto', totalPrice: 42.50),
      ],
    );

    final draft = ReceiptTransactionDraft.fromScanResult(result);

    expect(draft.description, 'LOJA DUO');
    expect(draft.purchaseDate, DateTime(2026, 8, 25));
    expect(draft.amount, 42.50);
    expect(draft.items, hasLength(1));
    expect(draft.canContinueToTransaction, isTrue);
  });

  test('permite correção e bloqueia avanço sem descrição ou valor válido', () {
    const draft = ReceiptTransactionDraft(description: '', amount: null);

    expect(draft.canContinueToTransaction, isFalse);

    final corrected = draft.copyWith(
      description: 'Mercado corrigido',
      amount: 10,
    );

    expect(corrected.canContinueToTransaction, isTrue);
    expect(draft.description, isEmpty);
    expect(draft.amount, isNull);
  });

  test('bloqueia handoff enquanto itens e total divergirem', () {
    const draft = ReceiptTransactionDraft(
      description: 'Mercado',
      amount: 20,
      items: [
        ReceiptScanItem(description: 'Item A', totalPrice: 12),
        ReceiptScanItem(description: 'Item B', totalPrice: 7),
      ],
    );

    expect(draft.itemsTotal, 19);
    expect(draft.hasTotalDivergence, isTrue);
    expect(draft.canContinueToTransaction, isFalse);

    final corrected = draft.copyWith(amount: 19);
    expect(corrected.hasTotalDivergence, isFalse);
    expect(corrected.canContinueToTransaction, isTrue);
  });
}
