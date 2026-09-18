import 'package:app/features/transactions/domain/purchase/models/purchase_item_model.dart';
import 'package:app/features/transactions/domain/purchase/repositories/purchase_repository.dart';
import 'package:app/features/transactions/presentation/controllers/purchase_controller.dart';
import 'package:app/features/transactions/presentation/widgets/new_transaction_surface.dart';
import 'package:app/shared/knowledge/products/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnusedRepository extends Fake implements PurchaseRepository {}

PurchaseItemModel _item() => PurchaseItemModel(
  id: 'item',
  purchaseId: 'purchase',
  name: 'Arroz integral',
  brand: 'Marca real',
  quantity: 1,
  unit: 'un',
  unitPrice: 8.9,
  totalPrice: 8.9,
  taxonomyId: 'grains',
  financialCategory: 'Alimentação',
  financialSubcategory: 'Mercado',
  productCategoryId: 'grains',
  productCategoryName: 'Grãos',
  createdAt: DateTime(2026),
);

void main() {
  testWidgets(
    'quantidade tem mínimo um e permite incrementos sem abrir edição',
    (tester) async {
      double quantity = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (_, update) => TransactionQuantityControl(
                quantity: quantity,
                onChanged: (value) => update(() => quantity = value),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Diminuir quantidade'));
      expect(quantity, 1);
      await tester.tap(find.byTooltip('Aumentar quantidade'));
      await tester.pump();
      expect(quantity, 2);
      await tester.tap(find.byTooltip('Diminuir quantidade'));
      await tester.pump();
      expect(quantity, 1);
    },
  );

  testWidgets('sheet reflete total, seleção, busca e edição do controller', (
    tester,
  ) async {
    final controller = PurchaseController(
      purchaseRepository: _UnusedRepository(),
    );
    final products = ProductRepository();
    controller.addPurchaseItem(_item());
    int edits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewTransactionItemsSheet(
            controller: controller,
            productRepository: products,
            onAdd: (_) async {},
            onEdit: (_) async {
              edits++;
            },
            onScan: () {},
            onRemove: (item) => controller.removeItem(item.id),
            onRestore: controller.addPurchaseItem,
            onQuantityChanged: (item, quantity) =>
                controller.updatePurchaseItem(
                  originalItemId: item.id,
                  updatedItem: item.copyWith(
                    quantity: quantity,
                    totalPrice: item.unitPrice * quantity,
                  ),
                ),
          ),
        ),
      ),
    );
    expect(find.text('1 item selecionado'), findsOneWidget);
    await tester.tap(find.byTooltip('Aumentar quantidade'));
    await tester.pump();
    expect(controller.total, 17.8);
    expect(edits, 0);
    expect(find.textContaining('17,80'), findsNWidgets(2));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(controller.items, isEmpty);
    expect(find.text('0 itens selecionados'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(controller.total, 17.8);
    expect(controller.items.single.id, 'item');
    await tester.tap(find.text('Arroz integral'));
    await tester.pump();
    expect(edits, 1);
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pump();
    expect(find.text('Nenhum item encontrado.'), findsOneWidget);
    expect(controller.total, 17.8);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('sheet e campos sem overflow em $width px', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = PurchaseController(
        purchaseRepository: _UnusedRepository(),
      );
      controller.addPurchaseItem(_item());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TransactionTypeTabs(type: 'expense', onChanged: (_) {}),
                TransactionPanel(
                  child: TransactionField(
                    icon: Icons.calendar_month,
                    label: 'Data',
                    value: '23 de maio de 2026',
                    onTap: () {},
                    trailing: TextButton(
                      onPressed: () {},
                      child: const Text('Hoje'),
                    ),
                  ),
                ),
                Expanded(
                  child: NewTransactionItemsSheet(
                    controller: controller,
                    productRepository: ProductRepository(),
                    onAdd: (_) async {},
                    onEdit: (_) async {},
                    onRemove: (_) {},
                    onRestore: (_) {},
                    onQuantityChanged: (_, _) {},
                    onScan: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  }
}
