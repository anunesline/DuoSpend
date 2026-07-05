import 'product_knowledge_pack_item.dart';

class BrazilProductKnowledgePack {
  const BrazilProductKnowledgePack();

  List<ProductKnowledgePackItem> load() {
    return const [
      ProductKnowledgePackItem(
        canonicalName: 'Leite',
        category: 'Alimentação',
        subcategory: 'Laticínios',
        variants: [
          'Integral',
          'Desnatado',
          'Semidesnatado',
          'Zero Lactose',
        ],
        brands: [
          'Piracanjuba',
          'Italac',
          'Tirol',
          'Parmalat',
          'Frimesa',
          'Ninho',
        ],
      ),
      ProductKnowledgePackItem(
        canonicalName: 'Arroz',
        category: 'Alimentação',
        subcategory: 'Grãos',
        variants: [
          'Branco',
          'Integral',
          'Parboilizado',
        ],
        brands: [
          'Camil',
          'Tio João',
          'Namorado',
          'Prato Fino',
        ],
      ),
      ProductKnowledgePackItem(
        canonicalName: 'Feijão',
        category: 'Alimentação',
        subcategory: 'Grãos',
        variants: [
          'Carioca',
          'Preto',
          'Branco',
          'Fradinho',
        ],
        brands: [
          'Camil',
          'Kicaldo',
          'Namorado',
          'Caldo Bom',
        ],
      ),
      ProductKnowledgePackItem(
        canonicalName: 'Café',
        category: 'Alimentação',
        subcategory: 'Bebidas',
        variants: [
          'Tradicional',
          'Extra Forte',
          'Descafeinado',
        ],
        brands: [
          'Pilão',
          'Melitta',
          'Três Corações',
          'Caboclo',
        ],
      ),
      ProductKnowledgePackItem(
        canonicalName: 'Açúcar',
        category: 'Alimentação',
        subcategory: 'Mercearia',
        variants: [
          'Refinado',
          'Cristal',
          'Demerara',
          'Mascavo',
        ],
        brands: [
          'União',
          'Caravelas',
          'Da Barra',
          'Guarani',
        ],
      ),
      ProductKnowledgePackItem(
        canonicalName: 'Óleo',
        category: 'Alimentação',
        subcategory: 'Mercearia',
        variants: [
          'Soja',
          'Girassol',
          'Canola',
          'Milho',
        ],
        brands: [
          'Soya',
          'Liza',
          'Sinhá',
          'Coamo',
        ],
      ),
      ProductKnowledgePackItem(
        canonicalName: 'Macarrão',
        category: 'Alimentação',
        subcategory: 'Massas',
        variants: [
          'Espaguete',
          'Parafuso',
          'Penne',
          'Integral',
        ],
        brands: [
          'Renata',
          'Barilla',
          'Adria',
          'Dona Benta',
        ],
      ),
      ProductKnowledgePackItem(
        canonicalName: 'Detergente',
        category: 'Casa',
        subcategory: 'Limpeza',
        variants: [
          'Neutro',
          'Limão',
          'Coco',
          'Maçã',
        ],
        brands: [
          'Ypê',
          'Limpol',
          'Minuano',
          'Qualitá',
        ],
      ),
      ProductKnowledgePackItem(
        canonicalName: 'Sabão em pó',
        category: 'Casa',
        subcategory: 'Lavanderia',
        variants: [
          'Roupas brancas',
          'Roupas coloridas',
          'Lavagem pesada',
        ],
        brands: [
          'Omo',
          'Ariel',
          'Brilhante',
          'Tixan',
        ],
      ),
      ProductKnowledgePackItem(
        canonicalName: 'Ração',
        category: 'Pet',
        subcategory: 'Alimentação',
        variants: [
          'Cães',
          'Gatos',
          'Filhotes',
          'Adultos',
        ],
        brands: [
          'Golden',
          'Premier',
          'GranPlus',
          'Pedigree',
          'Whiskas',
        ],
      ),
    ];
  }
}