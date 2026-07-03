class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final List<String> subcategories;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.subcategories,
  });
}