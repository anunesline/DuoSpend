class ProductClassificationResult {
  final String rawText;
  final String normalizedText;
  final String canonicalName;
  final String? brand;
  final String? variant;
  final double? packageQuantity;
  final String? packageUnit;
  final List<String> tokens;
  final double confidence;

  const ProductClassificationResult({
    required this.rawText,
    required this.normalizedText,
    required this.canonicalName,
    this.brand,
    this.variant,
    this.packageQuantity,
    this.packageUnit,
    this.tokens = const [],
    this.confidence = 0.0,
  });
}