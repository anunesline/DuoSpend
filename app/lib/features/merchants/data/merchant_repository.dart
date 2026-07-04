import '../domain/merchant_model.dart';
import '../domain/merchant_types.dart';
import 'merchant_memory_repository.dart';
import 'merchant_seed.dart';

class MerchantRepository {
  MerchantRepository({
    MerchantMemoryRepository? memoryRepository,
  }) : _memoryRepository = memoryRepository ?? MerchantMemoryRepository();

  final MerchantMemoryRepository _memoryRepository;

  List<MerchantModel> getAll() {
    return MerchantSeed.items;
  }

  Future<List<MerchantModel>> getAllWithMemory() async {
    final memories = await _memoryRepository.getAllMemories();

    final memoryMerchants = memories.map((memory) {
      return MerchantModel(
        id: memory.merchantId,
        name: memory.merchantName,
        type: MerchantTypes.other,
        defaultFinancialCategory: 'Compras',
        defaultFinancialSubcategory: 'Outros',
        aliases: [memory.merchantName],
        icon: 'storefront',
        updatedAt: memory.lastPurchaseAt,
      );
    }).toList();

    final seedIds = MerchantSeed.items.map((merchant) => merchant.id).toSet();

    final filteredMemoryMerchants = memoryMerchants.where((merchant) {
      return !seedIds.contains(merchant.id);
    }).toList();

    return [
      ...MerchantSeed.items,
      ...filteredMemoryMerchants,
    ];
  }

  List<MerchantModel> search(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return [];
    }

    return MerchantSeed.items.where((merchant) {
      return merchant.matches(normalizedQuery);
    }).toList();
  }

  Future<List<MerchantModel>> searchWithMemory(String query) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return [];
    }

    final seedResults = search(query);
    final memories = await _memoryRepository.searchMemories(query);

    final memoryResults = memories.map((memory) {
      return MerchantModel(
        id: memory.merchantId,
        name: memory.merchantName,
        type: MerchantTypes.other,
        defaultFinancialCategory: 'Compras',
        defaultFinancialSubcategory: 'Outros',
        aliases: [memory.merchantName],
        icon: 'storefront',
        updatedAt: memory.lastPurchaseAt,
      );
    }).toList();

    final seedIds = seedResults.map((merchant) => merchant.id).toSet();

    final filteredMemoryResults = memoryResults.where((merchant) {
      return !seedIds.contains(merchant.id);
    }).toList();

    return [
      ...seedResults,
      ...filteredMemoryResults,
    ];
  }

  MerchantModel? findById(String id) {
    try {
      return MerchantSeed.items.firstWhere(
        (merchant) => merchant.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  MerchantModel? findBestMatch(String query) {
    final results = search(query);

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }
}