import 'package:app/features/receipt_scanner/application/receipt_transaction_item_mapper.dart';
import 'package:app/features/receipt_scanner/domain/models/receipt_scan_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte itens temporários para a estrutura real sem persistir', () {
    final result = const ReceiptTransactionItemMapper().map(
      items: const [
        ReceiptScanItem(
          description: 'Arroz',
          quantity: 2,
          unitPrice: 10,
          totalPrice: 20,
        ),
      ],
      category: 'Alimentação',
      subcategory: 'Mercado',
      taxonomyId: 'mercado',
      createdAt: DateTime(2026, 8, 26),
    );

    expect(result, hasLength(1));
    expect(result.single.name, 'Arroz');
    expect(result.single.quantity, 2);
    expect(result.single.totalPrice, 20);
    expect(result.single.category, 'Alimentação');
  });

  test('descarta item incompleto em vez de inventar valor', () {
    final result = const ReceiptTransactionItemMapper().map(
      items: const [ReceiptScanItem(description: 'Item ilegível')],
      category: 'Alimentação',
      subcategory: 'Mercado',
      taxonomyId: 'mercado',
      createdAt: DateTime(2026, 8, 26),
    );

    expect(result, isEmpty);
  });
}
