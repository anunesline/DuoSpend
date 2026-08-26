import '../models/receipt_scan_item.dart';
import '../models/receipt_scan_result.dart';

class ReceiptTextParser {
  const ReceiptTextParser();

  ReceiptScanResult parse(String text) {
    final normalizedText = text.replaceAll('\r', '');
    final lines = normalizedText.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList(growable: false);
    return ReceiptScanResult(
      rawText: text,
      merchant: _findMerchant(lines),
      date: _findDate(normalizedText),
      totalAmount: _findTotal(normalizedText),
      paymentMethodSuggestion: _findPaymentMethod(normalizedText),
      items: _findItems(lines),
    );
  }

  String? _findMerchant(List<String> lines) {
    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.contains('CNPJ') || upper.contains('TOTAL') || RegExp(r'^\d{2}/\d{2}/\d{2,4}').hasMatch(line)) continue;
      return line;
    }
    return null;
  }

  DateTime? _findDate(String text) {
    final match = RegExp(r'\b(\d{2})/(\d{2})/(\d{2,4})\b').firstMatch(text);
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final rawYear = int.tryParse(match.group(3)!);
    if (day == null || month == null || rawYear == null) return null;
    final year = rawYear < 100 ? 2000 + rawYear : rawYear;
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day ? date : null;
  }

  double? _findTotal(String text) {
    final match = RegExp(r'(?:VALOR\s+)?TOTAL\s*[:R$]*\s*([\d.,]+)', caseSensitive: false).firstMatch(text);
    return match == null ? null : _parseMoney(match.group(1)!);
  }

  String? _findPaymentMethod(String text) {
    final upper = text.toUpperCase();
    if (upper.contains('PIX')) return 'pix';
    if (upper.contains('CRÉDITO') || upper.contains('CREDITO')) return 'creditCard';
    if (upper.contains('DÉBITO') || upper.contains('DEBITO')) return 'debitCard';
    if (upper.contains('DINHEIRO')) return 'cash';
    return null;
  }

  List<ReceiptScanItem> _findItems(List<String> lines) {
    final items = <ReceiptScanItem>[];
    final quantityPattern = RegExp(r'^(.+?)\s+(\d+(?:[.,]\d+)?)\s*[Xx]\s*([\d.,]+)\s+([\d.,]+)$');
    final totalOnlyPattern = RegExp(r'^(.+?)\s+([\d.,]+)$');
    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.contains('TOTAL') || upper.contains('CNPJ') || upper.contains('PIX')) continue;
      final quantityMatch = quantityPattern.firstMatch(line);
      if (quantityMatch != null) {
        final quantity = _parseNumber(quantityMatch.group(2)!);
        final unitPrice = _parseMoney(quantityMatch.group(3)!);
        final totalPrice = _parseMoney(quantityMatch.group(4)!);
        if (quantity != null && unitPrice != null && totalPrice != null) {
          items.add(ReceiptScanItem(description: quantityMatch.group(1)!.trim(), quantity: quantity, unitPrice: unitPrice, totalPrice: totalPrice));
        }
        continue;
      }
      final match = totalOnlyPattern.firstMatch(line);
      if (match == null) continue;
      final totalPrice = _parseMoney(match.group(2)!);
      final description = match.group(1)!.trim();
      if (totalPrice != null && description.length > 1 && !RegExp(r'^\d').hasMatch(description)) {
        items.add(ReceiptScanItem(description: description, totalPrice: totalPrice));
      }
    }
    return List.unmodifiable(items);
  }

  double? _parseNumber(String value) => double.tryParse(value.replaceAll(',', '.'));

  double? _parseMoney(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[^\d,.-]'), '');
    if (normalized.isEmpty) return null;
    final commaIndex = normalized.lastIndexOf(',');
    final dotIndex = normalized.lastIndexOf('.');
    final decimalIndex = commaIndex > dotIndex ? commaIndex : dotIndex;
    final digits = normalized.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    if (decimalIndex == -1) return double.tryParse(digits);
    final decimalPlaces = normalized.length - decimalIndex - 1;
    final parsed = double.tryParse(digits);
    if (parsed == null || decimalPlaces <= 0) return parsed;
    var divisor = 1.0;
    for (var index = 0; index < decimalPlaces; index++) { divisor *= 10; }
    return parsed / divisor;
  }
}
