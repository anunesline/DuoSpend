import '../domain/merchant_model.dart';
import '../domain/merchant_types.dart';

abstract final class MerchantSeed {
  MerchantSeed._();

  static const List<MerchantModel> items = [
    // Supermercados
    MerchantModel(
      id: 'condor',
      name: 'Condor',
      type: MerchantTypes.supermarket,
      defaultFinancialCategory: 'Mercado',
      defaultFinancialSubcategory: 'Supermercado',
      aliases: [
        'condor supermercado',
        'super condor',
        'condor hipermercado',
      ],
      icon: 'storefront',
    ),
    MerchantModel(
      id: 'muffato',
      name: 'Muffato',
      type: MerchantTypes.supermarket,
      defaultFinancialCategory: 'Mercado',
      defaultFinancialSubcategory: 'Supermercado',
      aliases: [
        'super muffato',
        'grupo muffato',
        'max muffato',
      ],
      icon: 'storefront',
    ),
    MerchantModel(
      id: 'festval',
      name: 'Festval',
      type: MerchantTypes.supermarket,
      defaultFinancialCategory: 'Mercado',
      defaultFinancialSubcategory: 'Supermercado',
      aliases: [
        'festival',
        'mercado festval',
      ],
      icon: 'storefront',
    ),
    MerchantModel(
      id: 'carrefour',
      name: 'Carrefour',
      type: MerchantTypes.supermarket,
      defaultFinancialCategory: 'Mercado',
      defaultFinancialSubcategory: 'Supermercado',
      aliases: [
        'carrefour mercado',
        'carrefour hiper',
      ],
      icon: 'storefront',
    ),
    MerchantModel(
      id: 'assai',
      name: 'Assaí',
      type: MerchantTypes.wholesale,
      defaultFinancialCategory: 'Mercado',
      defaultFinancialSubcategory: 'Atacado',
      aliases: [
        'assai atacadista',
        'assaí atacadista',
        'assai',
      ],
      icon: 'storefront',
    ),
    MerchantModel(
      id: 'atacadao',
      name: 'Atacadão',
      type: MerchantTypes.wholesale,
      defaultFinancialCategory: 'Mercado',
      defaultFinancialSubcategory: 'Atacado',
      aliases: [
        'atacadao',
        'atacadão mercado',
      ],
      icon: 'storefront',
    ),
    MerchantModel(
      id: 'max_atacadista',
      name: 'Max Atacadista',
      type: MerchantTypes.wholesale,
      defaultFinancialCategory: 'Mercado',
      defaultFinancialSubcategory: 'Atacado',
      aliases: [
        'max atacadista',
        'max mercado',
      ],
      icon: 'storefront',
    ),

    // Farmácias
    MerchantModel(
      id: 'farmacias_nissei',
      name: 'Farmácias Nissei',
      type: MerchantTypes.pharmacy,
      defaultFinancialCategory: 'Saúde',
      defaultFinancialSubcategory: 'Farmácia',
      aliases: [
        'nissei',
        'farmacia nissei',
        'farmácia nissei',
      ],
      icon: 'local_pharmacy',
    ),
    MerchantModel(
      id: 'panvel',
      name: 'Panvel',
      type: MerchantTypes.pharmacy,
      defaultFinancialCategory: 'Saúde',
      defaultFinancialSubcategory: 'Farmácia',
      aliases: [
        'farmacia panvel',
        'farmácia panvel',
      ],
      icon: 'local_pharmacy',
    ),
    MerchantModel(
      id: 'droga_raia',
      name: 'Droga Raia',
      type: MerchantTypes.pharmacy,
      defaultFinancialCategory: 'Saúde',
      defaultFinancialSubcategory: 'Farmácia',
      aliases: [
        'raia',
        'drogaraia',
        'droga raia',
      ],
      icon: 'local_pharmacy',
    ),
    MerchantModel(
      id: 'drogasil',
      name: 'Drogasil',
      type: MerchantTypes.pharmacy,
      defaultFinancialCategory: 'Saúde',
      defaultFinancialSubcategory: 'Farmácia',
      aliases: [
        'droga sil',
        'farmacia drogasil',
        'farmácia drogasil',
      ],
      icon: 'local_pharmacy',
    ),

    // Delivery e alimentação
    MerchantModel(
      id: 'ifood',
      name: 'iFood',
      type: MerchantTypes.delivery,
      defaultFinancialCategory: 'Alimentação',
      defaultFinancialSubcategory: 'Delivery',
      aliases: [
        'ifood',
        'i food',
      ],
      icon: 'delivery_dining',
    ),
    MerchantModel(
      id: 'rappi',
      name: 'Rappi',
      type: MerchantTypes.delivery,
      defaultFinancialCategory: 'Alimentação',
      defaultFinancialSubcategory: 'Delivery',
      aliases: [
        'rappi delivery',
      ],
      icon: 'delivery_dining',
    ),
    MerchantModel(
      id: 'mcdonalds',
      name: "McDonald's",
      type: MerchantTypes.snackBar,
      defaultFinancialCategory: 'Alimentação',
      defaultFinancialSubcategory: 'Lanche',
      aliases: [
        'mcdonalds',
        'mc donalds',
        'mc',
        'méqui',
        'mequi',
      ],
      icon: 'fastfood',
    ),
    MerchantModel(
      id: 'burger_king',
      name: 'Burger King',
      type: MerchantTypes.snackBar,
      defaultFinancialCategory: 'Alimentação',
      defaultFinancialSubcategory: 'Lanche',
      aliases: [
        'bk',
        'burger king',
      ],
      icon: 'fastfood',
    ),

    // E-commerce
    MerchantModel(
      id: 'amazon',
      name: 'Amazon',
      type: MerchantTypes.ecommerce,
      defaultFinancialCategory: 'Compras',
      defaultFinancialSubcategory: 'E-commerce',
      aliases: [
        'amazon brasil',
        'amazon.com.br',
      ],
      icon: 'shopping_cart',
    ),
    MerchantModel(
      id: 'mercado_livre',
      name: 'Mercado Livre',
      type: MerchantTypes.ecommerce,
      defaultFinancialCategory: 'Compras',
      defaultFinancialSubcategory: 'E-commerce',
      aliases: [
        'mercadolivre',
        'mercado livre',
        'meli',
      ],
      icon: 'shopping_cart',
    ),
    MerchantModel(
      id: 'shopee',
      name: 'Shopee',
      type: MerchantTypes.ecommerce,
      defaultFinancialCategory: 'Compras',
      defaultFinancialSubcategory: 'E-commerce',
      aliases: [
        'shopee brasil',
      ],
      icon: 'shopping_cart',
    ),
    MerchantModel(
      id: 'shein',
      name: 'Shein',
      type: MerchantTypes.ecommerce,
      defaultFinancialCategory: 'Compras',
      defaultFinancialSubcategory: 'Roupas',
      aliases: [
        'shein brasil',
      ],
      icon: 'shopping_bag',
    ),

    // Pet
    MerchantModel(
      id: 'cobasi',
      name: 'Cobasi',
      type: MerchantTypes.petShop,
      defaultFinancialCategory: 'Pets',
      defaultFinancialSubcategory: 'Pet shop',
      aliases: [
        'cobasi pet',
        'cobasi petshop',
      ],
      icon: 'pets',
    ),
    MerchantModel(
      id: 'petz',
      name: 'Petz',
      type: MerchantTypes.petShop,
      defaultFinancialCategory: 'Pets',
      defaultFinancialSubcategory: 'Pet shop',
      aliases: [
        'petz petshop',
        'petz loja',
      ],
      icon: 'pets',
    ),

    // Postos e conveniência
    MerchantModel(
      id: 'shell',
      name: 'Shell',
      type: MerchantTypes.gasStation,
      defaultFinancialCategory: 'Transporte',
      defaultFinancialSubcategory: 'Combustível',
      aliases: [
        'posto shell',
        'shell box',
      ],
      icon: 'local_gas_station',
    ),
    MerchantModel(
      id: 'ipiranga',
      name: 'Ipiranga',
      type: MerchantTypes.gasStation,
      defaultFinancialCategory: 'Transporte',
      defaultFinancialSubcategory: 'Combustível',
      aliases: [
        'posto ipiranga',
        'abastece ai',
        'abastece aí',
      ],
      icon: 'local_gas_station',
    ),
    MerchantModel(
      id: 'petrobras',
      name: 'Petrobras',
      type: MerchantTypes.gasStation,
      defaultFinancialCategory: 'Transporte',
      defaultFinancialSubcategory: 'Combustível',
      aliases: [
        'posto petrobras',
        'br mania',
      ],
      icon: 'local_gas_station',
    ),

    // Casa e construção
    MerchantModel(
      id: 'leroy_merlin',
      name: 'Leroy Merlin',
      type: MerchantTypes.home,
      defaultFinancialCategory: 'Casa',
      defaultFinancialSubcategory: 'Construção e decoração',
      aliases: [
        'leroy',
        'leroy merlin',
      ],
      icon: 'home_repair_service',
    ),
    MerchantModel(
      id: 'cassol',
      name: 'Cassol',
      type: MerchantTypes.home,
      defaultFinancialCategory: 'Casa',
      defaultFinancialSubcategory: 'Construção e decoração',
      aliases: [
        'cassol centerlar',
        'cassol materiais',
      ],
      icon: 'home_repair_service',
    ),

    // Bancos e assinaturas
    MerchantModel(
      id: 'nubank',
      name: 'Nubank',
      type: MerchantTypes.bank,
      defaultFinancialCategory: 'Financeiro',
      defaultFinancialSubcategory: 'Banco',
      aliases: [
        'nu pagamentos',
        'nu bank',
      ],
      icon: 'account_balance',
    ),
    MerchantModel(
      id: 'netflix',
      name: 'Netflix',
      type: MerchantTypes.subscription,
      defaultFinancialCategory: 'Assinaturas',
      defaultFinancialSubcategory: 'Streaming',
      aliases: [
        'netflix.com',
        'netflix brasil',
      ],
      icon: 'subscriptions',
    ),
    MerchantModel(
      id: 'spotify',
      name: 'Spotify',
      type: MerchantTypes.subscription,
      defaultFinancialCategory: 'Assinaturas',
      defaultFinancialSubcategory: 'Streaming',
      aliases: [
        'spotify premium',
      ],
      icon: 'subscriptions',
    ),
    MerchantModel(
      id: 'amazon_prime',
      name: 'Amazon Prime',
      type: MerchantTypes.subscription,
      defaultFinancialCategory: 'Assinaturas',
      defaultFinancialSubcategory: 'Streaming',
      aliases: [
        'prime video',
        'amazon prime video',
      ],
      icon: 'subscriptions',
    ),
  ];
}