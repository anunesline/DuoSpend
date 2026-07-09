import '../consumer_profile_entity.dart';
import '../consumer_type.dart';
import '../repositories/consumer_profile_repository.dart';

class ConsumerBootstrap {
  final ConsumerProfileRepository repository;

  const ConsumerBootstrap(this.repository);

  Future<void> initialize({
    required String walletId,
  }) async {
    final existing = await repository.getByWalletId(walletId);

    if (existing.isNotEmpty) {
      return;
    }

    final now = DateTime.now();

    await repository.save(
      ConsumerProfileEntity(
        id: '${walletId}_owner',
        walletId: walletId,
        name: 'Eu',
        type: ConsumerType.person,
        isActive: true,
        createdAt: now,
      ),
    );
  }
}