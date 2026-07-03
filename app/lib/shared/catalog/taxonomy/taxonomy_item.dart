class TaxonomyItem {
  final String id;
  final String name;
  final String icon;
  final List<TaxonomyItem> children;

  const TaxonomyItem({
    required this.id,
    required this.name,
    required this.icon,
    this.children = const [],
  });
}