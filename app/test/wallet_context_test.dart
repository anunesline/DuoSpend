import 'package:app/core/context/wallet_context.dart';
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WalletModel wallet({
    required String id,
    required WalletType type,
    List<String> memberIds = const ['owner'],
  }) {
    final now = DateTime(2026, 8, 25);
    return WalletModel(
      id: id,
      name: id,
      balance: 0,
      type: type,
      ownerId: 'owner',
      memberIds: memberIds,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('preserva carteira compartilhada mesmo sem IDs auxiliares', () {
    final context = WalletContext();
    final shared = wallet(
      id: 'shared',
      type: WalletType.shared,
      memberIds: const ['owner', 'member'],
    );

    context.initialize(wallets: [shared]);

    expect(context.selectedWalletIsShared, isTrue);
    expect(context.isCoupleMode, isTrue);
    expect(context.sharedWallets, contains(shared));
  });

  test('alterna entre contextos solo e compartilhado sem misturar seleção', () {
    final context = WalletContext();
    final solo = wallet(id: 'solo', type: WalletType.individual);
    final shared = wallet(
      id: 'shared',
      type: WalletType.shared,
      memberIds: const ['owner', 'member'],
    );
    context.initialize(wallets: [solo, shared]);

    context.useCoupleMode();
    expect(context.selectedWallet?.id, 'shared');
    expect(context.isCoupleMode, isTrue);

    context.useSoloMode();
    expect(context.selectedWallet?.id, 'solo');
    expect(context.isSoloMode, isTrue);
  });

  test('atualização direta seleciona carteira compartilhada no contexto certo', () {
    final context = WalletContext();
    final solo = wallet(id: 'solo', type: WalletType.individual);
    final shared = wallet(
      id: 'shared',
      type: WalletType.shared,
      memberIds: const ['owner', 'member'],
    );
    context.initialize(wallets: [solo]);

    context.updateSelectedWallet(shared);

    expect(context.selectedWalletIsShared, isTrue);
    expect(context.isCoupleMode, isTrue);
    expect(context.sharedWallets, contains(shared));
  });
}
