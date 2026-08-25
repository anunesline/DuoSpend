import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/budgets/data/repositories/budget_repository.dart';
import 'package:app/features/budgets/domain/models/budget.dart';
import 'package:app/features/home/data/models/wallet_model.dart';

void main() {
  const owner = 'owner';
  MockFirebaseAuth auth(String uid) => MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);
  WalletModel wallet({bool shared = false}) => WalletModel(id: 'wallet', name: 'Carteira', balance: 0, type: shared ? WalletType.shared : WalletType.individual, ownerId: owner, memberIds: shared ? const [owner, 'member'] : const [owner], createdAt: DateTime(2026, 8, 1), updatedAt: DateTime(2026, 8, 1));
  Budget budget({String userId = owner}) => Budget(id: 'budget', walletId: 'wallet', category: 'Mercado', month: DateTime(2026, 8), limitAmount: 400, createdByUserId: userId, createdAt: DateTime(2026, 8, 1), updatedAt: DateTime(2026, 8, 1));

  test('persiste orçamento individual no usuário autenticado', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = BudgetRepository(firestore: firestore, auth: auth(owner));
    await repository.create(budget: budget(), wallet: wallet());
    expect((await repository.getByWallet(wallet: wallet())).single.category, 'Mercado');
    expect((await firestore.collection('users').doc(owner).collection('budgets').doc('budget').get()).exists, isTrue);
  });

  test('membro pode consultar, mas não alterar orçamento compartilhado', () async {
    final firestore = FakeFirebaseFirestore();
    final ownerRepository = BudgetRepository(firestore: firestore, auth: auth(owner));
    final sharedWallet = wallet(shared: true);
    await ownerRepository.create(budget: budget(), wallet: sharedWallet);
    final memberRepository = BudgetRepository(firestore: firestore, auth: auth('member'));
    expect((await memberRepository.getByWallet(wallet: sharedWallet)).single.id, 'budget');
    await expectLater(memberRepository.changeStatus(budget: budget(), status: BudgetStatus.paused, wallet: sharedWallet), throwsStateError);
  });

  test('atualização mantém um único documento de orçamento', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = BudgetRepository(firestore: firestore, auth: auth(owner));
    final item = budget();
    await repository.create(budget: item, wallet: wallet());
    await repository.update(budget: item.copyWith(limitAmount: 500), wallet: wallet());
    final budgets = await repository.getByWallet(wallet: wallet());
    expect(budgets, hasLength(1));
    expect(budgets.single.limitAmount, 500);
  });

  test('atualização preserva campos imutáveis persistidos', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = BudgetRepository(
      firestore: firestore,
      auth: auth(owner),
    );
    final original = budget();
    await repository.create(budget: original, wallet: wallet());

    final tamperedUpdate = Budget(
      id: original.id,
      walletId: 'wallet-alterada',
      category: 'Lazer',
      month: DateTime(2026, 9),
      limitAmount: 500,
      createdByUserId: 'outro-usuario',
      status: BudgetStatus.paused,
      createdAt: DateTime(2020, 1, 1),
      updatedAt: DateTime(2026, 8, 25),
    );

    final updated = await repository.update(
      budget: tamperedUpdate,
      wallet: wallet(),
    );
    final persisted = (await repository.getByWallet(wallet: wallet())).single;

    expect(updated.id, original.id);
    expect(persisted.id, original.id);
    expect(persisted.walletId, original.walletId);
    expect(persisted.createdByUserId, original.createdByUserId);
    expect(persisted.createdAt, original.createdAt);
    expect(persisted.category, 'Lazer');
    expect(persisted.month, DateTime(2026, 9));
    expect(persisted.limitAmount, 500);
    expect(persisted.status, BudgetStatus.paused);
  });
}
