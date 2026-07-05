import '../models/shopping_item_model.dart';

abstract class ShoppingRepository {
  /// Cria um novo item na lista de compras.
  Future<void> createItem(ShoppingItemModel item);

  /// Atualiza um item existente.
  Future<void> updateItem(ShoppingItemModel item);

  /// Remove um item da lista.
  Future<void> deleteItem(String itemId);

  /// Obtém um item pelo ID.
  Future<ShoppingItemModel?> getItemById(String itemId);

  /// Retorna todos os itens da lista.
  Future<List<ShoppingItemModel>> getAllItems();

  /// Retorna apenas os itens pendentes.
  Future<List<ShoppingItemModel>> getPendingItems();

  /// Retorna apenas os itens comprados.
  Future<List<ShoppingItemModel>> getPurchasedItems();

  /// Marca um item como comprado.
  Future<void> markAsPurchased(String itemId);

  /// Arquiva um item.
  Future<void> archiveItem(String itemId);

  /// Retorna sugestões inteligentes.
  ///
  /// No início pode retornar vazio.
  /// Futuramente será alimentado por Product Memory,
  /// Purchase History e IA.
  Future<List<ShoppingItemModel>> getSuggestions();

  /// Pesquisa itens.
  Future<List<ShoppingItemModel>> search(String query);

  /// Limpa todos os itens arquivados.
  Future<void> clearArchive();
}