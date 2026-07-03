import 'taxonomy_item.dart';

class DuoTaxonomy {
  static const List<TaxonomyItem> items = [
    TaxonomyItem(
      id: 'food',
      name: 'Alimentação',
      icon: '🍔',
      children: [
        TaxonomyItem(
          id: 'market',
          name: 'Mercado',
          icon: '🛒',
          children: [
            TaxonomyItem(id: 'meat', name: 'Carnes', icon: '🥩'),
            TaxonomyItem(id: 'drinks', name: 'Bebidas', icon: '🥤'),
            TaxonomyItem(id: 'dairy', name: 'Laticínios', icon: '🥛'),
            TaxonomyItem(id: 'cleaning', name: 'Limpeza', icon: '🧼'),
            TaxonomyItem(id: 'hygiene', name: 'Higiene', icon: '🧻'),
            TaxonomyItem(id: 'snacks', name: 'Besteiras', icon: '🍫'),
          ],
        ),
        TaxonomyItem(
          id: 'fast_food',
          name: 'Fast food',
          icon: '🍟',
          children: [
            TaxonomyItem(id: 'pizza', name: 'Pizza', icon: '🍕'),
            TaxonomyItem(id: 'burger', name: 'Hambúrguer', icon: '🍔'),
            TaxonomyItem(id: 'hot_dog', name: 'Hot dog', icon: '🌭'),
            TaxonomyItem(id: 'delivery', name: 'Delivery', icon: '🛵'),
          ],
        ),
        TaxonomyItem(id: 'restaurant', name: 'Restaurante', icon: '🍽️'),
        TaxonomyItem(id: 'bakery', name: 'Padaria', icon: '🥐'),
      ],
    ),

    TaxonomyItem(
      id: 'transport',
      name: 'Transporte',
      icon: '🚗',
      children: [
        TaxonomyItem(id: 'fuel', name: 'Combustível', icon: '⛽'),
        TaxonomyItem(id: 'uber', name: 'Uber/99', icon: '🚘'),
        TaxonomyItem(id: 'parking', name: 'Estacionamento', icon: '🅿️'),
        TaxonomyItem(id: 'toll', name: 'Pedágio', icon: '🛣️'),
      ],
    ),

    TaxonomyItem(
      id: 'pets',
      name: 'Pets',
      icon: '🐶',
      children: [
        TaxonomyItem(id: 'robert', name: 'Robert', icon: '🐶'),
        TaxonomyItem(id: 'marieta', name: 'Marieta', icon: '🐱'),
        TaxonomyItem(id: 'pet_food', name: 'Ração', icon: '🥣'),
        TaxonomyItem(id: 'vet', name: 'Veterinário', icon: '🏥'),
        TaxonomyItem(id: 'grooming', name: 'Banho e tosa', icon: '🛁'),
      ],
    ),

    TaxonomyItem(
      id: 'home',
      name: 'Casa',
      icon: '🏠',
      children: [
        TaxonomyItem(id: 'rent', name: 'Aluguel/Financiamento', icon: '🏡'),
        TaxonomyItem(id: 'furniture', name: 'Móveis', icon: '🛋️'),
        TaxonomyItem(id: 'maintenance', name: 'Manutenção', icon: '🧰'),
        TaxonomyItem(id: 'decor', name: 'Decoração', icon: '🖼️'),
      ],
    ),

    TaxonomyItem(
      id: 'bills',
      name: 'Contas',
      icon: '💡',
      children: [
        TaxonomyItem(id: 'energy', name: 'Luz', icon: '💡'),
        TaxonomyItem(id: 'water', name: 'Água', icon: '🚿'),
        TaxonomyItem(id: 'internet', name: 'Internet', icon: '🌐'),
        TaxonomyItem(id: 'phone', name: 'Telefone', icon: '📱'),
        TaxonomyItem(id: 'subscriptions', name: 'Assinaturas', icon: '📺'),
      ],
    ),

    TaxonomyItem(
      id: 'income',
      name: 'Receita',
      icon: '💰',
      children: [
        TaxonomyItem(id: 'salary', name: 'Salário', icon: '💼'),
        TaxonomyItem(id: 'freelance', name: 'Freelance', icon: '🧑‍💻'),
        TaxonomyItem(id: 'refund', name: 'Reembolso', icon: '↩️'),
        TaxonomyItem(id: 'gift', name: 'Presente', icon: '🎁'),
      ],
    ),

    TaxonomyItem(
      id: 'other',
      name: 'Outros',
      icon: '✨',
    ),
  ];

  DuoTaxonomy._();
}