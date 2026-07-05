import '../models/shopping_item_model.dart';

class ShoppingIntelligenceService {
  const ShoppingIntelligenceService();

  /// Normaliza o nome do produto.
  String normalizeName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Verifica se dois produtos são equivalentes.
  bool areEquivalent(
    ShoppingItemModel first,
    ShoppingItemModel second,
  ) {
    return normalizeName(first.name) ==
        normalizeName(second.name);
  }

  /// Evita adicionar produtos duplicados.
  bool shouldCreateItem({
    required ShoppingItemModel newItem,
    required List<ShoppingItemModel> existingItems,
  }) {
    return !existingItems.any(
      (item) => areEquivalent(item, newItem),
    );
  }

  /// Sugere unidade padrão.
  String suggestUnit(String? currentUnit) {
    if (currentUnit == null || currentUnit.trim().isEmpty) {
      return 'un';
    }

    return currentUnit.trim();
  }

  /// Garante quantidade mínima.
  double normalizeQuantity(double quantity) {
    return quantity <= 0 ? 1 : quantity;
  }

  /// Futuramente:
  ///
  /// - analisar Product Memory
  /// - analisar Purchase History
  /// - sugerir mercado
  /// - sugerir preço
  /// - sugerir categoria
  /// - prever reposição
}