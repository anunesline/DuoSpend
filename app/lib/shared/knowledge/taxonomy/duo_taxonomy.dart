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
            TaxonomyItem(id: 'grains', name: 'Grãos e cereais', icon: '🌾'),
            TaxonomyItem(id: 'cleaning', name: 'Limpeza', icon: '🧼'),
            TaxonomyItem(id: 'hygiene', name: 'Higiene', icon: '🧻'),
            TaxonomyItem(id: 'produce', name: 'Hortifrúti', icon: '🥬'),
            TaxonomyItem(
              id: 'bakery_products',
              name: 'Padaria e massas',
              icon: '🍞',
            ),
            TaxonomyItem(id: 'frozen', name: 'Congelados', icon: '🧊'),
            TaxonomyItem(
              id: 'condiments',
              name: 'Temperos e molhos',
              icon: '🧂',
            ),
            TaxonomyItem(id: 'snacks', name: 'Doces e snacks', icon: '🍫'),
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
        TaxonomyItem(
          id: 'public_transport',
          name: 'Transporte público',
          icon: '🚌',
        ),
        TaxonomyItem(
          id: 'vehicle_maintenance',
          name: 'Manutenção do veículo',
          icon: '🔧',
        ),
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
        TaxonomyItem(
          id: 'pet_medication',
          name: 'Medicamentos',
          icon: '💊',
        ),
        TaxonomyItem(
          id: 'pet_accessories',
          name: 'Acessórios',
          icon: '🦴',
        ),
      ],
    ),
    TaxonomyItem(
      id: 'home',
      name: 'Casa',
      icon: '🏠',
      children: [
        TaxonomyItem(
          id: 'rent',
          name: 'Aluguel/Financiamento',
          icon: '🏡',
        ),
        TaxonomyItem(id: 'energy', name: 'Luz', icon: '💡'),
        TaxonomyItem(id: 'water', name: 'Água', icon: '🚿'),
        TaxonomyItem(id: 'internet', name: 'Internet', icon: '🌐'),
        TaxonomyItem(id: 'phone', name: 'Telefone', icon: '📱'),
        TaxonomyItem(
          id: 'subscriptions',
          name: 'Assinaturas',
          icon: '📺',
        ),
        TaxonomyItem(id: 'furniture', name: 'Móveis', icon: '🛋️'),
        TaxonomyItem(id: 'maintenance', name: 'Manutenção', icon: '🧰'),
        TaxonomyItem(id: 'decor', name: 'Decoração', icon: '🖼️'),
        TaxonomyItem(
          id: 'household_items',
          name: 'Utensílios domésticos',
          icon: '🍽️',
        ),
        TaxonomyItem(
          id: 'condominium',
          name: 'Condomínio',
          icon: '🏢',
        ),
        TaxonomyItem(
          id: 'property_tax',
          name: 'IPTU',
          icon: '🧾',
        ),
      ],
    ),
    TaxonomyItem(
      id: 'health',
      name: 'Saúde',
      icon: '❤️',
      children: [
        TaxonomyItem(
          id: 'medication',
          name: 'Medicamentos',
          icon: '💊',
        ),
        TaxonomyItem(
          id: 'medical_appointment',
          name: 'Consultas',
          icon: '🩺',
        ),
        TaxonomyItem(id: 'exams', name: 'Exames', icon: '🔬'),
        TaxonomyItem(
          id: 'health_insurance',
          name: 'Plano de saúde',
          icon: '🏥',
        ),
        TaxonomyItem(id: 'dentist', name: 'Dentista', icon: '🦷'),
      ],
    ),
    TaxonomyItem(
      id: 'personal',
      name: 'Pessoal',
      icon: '👤',
      children: [
        TaxonomyItem(id: 'clothing', name: 'Roupas', icon: '👕'),
        TaxonomyItem(id: 'beauty', name: 'Beleza', icon: '💄'),
        TaxonomyItem(
          id: 'personal_care',
          name: 'Cuidados pessoais',
          icon: '🧴',
        ),
        TaxonomyItem(id: 'education', name: 'Educação', icon: '📚'),
      ],
    ),
    TaxonomyItem(
      id: 'leisure',
      name: 'Lazer',
      icon: '🎉',
      children: [
        TaxonomyItem(id: 'travel', name: 'Viagens', icon: '✈️'),
        TaxonomyItem(id: 'cinema', name: 'Cinema', icon: '🎬'),
        TaxonomyItem(id: 'games', name: 'Jogos', icon: '🎮'),
        TaxonomyItem(id: 'events', name: 'Eventos', icon: '🎟️'),
        TaxonomyItem(id: 'bars', name: 'Bares', icon: '🍻'),
      ],
    ),
    TaxonomyItem(
      id: 'financial',
      name: 'Financeiro',
      icon: '🏦',
      children: [
        TaxonomyItem(
          id: 'credit_card',
          name: 'Cartão de crédito',
          icon: '💳',
        ),
        TaxonomyItem(id: 'loan', name: 'Empréstimo', icon: '💸'),
        TaxonomyItem(id: 'fees', name: 'Taxas', icon: '🧾'),
        TaxonomyItem(id: 'interest', name: 'Juros', icon: '📈'),
        TaxonomyItem(
          id: 'insurance',
          name: 'Seguros',
          icon: '🛡️',
        ),
      ],
    ),
    TaxonomyItem(
      id: 'income',
      name: 'Receita',
      icon: '💰',
      children: [
        TaxonomyItem(id: 'salary', name: 'Salário', icon: '💼'),
        TaxonomyItem(id: 'freelance', name: 'Freelance', icon: '🧑‍💻'),
        TaxonomyItem(id: 'commission', name: 'Comissão', icon: '📊'),
        TaxonomyItem(id: 'refund', name: 'Reembolso', icon: '↩️'),
        TaxonomyItem(id: 'gift', name: 'Presente', icon: '🎁'),
        TaxonomyItem(
          id: 'investment_income',
          name: 'Rendimentos',
          icon: '📈',
        ),
        TaxonomyItem(
          id: 'other_income',
          name: 'Outra receita',
          icon: '💵',
        ),
      ],
    ),
    TaxonomyItem(
      id: 'other',
      name: 'Outros',
      icon: '✨',
      children: [
        TaxonomyItem(
          id: 'tobacco',
          name: 'Tabaco',
          icon: '🚬',
        ),
        TaxonomyItem(
          id: 'gifts_and_donations',
          name: 'Presentes e doações',
          icon: '🎁',
        ),
        TaxonomyItem(
          id: 'documents',
          name: 'Documentos e taxas',
          icon: '📄',
        ),
        TaxonomyItem(
          id: 'uncategorized_expense',
          name: 'Despesa não classificada',
          icon: '📦',
        ),
      ],
    ),
  ];

  DuoTaxonomy._();
}