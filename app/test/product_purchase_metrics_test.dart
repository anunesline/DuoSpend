import 'package:app/shared/knowledge/products/product_price_observation.dart';
import 'package:app/shared/knowledge/products/product_purchase_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

ProductPriceObservation _observation({
  required String purchaseId,
  required DateTime purchasedAt,
  required double unitPrice,
  required double quantity,
  String productId = 'coffee',
  String? merchantId,
  String? merchantName,
  String? categoryId,
  String? categoryName,
  double? totalPrice,
}) {
  return ProductPriceObservation(
    productId: productId,
    purchaseId: purchaseId,
    purchasedAt: purchasedAt,
    unitPrice: unitPrice,
    quantity: quantity,
    merchantId: merchantId,
    merchantName: merchantName,
    productCategoryId: categoryId,
    productCategoryName: categoryName,
    totalPrice: totalPrice,
  );
}

void main() {
  const calculator = ProductPurchaseMetricsCalculator();

  test(
    'deriva preços, variação, quantidade, gastos, frequência e recorrência',
    () {
      final metrics = calculator.calculate(
        productId: 'coffee',
        observations: [
          _observation(
            purchaseId: 'purchase-3',
            purchasedAt: DateTime(2026, 1, 15),
            unitPrice: 15,
            quantity: 3,
            merchantId: 'market-b',
            merchantName: 'Mercado B',
            categoryId: 'grocery',
            categoryName: 'Mercearia',
          ),
          _observation(
            purchaseId: 'purchase-1',
            purchasedAt: DateTime(2026, 1, 1),
            unitPrice: 10,
            quantity: 2,
            merchantId: 'market-a',
            merchantName: 'Mercado A',
            categoryId: 'grocery',
            categoryName: 'Mercearia',
          ),
          _observation(
            purchaseId: 'purchase-2',
            purchasedAt: DateTime(2026, 1, 8),
            unitPrice: 12,
            quantity: 1,
            merchantId: 'market-a',
            merchantName: 'Mercado A',
            categoryId: 'grocery',
            categoryName: 'Mercearia',
          ),
        ],
      );

      expect(metrics.history.map((observation) => observation.purchaseId), [
        'purchase-1',
        'purchase-2',
        'purchase-3',
      ]);
      expect(metrics.lastUnitPrice, 15);
      expect(metrics.averageUnitPrice, closeTo(37 / 3, 0.0001));
      expect(metrics.minimumUnitPrice, 10);
      expect(metrics.maximumUnitPrice, 15);
      expect(metrics.absolutePriceVariation, 3);
      expect(metrics.percentagePriceVariation, 25);
      expect(metrics.lastPurchase?.merchantName, 'Mercado B');
      expect(metrics.lastPurchasedQuantity, 3);
      expect(metrics.totalQuantity, 6);
      expect(metrics.totalSpent, 77);
      expect(metrics.averagePurchaseInterval, const Duration(days: 7));
      expect(metrics.purchaseFrequencyPer30Days, closeTo(60 / 14, 0.0001));
      expect(metrics.probableRecurrence, isNotNull);
      expect(
        metrics.probableRecurrence?.nextExpectedPurchaseAt,
        DateTime(2026, 1, 22),
      );

      expect(metrics.spendingByMerchant, hasLength(2));
      expect(metrics.spendingByMerchant.first.id, 'market-b');
      expect(metrics.spendingByMerchant.first.totalSpent, 45);
      expect(metrics.spendingByMerchant.last.id, 'market-a');
      expect(metrics.spendingByMerchant.last.totalSpent, 32);
      expect(metrics.spendingByCategory.single.id, 'grocery');
      expect(metrics.spendingByCategory.single.totalSpent, 77);
    },
  );

  test('uma compra não inventa variação, frequência ou recorrência', () {
    final metrics = calculator.calculate(
      productId: 'coffee',
      observations: [
        _observation(
          purchaseId: 'only',
          purchasedAt: DateTime(2026, 1, 1),
          unitPrice: 10,
          quantity: 2,
        ),
      ],
    );

    expect(metrics.absolutePriceVariation, isNull);
    expect(metrics.percentagePriceVariation, isNull);
    expect(metrics.purchaseFrequencyPer30Days, isNull);
    expect(metrics.averagePurchaseInterval, isNull);
    expect(metrics.probableRecurrence, isNull);
    expect(metrics.spendingByMerchant, isEmpty);
    expect(metrics.spendingByCategory, isEmpty);
  });

  test('intervalos irregulares não são classificados como recorrência', () {
    final metrics = calculator.calculate(
      productId: 'coffee',
      observations: [
        _observation(
          purchaseId: 'p1',
          purchasedAt: DateTime(2026, 1, 1),
          unitPrice: 10,
          quantity: 1,
        ),
        _observation(
          purchaseId: 'p2',
          purchasedAt: DateTime(2026, 1, 3),
          unitPrice: 10,
          quantity: 1,
        ),
        _observation(
          purchaseId: 'p3',
          purchasedAt: DateTime(2026, 2, 3),
          unitPrice: 10,
          quantity: 1,
        ),
      ],
    );

    expect(metrics.probableRecurrence, isNull);
  });

  test(
    'observação legada preserva dados e calcula total sem inventar campos',
    () {
      final legacy = ProductPriceObservation.fromMap({
        'purchaseId': 'legacy-purchase',
        'purchasedAt': '2025-12-01T00:00:00.000',
        'unitPrice': 8,
        'quantity': 2,
        'merchantId': 'legacy-market',
      }, fallbackProductId: 'coffee');
      final metrics = calculator.calculate(
        productId: 'coffee',
        observations: [legacy],
      );

      expect(legacy.productId, 'coffee');
      expect(legacy.observedTotal, 16);
      expect(legacy.merchantName, isNull);
      expect(legacy.productCategoryName, isNull);
      expect(metrics.totalSpent, 16);
      expect(metrics.spendingByMerchant.single.id, 'legacy-market');
      expect(metrics.spendingByCategory, isEmpty);
    },
  );

  test('dados inválidos ou de outro produto não contaminam as métricas', () {
    final metrics = calculator.calculate(
      productId: 'coffee',
      observations: [
        _observation(
          purchaseId: 'valid',
          purchasedAt: DateTime(2026, 1, 1),
          unitPrice: 10,
          quantity: 1,
        ),
        _observation(
          purchaseId: 'wrong-product',
          productId: 'tea',
          purchasedAt: DateTime(2026, 1, 2),
          unitPrice: 100,
          quantity: 1,
        ),
        _observation(
          purchaseId: 'zero-price',
          purchasedAt: DateTime(2026, 1, 3),
          unitPrice: 0,
          quantity: 1,
        ),
        _observation(
          purchaseId: '',
          purchasedAt: DateTime(2026, 1, 4),
          unitPrice: 20,
          quantity: 1,
        ),
      ],
    );

    expect(metrics.history, hasLength(1));
    expect(metrics.totalSpent, 10);
  });
}
