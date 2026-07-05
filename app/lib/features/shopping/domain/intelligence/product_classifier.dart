import 'product_classification_result.dart';

class ProductClassifier {
  const ProductClassifier();

  ProductClassificationResult classify(String input) {
    final rawText = input.trim();
    final normalizedText = _normalize(rawText);
    final tokens = normalizedText
        .split(' ')
        .where((token) => token.trim().isNotEmpty)
        .toList();

    final brand = _detectBrand(normalizedText);
    final variant = _detectVariant(normalizedText);
    final packageData = _detectPackage(normalizedText);
    final canonicalName = _detectCanonicalName(
      normalizedText: normalizedText,
      brand: brand,
      variant: variant,
      packageText: packageData?.text,
    );

    final confidence = _calculateConfidence(
      canonicalName: canonicalName,
      brand: brand,
      variant: variant,
      packageQuantity: packageData?.quantity,
      packageUnit: packageData?.unit,
    );

    return ProductClassificationResult(
      rawText: rawText,
      normalizedText: normalizedText,
      canonicalName: canonicalName,
      brand: brand,
      variant: variant,
      packageQuantity: packageData?.quantity,
      packageUnit: packageData?.unit,
      tokens: tokens,
      confidence: confidence,
    );
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  String _detectCanonicalName({
    required String normalizedText,
    required String? brand,
    required String? variant,
    required String? packageText,
  }) {
    final cleaned = normalizedText
        .replaceAll(brand ?? '', '')
        .replaceAll(variant ?? '', '')
        .replaceAll(packageText ?? '', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) {
      return normalizedText;
    }

    return cleaned;
  }

  String? _detectBrand(String input) {
    final brands = [
      'piracanjuba',
      'italac',
      'tirol',
      'parmalat',
      'frimesa',
      'ninho',
      'nestle',
      'tio joao',
      'camil',
      'namorado',
      'pilao',
      'melitta',
      'uniao',
      'qualita',
    ];

    for (final brand in brands) {
      if (input.contains(brand)) {
        return brand;
      }
    }

    return null;
  }

  String? _detectVariant(String input) {
    final variants = [
      'zero lactose',
      'sem lactose',
      'integral',
      'desnatado',
      'semidesnatado',
      'tradicional',
      'extra forte',
      'refinado',
      'cristal',
      'parboilizado',
      'carioca',
      'preto',
    ];

    for (final variant in variants) {
      if (input.contains(variant)) {
        return variant;
      }
    }

    return null;
  }

  _DetectedPackage? _detectPackage(String input) {
    final regex = RegExp(
      r'(\d+(?:[,.]\d+)?)\s?(kg|g|l|ml|litro|litros|un|unidade|unidades)',
    );

    final match = regex.firstMatch(input);

    if (match == null) {
      return null;
    }

    final quantityText = match.group(1)?.replaceAll(',', '.');
    final unit = match.group(2);

    if (quantityText == null || unit == null) {
      return null;
    }

    final quantity = double.tryParse(quantityText);

    if (quantity == null) {
      return null;
    }

    return _DetectedPackage(
      text: match.group(0) ?? '',
      quantity: quantity,
      unit: _normalizeUnit(unit),
    );
  }

  String _normalizeUnit(String unit) {
    switch (unit) {
      case 'litro':
      case 'litros':
        return 'l';
      case 'unidade':
      case 'unidades':
        return 'un';
      default:
        return unit;
    }
  }

  double _calculateConfidence({
    required String canonicalName,
    required String? brand,
    required String? variant,
    required double? packageQuantity,
    required String? packageUnit,
  }) {
    double confidence = 0.4;

    if (canonicalName.trim().isNotEmpty) confidence += 0.2;
    if (brand != null) confidence += 0.15;
    if (variant != null) confidence += 0.15;
    if (packageQuantity != null && packageUnit != null) confidence += 0.1;

    return confidence.clamp(0.0, 1.0);
  }
}

class _DetectedPackage {
  final String text;
  final double quantity;
  final String unit;

  const _DetectedPackage({
    required this.text,
    required this.quantity,
    required this.unit,
  });
}