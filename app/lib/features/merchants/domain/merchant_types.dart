/// Tipos padronizados de estabelecimentos.
///
/// Evita strings espalhadas pelo projeto e facilita:
/// - filtros
/// - estatísticas
/// - IA
/// - OCR
/// - recomendações
abstract final class MerchantTypes {
  MerchantTypes._();

  static const supermarket = 'supermarket';
  static const wholesale = 'wholesale';

  static const pharmacy = 'pharmacy';
  static const petShop = 'pet_shop';

  static const restaurant = 'restaurant';
  static const snackBar = 'snack_bar';
  static const bakery = 'bakery';
  static const coffeeShop = 'coffee_shop';
  static const delivery = 'delivery';

  static const gasStation = 'gas_station';
  static const convenienceStore = 'convenience_store';

  static const ecommerce = 'ecommerce';
  static const retail = 'retail';
  static const shoppingMall = 'shopping_mall';

  static const health = 'health';
  static const education = 'education';

  static const entertainment = 'entertainment';
  static const subscription = 'subscription';

  static const transport = 'transport';
  static const travel = 'travel';

  static const home = 'home';
  static const utilities = 'utilities';

  static const bank = 'bank';
  static const government = 'government';

  static const service = 'service';
  static const other = 'other';
}