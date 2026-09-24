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
          unit: 'UN',
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

  test('leva identidade confirmada e preserva marca e unidade', () {
    final mapped = const ReceiptTransactionItemMapper().map(
      items: const [
        ReceiptScanItem(
          description: 'Arroz Buriti 5 kg',
          brand: 'Buriti',
          productId: 'buriti-5kg',
          quantity: 2,
          unit: 'UN',
          unitPrice: 12.5,
          totalPrice: 25,
        ),
      ],
      category: 'Alimentação',
      subcategory: 'Mercado',
      taxonomyId: 'mercado',
      createdAt: DateTime(2026, 9, 23),
    );
    expect(mapped.single.productId, 'buriti-5kg');
    expect(mapped.single.brand, 'Buriti');
    expect(mapped.single.quantity, 2);
  });
}
