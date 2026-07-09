import '../consumer_profile_entity.dart';
import '../consumer_type.dart';
import '../usecases/create_consumer_usecase.dart';
import '../usecases/delete_consumer_usecase.dart';
import '../usecases/get_consumer_by_id_usecase.dart';
import '../usecases/get_consumers_by_wallet_id_usecase.dart';
import '../usecases/get_default_consumer_usecase.dart';
import '../usecases/save_consumer_usecase.dart';
import 'consumer_bootstrap.dart';

class ConsumerFlowService {
  final ConsumerBootstrap consumerBootstrap;
  final CreateConsumerUseCase createConsumer;
  final SaveConsumerUseCase saveConsumer;
  final DeleteConsumerUseCase deleteConsumer;
  final GetConsumerByIdUseCase getConsumerById;
  final GetConsumersByWalletIdUseCase getConsumersByWalletId;
  final GetDefaultConsumerUseCase getDefaultConsumer;

  const ConsumerFlowService({
    required this.consumerBootstrap,
    required this.createConsumer,
    required this.saveConsumer,
    required this.deleteConsumer,
    required this.getConsumerById,
    required this.getConsumersByWalletId,
    required this.getDefaultConsumer,
  });

  Future<void> initializeWalletConsumers({
    required String walletId,
  }) {
    return consumerBootstrap.initialize(walletId: walletId);
  }

  Future<List<ConsumerProfileEntity>> getWalletConsumers({
    required String walletId,
  }) {
    return getConsumersByWalletId(walletId);
  }

  Future<ConsumerProfileEntity?> getConsumer({
    required String id,
  }) {
    return getConsumerById(id);
  }

  Future<ConsumerProfileEntity?> getDefault({
    required String walletId,
  }) {
    return getDefaultConsumer(walletId);
  }

  Future<ConsumerProfileEntity> create({
    required String walletId,
    required String name,
    required ConsumerType type,
    String? icon,
    String? color,
  }) {
    return createConsumer(
      walletId: walletId,
      name: name,
      type: type,
      icon: icon,
      color: color,
    );
  }

  Future<ConsumerProfileEntity> save(
    ConsumerProfileEntity consumer,
  ) {
    return saveConsumer(consumer);
  }

  Future<void> archive({
    required String id,
  }) {
    return deleteConsumer(id);
  }
}