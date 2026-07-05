class ProductKnowledgePackItem {
  final String canonicalName;
  final String category;
  final String subcategory;
  final List<String> variants;
  final List<String> brands;

  const ProductKnowledgePackItem({
    required this.canonicalName,
    required this.category,
    required this.subcategory,
    this.variants = const [],
    this.brands = const [],
  });
}