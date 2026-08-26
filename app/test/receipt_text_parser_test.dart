import 'package:app/features/receipt_scanner/domain/models/receipt_scan_item.dart';
import 'package:app/features/receipt_scanner/domain/models/receipt_scan_result.dart';
import 'package:app/features/receipt_scanner/domain/services/receipt_text_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ReceiptTextParser();

  test('lê estabelecimento, data, total, pagamento e múltiplos itens', () {
    final result = parser.parse('''
MERCADO DUOSPEND
CNPJ 12.345.678/0001-00
25/08/2026
ARROZ 2 X 10,00 20,00
LEITE 5,50
TOTAL R$ 25,50
PIX
''');
    expect(result.merchant, 'MERCADO DUOSPEND');
    expect(result.date, DateTime(2026, 8, 25));
    expect(result.totalAmount, 25.5);
    expect(result.paymentMethodSuggestion, 'pix');
    expect(result.items, hasLength(2));
    expect(result.items.first.quantity, 2);
    expect(result.items.first.unitPrice, 10);
    expect(result.items.first.totalPrice, 20);
    expect(result.items.last.totalPrice, 5.5);
    expect(result.hasTotalDivergence, isFalse);
  });

  test('mantém campos ausentes e texto ilegível sem inventar dados', () {
    final result = parser.parse('@@@ texto sem valores confiáveis ###');
    expect(result.merchant, '@@@ texto sem valores confiáveis ###');
    expect(result.date, isNull);
    expect(result.totalAmount, isNull);
    expect(result.items, isEmpty);
  });

  test('informa divergência entre itens e total para revisão', () {
    final result = ReceiptScanResult(
      rawText: 'cupom',
      totalAmount: 20,
      items: const [
        ReceiptScanItem(description: 'Item A', totalPrice: 12),
        ReceiptScanItem(description: 'Item B', totalPrice: 10),
      ],
    );
    expect(result.itemsTotal, 22);
    expect(result.totalDifference, 2);
    expect(result.hasTotalDivergence, isTrue);
  });

  test('resultado pode ser corrigido pelo usuário sem persistência', () {
    final recognized = parser.parse('LOJA\nTOTAL 12,00');
    final corrected = recognized.copyWith(
      merchant: 'Loja Corrigida',
      totalAmount: 10,
      items: const [ReceiptScanItem(description: 'Produto', totalPrice: 10)],
    );
    expect(recognized.merchant, 'LOJA');
    expect(recognized.totalAmount, 12);
    expect(corrected.merchant, 'Loja Corrigida');
    expect(corrected.totalAmount, 10);
    expect(corrected.hasTotalDivergence, isFalse);
  });
}
