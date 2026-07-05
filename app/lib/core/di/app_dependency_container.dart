import '../../features/shopping/data/repositories/firestore_shopping_repository.dart';
import '../../features/shopping/data/repositories/in_memory_product_memory_repository.dart';
import '../../features/shopping/domain/intelligence/product_intelligence_engine.dart';
import '../../features/shopping/domain/repositories/product_memory_repository.dart';
import '../../features/shopping/domain/repositories/shopping_repository.dart';
import '../../features/shopping/domain/services/shopping_flow_service.dart';
import '../../features/shopping/domain/usecases/archive_shopping_item_usecase.dart';
import '../../features/shopping/domain/usecases/create_shopping_item_usecase.dart';
import '../../features/shopping/domain/usecases/delete_shopping_item_usecase.dart';
import '../../features/shopping/domain/usecases/get_all_shopping_items_usecase.dart';
import '../../features/shopping/domain/usecases/get_pending_shopping_items_usecase.dart';
import '../../features/shopping/domain/usecases/get_purchased_shopping_items_usecase.dart';
import '../../features/shopping/domain/usecases/get_shopping_suggestions_usecase.dart';
import '../../features/shopping/domain/usecases/mark_shopping_item_as_purchased_usecase.dart';
import '../../features/shopping/domain/usecases/process_product_intelligence_usecase.dart';
import '../../features/shopping/domain/usecases/search_shopping_items_usecase.dart';
import '../../features/shopping/domain/usecases/update_shopping_item_usecase.dart';
import '../../features/shopping/presentation/controllers/shopping_controller.dart';

class AppDependencyContainer {
  late final ShoppingRepository shoppingRepository;
  late final ProductMemoryRepository productMemoryRepository;

  late final ProductIntelligenceEngine productIntelligenceEngine;
  late final ProcessProductIntelligenceUseCase processProductIntelligenceUseCase;

  late final CreateShoppingItemUseCase createShoppingItemUseCase;
  late final UpdateShoppingItemUseCase updateShoppingItemUseCase;
  late final DeleteShoppingItemUseCase deleteShoppingItemUseCase;
  late final GetAllShoppingItemsUseCase getAllShoppingItemsUseCase;
  late final GetPendingShoppingItemsUseCase getPendingShoppingItemsUseCase;
  late final GetPurchasedShoppingItemsUseCase getPurchasedShoppingItemsUseCase;
  late final MarkShoppingItemAsPurchasedUseCase markShoppingItemAsPurchasedUseCase;
  late final ArchiveShoppingItemUseCase archiveShoppingItemUseCase;
  late final SearchShoppingItemsUseCase searchShoppingItemsUseCase;
  late final GetShoppingSuggestionsUseCase getShoppingSuggestionsUseCase;

  late final ShoppingFlowService shoppingFlowService;
  late final ShoppingController shoppingController;

  AppDependencyContainer() {
    _registerRepositories();
    _registerProductIntelligence();
    _registerShoppingUseCases();
    _registerShoppingFlow();
    _registerControllers();
  }

  void _registerRepositories() {
    shoppingRepository = FirestoreShoppingRepository();
    productMemoryRepository = InMemoryProductMemoryRepository();
  }

  void _registerProductIntelligence() {
    productIntelligenceEngine = ProductIntelligenceEngine(
      repository: productMemoryRepository,
    );

    processProductIntelligenceUseCase = ProcessProductIntelligenceUseCase(
      productIntelligenceEngine,
    );
  }

  void _registerShoppingUseCases() {
    createShoppingItemUseCase = CreateShoppingItemUseCase(shoppingRepository);
    updateShoppingItemUseCase = UpdateShoppingItemUseCase(shoppingRepository);
    deleteShoppingItemUseCase = DeleteShoppingItemUseCase(shoppingRepository);
    getAllShoppingItemsUseCase = GetAllShoppingItemsUseCase(shoppingRepository);
    getPendingShoppingItemsUseCase =
        GetPendingShoppingItemsUseCase(shoppingRepository);
    getPurchasedShoppingItemsUseCase =
        GetPurchasedShoppingItemsUseCase(shoppingRepository);
    markShoppingItemAsPurchasedUseCase =
        MarkShoppingItemAsPurchasedUseCase(shoppingRepository);
    archiveShoppingItemUseCase = ArchiveShoppingItemUseCase(shoppingRepository);
    searchShoppingItemsUseCase = SearchShoppingItemsUseCase(shoppingRepository);
    getShoppingSuggestionsUseCase =
        GetShoppingSuggestionsUseCase(shoppingRepository);
  }

  void _registerShoppingFlow() {
    shoppingFlowService = ShoppingFlowService(
      createShoppingItem: createShoppingItemUseCase,
      updateShoppingItem: updateShoppingItemUseCase,
      deleteShoppingItem: deleteShoppingItemUseCase,
      getAllShoppingItems: getAllShoppingItemsUseCase,
      getPendingShoppingItems: getPendingShoppingItemsUseCase,
      getPurchasedShoppingItems: getPurchasedShoppingItemsUseCase,
      markShoppingItemAsPurchased: markShoppingItemAsPurchasedUseCase,
      archiveShoppingItem: archiveShoppingItemUseCase,
      searchShoppingItems: searchShoppingItemsUseCase,
      getShoppingSuggestions: getShoppingSuggestionsUseCase,
      processProductIntelligence: processProductIntelligenceUseCase,
    );
  }

  void _registerControllers() {
    shoppingController = ShoppingController(shoppingFlowService);
  }
}