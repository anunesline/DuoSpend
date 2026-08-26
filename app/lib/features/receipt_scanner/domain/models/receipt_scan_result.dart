import 'receipt_scan_item.dart';

class ReceiptScanResult {
  final String rawText;
  final String? merchant;
  final DateTime? date;
  final double? totalAmount;
  final String? paymentMethodSuggestion;
  final List<ReceiptScanItem> items;

  const ReceiptScanResult({
    required this.rawText,
    this.merchant,
    this.date,
    this.totalAmount,
    this.paymentMethodSuggestion,
    this.items = const [],
  });

  double? get itemsTotal {
    if (items.isEmpty || items.any((item) => item.totalPrice == null)) {
      return null;
    }

    return items.fold<double>(
      0,
      (total, item) => total + item.totalPrice!,
    );
  }

  double? get totalDifference {
    final scannedItemsTotal = itemsTotal;

    if (totalAmount == null || scannedItemsTotal == null) {
      return null;
    }

    return _roundCurrency(scannedItemsTotal - totalAmount!);
  }

  bool get hasTotalDivergence {
    final difference = totalDifference;
    return difference != null && difference.abs() >= 0.01;
  }

  bool get hasRecognizedData {
    return merchant != null || date != null || totalAmount != null || items.isNotEmpty;
  }

  ReceiptScanResult copyWith({
    String? rawText,
    String? merchant,
    DateTime? date,
    double? totalAmount,
    String? paymentMethodSuggestion,
    List<ReceiptScanItem>? items,
    bool clearMerchant = false,
    bool clearDate = false,
    bool clearTotalAmount = false,
    bool clearPaymentMethodSuggestion = false,
  }) {
    return ReceiptScanResult(
      rawText: rawText ?? this.rawText,
      merchant: clearMerchant ? null : merchant ?? this.merchant,
      date: clearDate ? null : date ?? this.date,
      totalAmount: clearTotalAmount ? null : totalAmount ?? this.totalAmount,
      paymentMethodSuggestion: clearPaymentMethodSuggestion
          ? null
          : paymentMethodSuggestion ?? this.paymentMethodSuggestion,
      items: items ?? this.items,
    );
  }

  double _roundCurrency(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
