import '../context/wallet_context.dart';

import '../../features/consumers/data/repositories/firestore_consumer_profile_repository.dart';
import '../../features/consumers/data/repositories/in_memory_consumer_memory_repository.dart';
import '../../features/consumers/domain/intelligence/consumer_habit_analyzer.dart';
import '../../features/consumers/domain/intelligence/consumer_habit_updater.dart';
import '../../features/consumers/domain/intelligence/consumer_intelligence_engine.dart';
import '../../features/consumers/domain/intelligence/consumer_memory_loader.dart';
import '../../features/consumers/domain/intelligence/default_consumer_intelligence_engine.dart';
import '../../features/consumers/domain/repositories/consumer_memory_repository.dart';
import '../../features/consumers/domain/repositories/consumer_profile_repository.dart';
import '../../features/consumers/domain/services/consumer_bootstrap.dart';
import '../../features/consumers/domain/services/consumer_flow_service.dart';
import '../../features/consumers/domain/services/consumer_lifecycle_service.dart';
import '../../features/consumers/domain/usecases/create_consumer_usecase.dart';
import '../../features/consumers/domain/usecases/delete_consumer_usecase.dart';
import '../../features/consumers/domain/usecases/get_all_consumers_usecase.dart';
import '../../features/consumers/domain/usecases/get_consumer_by_id_usecase.dart';
import '../../features/consumers/domain/usecases/get_consumers_by_wallet_id_usecase.dart';
import '../../features/consumers/domain/usecases/get_default_consumer_usecase.dart';
import '../../features/consumers/domain/usecases/process_consumer_intelligence_usecase.dart';
import '../../features/consumers/domain/usecases/save_consumer_usecase.dart';
import '../../features/consumers/presentation/controllers/consumer_controller.dart';

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

import '../../features/transactions/data/repositories/firestore_product_persistence_repository.dart';
import '../../features/transactions/presentation/controllers/purchase_controller.dart';

import '../../shared/knowledge/products/product_bootstrap.dart';
import '../../shared/knowledge/products/product_persistence_repository.dart';
import '../../shared/knowledge/products/product_repository.dart';

class AppDependencyContainer {
  late final WalletContext walletContext;

  late final ShoppingRepository shoppingRepository;
  late final ProductMemoryRepository productMemoryRepository;

  late final ProductPersistenceRepository productPersistenceRepository;
  late final ProductRepository productRepository;
  late final ProductBootstrap productBootstrap;

  late final ProductIntelligenceEngine productIntelligenceEngine;
  late final ProcessProductIntelligenceUseCase
      processProductIntelligenceUseCase;

  late final CreateShoppingItemUseCase createShoppingItemUseCase;
  late final UpdateShoppingItemUseCase updateShoppingItemUseCase;
  late final DeleteShoppingItemUseCase deleteShoppingItemUseCase;
  late final GetAllShoppingItemsUseCase getAllShoppingItemsUseCase;
  late final GetPendingShoppingItemsUseCase
      getPendingShoppingItemsUseCase;
  late final GetPurchasedShoppingItemsUseCase
      getPurchasedShoppingItemsUseCase;
  late final MarkShoppingItemAsPurchasedUseCase
      markShoppingItemAsPurchasedUseCase;
  late final ArchiveShoppingItemUseCase archiveShoppingItemUseCase;
  late final SearchShoppingItemsUseCase searchShoppingItemsUseCase;
  late final GetShoppingSuggestionsUseCase
      getShoppingSuggestionsUseCase;

  late final ShoppingFlowService shoppingFlowService;
  late final ShoppingController shoppingController;

  late final ConsumerProfileRepository consumerProfileRepository;
  late final ConsumerMemoryRepository consumerMemoryRepository;
  late final ConsumerMemoryLoader consumerMemoryLoader;
  late final ConsumerHabitAnalyzer consumerHabitAnalyzer;
  late final ConsumerHabitUpdater consumerHabitUpdater;
  late final ConsumerIntelligenceEngine consumerIntelligenceEngine;
  late final ProcessConsumerIntelligenceUseCase
      processConsumerIntelligenceUseCase;

  late final ConsumerBootstrap consumerBootstrap;
  late final ConsumerLifecycleService consumerLifecycleService;
  late final ConsumerFlowService consumerFlowService;

  late final CreateConsumerUseCase createConsumerUseCase;
  late final SaveConsumerUseCase saveConsumerUseCase;
  late final DeleteConsumerUseCase deleteConsumerUseCase;
  late final GetAllConsumersUseCase getAllConsumersUseCase;
  late final GetConsumerByIdUseCase getConsumerByIdUseCase;
  late final GetConsumersByWalletIdUseCase
      getConsumersByWalletIdUseCase;
  late final GetDefaultConsumerUseCase getDefaultConsumerUseCase;

  late final ConsumerController consumerController;
  late final PurchaseController purchaseController;

  AppDependencyContainer() {
    walletContext = WalletContext();

    _registerRepositories();
    _registerProductServices();
    _registerProductIntelligence();
    _registerConsumerIntelligence();
    _registerShoppingUseCases();
    _registerShoppingFlow();
    _registerConsumers();
    _registerControllers();
  }

  void _registerRepositories() {
    shoppingRepository = FirestoreShoppingRepository();
    productMemoryRepository = InMemoryProductMemoryRepository();

    consumerProfileRepository =
        FirestoreConsumerProfileRepository();

    consumerMemoryRepository =
        InMemoryConsumerMemoryRepository();
  }

  void _registerProductServices() {
    productPersistenceRepository =
        FirestoreProductPersistenceRepository();

    productRepository = ProductRepository(
      persistenceRepository: productPersistenceRepository,
    );

    productBootstrap = ProductBootstrap(
      productRepository: productRepository,
    );
  }

  void _registerProductIntelligence() {
    productIntelligenceEngine = ProductIntelligenceEngine(
      repository: productMemoryRepository,
    );

    processProductIntelligenceUseCase =
        ProcessProductIntelligenceUseCase(
      productIntelligenceEngine,
    );
  }

  void _registerConsumerIntelligence() {
    consumerMemoryLoader = ConsumerMemoryLoader(
      repository: consumerMemoryRepository,
    );

    consumerHabitAnalyzer = const ConsumerHabitAnalyzer();
    consumerHabitUpdater = const ConsumerHabitUpdater();

    consumerIntelligenceEngine =
        DefaultConsumerIntelligenceEngine(
      analyzer: consumerHabitAnalyzer,
      updater: consumerHabitUpdater,
    );

    processConsumerIntelligenceUseCase =
        ProcessConsumerIntelligenceUseCase(
      memoryLoader: consumerMemoryLoader,
      intelligenceEngine: consumerIntelligenceEngine,
    );
  }

  void _registerShoppingUseCases() {
    createShoppingItemUseCase =
        CreateShoppingItemUseCase(
      shoppingRepository,
    );

    updateShoppingItemUseCase =
        UpdateShoppingItemUseCase(
      shoppingRepository,
    );

    deleteShoppingItemUseCase =
        DeleteShoppingItemUseCase(
      shoppingRepository,
    );

    getAllShoppingItemsUseCase =
        GetAllShoppingItemsUseCase(
      shoppingRepository,
    );

    getPendingShoppingItemsUseCase =
        GetPendingShoppingItemsUseCase(
      shoppingRepository,
    );

    getPurchasedShoppingItemsUseCase =
        GetPurchasedShoppingItemsUseCase(
      shoppingRepository,
    );

    markShoppingItemAsPurchasedUseCase =
        MarkShoppingItemAsPurchasedUseCase(
      shoppingRepository,
    );

    archiveShoppingItemUseCase =
        ArchiveShoppingItemUseCase(
      shoppingRepository,
    );

    searchShoppingItemsUseCase =
        SearchShoppingItemsUseCase(
      shoppingRepository,
    );

    getShoppingSuggestionsUseCase =
        GetShoppingSuggestionsUseCase(
      shoppingRepository,
    );
  }

  void _registerShoppingFlow() {
    shoppingFlowService = ShoppingFlowService(
      createShoppingItem: createShoppingItemUseCase,
      updateShoppingItem: updateShoppingItemUseCase,
      deleteShoppingItem: deleteShoppingItemUseCase,
      getAllShoppingItems: getAllShoppingItemsUseCase,
      getPendingShoppingItems: getPendingShoppingItemsUseCase,
      getPurchasedShoppingItems:
          getPurchasedShoppingItemsUseCase,
      markShoppingItemAsPurchased:
          markShoppingItemAsPurchasedUseCase,
      archiveShoppingItem: archiveShoppingItemUseCase,
      searchShoppingItems: searchShoppingItemsUseCase,
      getShoppingSuggestions: getShoppingSuggestionsUseCase,
      processProductIntelligence:
          processProductIntelligenceUseCase,
    );
  }

  void _registerConsumers() {
    consumerBootstrap = ConsumerBootstrap(
      consumerProfileRepository,
    );

    consumerLifecycleService = ConsumerLifecycleService(
      consumerProfileRepository,
    );

    createConsumerUseCase = CreateConsumerUseCase(
      consumerLifecycleService,
    );

    saveConsumerUseCase = SaveConsumerUseCase(
      consumerLifecycleService,
    );

    deleteConsumerUseCase = DeleteConsumerUseCase(
      consumerLifecycleService,
    );

    getAllConsumersUseCase = GetAllConsumersUseCase(
      consumerProfileRepository,
    );

    getConsumerByIdUseCase = GetConsumerByIdUseCase(
      consumerLifecycleService,
    );

    getConsumersByWalletIdUseCase =
        GetConsumersByWalletIdUseCase(
      consumerLifecycleService,
    );

    getDefaultConsumerUseCase = GetDefaultConsumerUseCase(
      consumerLifecycleService,
    );

    consumerFlowService = ConsumerFlowService(
      consumerBootstrap: consumerBootstrap,
      createConsumer: createConsumerUseCase,
      saveConsumer: saveConsumerUseCase,
      deleteConsumer: deleteConsumerUseCase,
      getConsumerById: getConsumerByIdUseCase,
      getConsumersByWalletId:
          getConsumersByWalletIdUseCase,
      getDefaultConsumer: getDefaultConsumerUseCase,
    );
  }

  void _registerControllers() {
    shoppingController = ShoppingController(
      shoppingFlowService,
    );

    consumerController = ConsumerController(
      consumerFlowService,
      walletContext,
    );

    purchaseController = PurchaseController(
      processConsumerIntelligenceUseCase:
          processConsumerIntelligenceUseCase,
    );
  }
}