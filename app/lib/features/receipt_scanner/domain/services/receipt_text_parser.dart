import '../models/receipt_scan_item.dart';
import '../models/receipt_scan_result.dart';

/// Interpreta texto produzido pelo OCR local. Campos incertos ficam vazios.
class ReceiptTextParser {
  const ReceiptTextParser();

  ReceiptScanResult parse(String text) {
    final lines = text
        .replaceAll('\r', '')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    return ReceiptScanResult(
      rawText: text,
      merchant: _merchant(lines),
      date: _date(lines),
      subtotal: _labelledMoney(
        lines,
        RegExp(
          r'^(?:SUB\s*TOTAL|VALOR\s+DOS\s+PRODUTOS)\b',
          caseSensitive: false,
        ),
      ),
      discount: _labelledMoney(
        lines,
        RegExp(
          r'^(?:DESCONTO|DESCONTOS|TOTAL\s+DESCONTOS)\b',
          caseSensitive: false,
        ),
      ),
      totalAmount: _labelledMoney(
        lines,
        RegExp(
          r'^(?:VALOR\s+A\s+PAGAR|VALOR\s+TOTAL|TOTAL(?!\s+DESCONTOS)(?!\s+DE\s+ITENS)\s+R?\$?)\b',
          caseSensitive: false,
        ),
      ),
      paymentMethodSuggestion: _payment(text),
      items: _items(lines),
    );
  }

  String? _merchant(List<String> lines) {
    for (final line in lines.take(6)) {
      if (_irrelevant(line) || !RegExp(r'[A-Za-zÀ-ÿ]{2}').hasMatch(line))
        continue;
      return line;
    }
    return null;
  }

  DateTime? _date(List<String> lines) {
    final pattern = RegExp(r'\b(\d{2})[/.-](\d{2})[/.-](\d{2}|\d{4})\b');
    final preferred = lines.where(
      (line) => RegExp(
        r'EMISS[AÃ]O|DATA\s+DA\s+COMPRA',
        caseSensitive: false,
      ).hasMatch(line),
    );
    for (final line in [...preferred, ...lines]) {
      final match = pattern.firstMatch(line);
      if (match == null) continue;
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final rawYear = int.parse(match.group(3)!);
      final year = rawYear < 100 ? rawYear + 2000 : rawYear;
      final date = DateTime(year, month, day);
      if (date.day == day && date.month == month && date.year == year)
        return date;
    }
    return null;
  }

  double? _labelledMoney(List<String> lines, RegExp label) {
    final trailing = RegExp(r'(\d[\d.,]*[.,]\d{2})\s*$');
    for (final line in lines) {
      if (!label.hasMatch(line)) continue;
      final match = trailing.firstMatch(line);
      if (match != null) return _number(match.group(1)!);
    }
    return null;
  }

  String? _payment(String text) {
    final upper = text.toUpperCase();
    if (upper.contains('PIX')) return 'pix';
    if (upper.contains('CRÉDITO') || upper.contains('CREDITO'))
      return 'creditCard';
    if (upper.contains('DÉBITO') || upper.contains('DEBITO'))
      return 'debitCard';
    if (upper.contains('DINHEIRO')) return 'cash';
    return null;
  }

  List<ReceiptScanItem> _items(List<String> lines) {
    final result = <ReceiptScanItem>[];
    final detailed = RegExp(
      r'^(.+?)\s+(\d+(?:[.,]\d+)?)\s*(UN|UND|UNID|KG|KGS|G|GR|L|LT|ML)?\s*[Xx]\s*(\d[\d.,]*[.,]\d{2})\s+(\d[\d.,]*[.,]\d{2})$',
      caseSensitive: false,
    );
    final totalOnly = RegExp(r'^(.+?[A-Za-zÀ-ÿ].*?)\s+(\d[\d.,]*[.,]\d{2})$');
    final quantityLine = RegExp(
      r'^(?:QTD?E?\.?\s*[:.]?\s*)?(\d+(?:[.,]\d+)?)\s*(UN|UND|UNID|KG|KGS|G|GR|L|LT|ML)\s*(?:[Xx]|VL\.?\s*UNIT\.?\s*[:.]?)\s*(\d[\d.,]*[.,]\d{2})(?:\s+(?:VL\.?\s*TOTAL\s*[:.]?)?\s*(\d[\d.,]*[.,]\d{2}))?$',
      caseSensitive: false,
    );
    for (var index = 0; index < lines.length; index++) {
      var line = lines[index];
      if (_irrelevant(line)) continue;
      line = line.replaceFirst(RegExp(r'^\d{1,3}\s+'), '');
      line = line.replaceFirst(
        RegExp(r'^\(?C[ÓO]D(?:IGO)?\s*[:.]?\s*\d+\)?\s*', caseSensitive: false),
        '',
      );
      final match = detailed.firstMatch(line);
      if (match != null) {
        final quantity = _number(match.group(2)!);
        final unitPrice = _number(match.group(4)!);
        final total = _number(match.group(5)!);
        if (quantity != null &&
            quantity > 0 &&
            unitPrice != null &&
            total != null) {
          result.add(
            ReceiptScanItem(
              description: _cleanDescription(match.group(1)!.trim()),
              originalDescription: match.group(1)!.trim(),
              quantity: quantity,
              unit: _unit(match.group(3)),
              unitPrice: unitPrice,
              totalPrice: total,
            ),
          );
        }
        continue;
      }
      if (index + 1 < lines.length && !_irrelevant(lines[index + 1])) {
        final next = quantityLine.firstMatch(lines[index + 1]);
        if (next != null && RegExp(r'[A-Za-zÀ-ÿ]{2}').hasMatch(line)) {
          result.add(
            ReceiptScanItem(
              description: _cleanDescription(line),
              originalDescription: line,
              quantity: _number(next.group(1)!),
              unit: _unit(next.group(2)),
              unitPrice: _number(next.group(3)!),
              totalPrice: next.group(4) == null
                  ? null
                  : _number(next.group(4)!),
            ),
          );
          index++;
          continue;
        }
      }
      final single = totalOnly.firstMatch(line);
      if (single != null && !_irrelevant(single.group(1)!)) {
        result.add(
          ReceiptScanItem(
            description: _cleanDescription(single.group(1)!.trim()),
            originalDescription: single.group(1)!.trim(),
            totalPrice: _number(single.group(2)!),
          ),
        );
      }
    }
    return List.unmodifiable(result);
  }

  bool _irrelevant(String line) => RegExp(
    r'CNPJ|CPF|CHAVE|ACESSO|PROTOCOLO|EMISS[AÃ]O|DATA\b|TOTAL|VALOR\s+A\s+PAGAR|DESCONTO|TRIBUTO|PAGAMENTO|PIX|DINHEIRO|CR[EÉ]DITO|D[EÉ]BITO|CONSUMIDOR|ENDERE[CÇ]O|RUA\b|AVENIDA\b|DOCUMENTO|FISCAL|NFC|CUPOM|QTDE?\.?\s+TOTAL|^\d{2}[/.-]\d{2}[/.-]\d{2,4}',
    caseSensitive: false,
  ).hasMatch(line);

  String _cleanDescription(String value) => value
      .replaceAll(
        RegExp(r'\s*\(?C[ÓO]D(?:IGO)?\s*[:.]\s*\d+\)?', caseSensitive: false),
        '',
      )
      .trim();

  String? _unit(String? value) {
    if (value == null) return null;
    final normalized = value.toUpperCase();
    if (const ['UND', 'UNID'].contains(normalized)) return 'UN';
    if (normalized == 'KGS') return 'KG';
    if (normalized == 'GR') return 'G';
    if (normalized == 'LT') return 'L';
    return normalized;
  }

  double? _number(String value) {
    final input = value.trim();
    if (!RegExp(r'^\d[\d.,]*$').hasMatch(input)) return null;
    final comma = input.lastIndexOf(',');
    final dot = input.lastIndexOf('.');
    final separator = comma > dot ? comma : dot;
    if (separator < 0) return double.tryParse(input);
    final integer = input
        .substring(0, separator)
        .replaceAll(RegExp(r'[.,]'), '');
    final fractional = input.substring(separator + 1);
    if (fractional.length > 3 || fractional.isEmpty) return null;
    return double.tryParse('$integer.$fractional');
  }
}
