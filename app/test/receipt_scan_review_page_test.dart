import 'package:app/features/receipt_scanner/domain/models/receipt_scan_item.dart';
import 'package:app/features/receipt_scanner/domain/models/receipt_transaction_draft.dart';
import 'package:app/features/receipt_scanner/presentation/pages/receipt_scan_review_page.dart';
import 'package:app/features/transactions/data/models/product_model.dart';
import 'package:app/shared/knowledge/products/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final draft = ReceiptTransactionDraft(
    description: 'Mercado',
    purchaseDate: DateTime(2026, 9, 18),
    amount: 10,
    items: const [
      ReceiptScanItem(
        description: 'Arroz Buriti 5 kg',
        quantity: 1,
        unit: 'UN',
        unitPrice: 10,
        totalPrice: 10,
      ),
    ],
  );

  testWidgets('cancelar a revisão não devolve compra', (tester) async {
    ReceiptTransactionDraft? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                confirmed = await Navigator.push<ReceiptTransactionDraft>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceiptScanReviewPage(draft: draft),
                  ),
                );
              },
              child: const Text('Abrir revisão'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir revisão'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(confirmed, isNull);
  });

  testWidgets('vínculo escolhido e data fiscal seguem no draft confirmado', (
    tester,
  ) async {
    final repository = ProductRepository()..clearMemory();
    repository.saveSeedProduct(
      ProductModel(
        id: 'buriti',
        name: 'Arroz Buriti 5 kg',
        normalizedName: 'arroz buriti 5 kg',
        brand: 'Buriti',
        barcode: '',
        defaultUnit: 'UN',
        productCategoryId: 'alimentos',
        productCategoryName: 'Alimentos',
        taxonomyId: 'alimentos',
        averagePrice: 0,
        lastPrice: 0,
        lastMerchantId: '',
        favorite: false,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      ),
    );
    ReceiptTransactionDraft? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                confirmed = await Navigator.push<ReceiptTransactionDraft>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceiptScanReviewPage(
                      draft: draft,
                      productRepository: repository,
                    ),
                  ),
                );
              },
              child: const Text('Abrir revisão'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir revisão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arroz Buriti 5 kg'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Vincular produto existente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vincular produto existente'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Arroz Buriti 5 kg').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuar para a transação'));
    await tester.tap(find.text('Continuar para a transação'));
    await tester.pumpAndSettle();
    expect(confirmed?.purchaseDate, DateTime(2026, 9, 18));
    expect(confirmed?.items.single.productId, 'buriti');
  });
}
