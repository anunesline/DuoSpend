import 'package:app/features/finances/data/financial_accounts_repository.dart';
import 'package:app/features/finances/presentation/finance_widgets.dart';
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/home/data/repositories/wallet_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  late FinancialAccountsRepository repo;
  setUp(() {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'user', displayName: 'Aline'),
      signedIn: true,
    );
    repo = FinancialAccountsRepository(firestore: db, auth: auth);
  });
  Future<WalletModel> create(
    String name, {
    double balance = 0,
    bool primary = false,
    String? creationId,
  }) => repo.save(
    name: name,
    kind: AccountKind.bank,
    bank: 'Banco',
    holder: 'Aline',
    pix: '',
    initialBalance: balance,
    primary: primary,
    creationId: creationId,
  );

  test(
    'old records preserve ownership and get backward compatible metadata',
    () {
      final old = WalletModel.fromMap({
        'id': 'principal',
        'name': 'Minha carteira',
        'balance': 23,
        'ownerId': 'user',
        'type': 'individual',
      });
      expect(old.accountKind, AccountKind.other);
      expect(old.isArchived, false);
      final changed = WalletModel.fromMap(
        old
            .copyWith(
              accountKind: AccountKind.bank,
              bank: 'Banco',
              holder: 'Aline',
              pix: 'chave',
            )
            .toMap(),
      );
      expect(changed.balance, 23);
      expect(changed.ownerId, 'user');
      expect(changed.memberIds, ['user']);
      expect(changed.bank, 'Banco');
      expect(changed.pix, 'chave');
    },
  );

  test('primary persists across repository instances and metadata edits preserve live balance', () async {
    final first = await create('Conta A', balance: 100);
    final second = await create('Conta B', balance: 250, primary: true);
    await db.collection('wallets').doc(second.id).update({'balance': 350});
    await repo.save(
      id: second.id,
      name: 'Renomeada',
      kind: AccountKind.digital,
      bank: '',
      holder: 'Aline',
      pix: 'nova',
      initialBalance: 99999,
    );
    final reloaded = WalletRepository(firestore: db, auth: auth);
    expect((await reloaded.getHomeWallet())?.id, second.id);
    expect((await reloaded.getHomeWallet())?.balance, 350);
    await repo.setPrimary(first.id);
    expect((await reloaded.getHomeWallet())?.id, first.id);
  });

  test('creation retry does not duplicate or reset the account', () async {
    final first = await create('Conta', balance: 20, creationId: 'draft');
    await db.collection('wallets').doc(first.id).update({'balance': 25});
    final retry = await create('Conta', balance: 20, creationId: 'draft');
    expect(retry.id, first.id);
    expect(retry.balance, 25);
    expect((await repo.loadAccounts()).length, 1);
  });

  test(
    'fallback ignores shared, archived and missing preference; ties use ID',
    () {
      final date = DateTime(2026);
      WalletModel account(
        String id, {
        bool archived = false,
        bool shared = false,
      }) => WalletModel(
        id: id,
        name: id,
        balance: 0,
        createdAt: date,
        isArchived: archived,
        type: shared ? WalletType.shared : WalletType.individual,
      );
      final values = [
        account('b'),
        account('joint', shared: true),
        account('old', archived: true),
        account('a'),
      ];
      expect(resolvePrimaryAccount(values, 'b')?.id, 'b');
      expect(resolvePrimaryAccount(values, 'old')?.id, 'a');
      expect(resolvePrimaryAccount(values, 'missing')?.id, 'a');
      expect(resolvePrimaryAccount(values.reversed.toList(), null)?.id, 'a');
      expect(
        resolvePrimaryAccount([account('joint', shared: true)], null),
        isNull,
      );
      expect(resolvePrimaryAccount([], null), isNull);
    },
  );

  test('archive keeps history, removes primary and active selectors; restore works', () async {
    final a = await create('A');
    final b = await create('B', primary: true);
    await repo.deposit(id: b.id, amount: 10, operationId: 'deposit');
    await repo.setArchived(b.id, true);
    expect((await repo.loadAccounts()).length, 2);
    expect((await repo.wallets.getUserWallets()).map((a) => a.id), [a.id]);
    expect(await repo.loadPrimaryId(), isNull);
    expect((await repo.wallets.getHomeWallet())?.id, a.id);
    expect(
      (await db
              .collection('users')
              .doc('user')
              .collection('transactions')
              .get())
          .docs
          .length,
      1,
    );
    await repo.setArchived(b.id, false);
    await repo.setPrimary(b.id);
    expect((await repo.wallets.getHomeWallet())?.id, b.id);
  });

  test('legacy principal ID still reads and updates its own document with modern accounts present', () async {
    final legacy = db
        .collection('users')
        .doc('user')
        .collection('wallets')
        .doc('principal');
    await legacy.set({'name': 'Antiga', 'balance': 40});
    final modern = await create('Nova', balance: 100);
    await repo.setPrimary('principal');
    expect((await repo.wallets.getHomeWallet())?.id, 'principal');
    expect((await repo.wallets.getWalletById('principal'))?.balance, 40);
    await repo.wallets.updateBalance(50, walletId: 'principal');
    expect((await legacy.get()).data()?['balance'], 50);
    expect((await repo.wallets.getWalletById(modern.id))?.balance, 100);
    await repo.deposit(id: 'principal', amount: 5, operationId: 'legacy');
    expect((await legacy.get()).data()?['balance'], 55);
  });

  test('deposit retries are idempotent and journal + balance match', () async {
    final a = await create('A', balance: 5);
    await repo.deposit(id: a.id, amount: 10, operationId: 'same');
    await repo.deposit(id: a.id, amount: 10, operationId: 'same');
    expect((await repo.wallets.getWalletById(a.id))?.balance, 15);
    final entries = await db
        .collection('users')
        .doc('user')
        .collection('transactions')
        .get();
    expect(entries.docs.length, 1);
    expect(entries.docs.single.data()['type'], 'income');
  });

  test('transfer preserves total and does not create income or expense; retries are idempotent', () async {
    final a = await create('A', balance: 100);
    final b = await create('B', balance: 20);
    for (var i = 0; i < 2; i++) {
      await repo.transfer(
        fromId: a.id,
        toId: b.id,
        amount: 30,
        operationId: 'same',
      );
    }
    expect((await repo.wallets.getWalletById(a.id))?.balance, 70);
    expect((await repo.wallets.getWalletById(b.id))?.balance, 50);
    expect((await repo.loadTransfers(a.id)).length, 1);
    expect((await repo.loadTransfers(b.id)).length, 1);
    expect(
      (await db
              .collection('users')
              .doc('user')
              .collection('transactions')
              .get())
          .docs,
      isEmpty,
    );
  });

  test('insufficient funds, archived destinations and invalid amounts cannot move money', () async {
    final a = await create('A', balance: 10);
    final b = await create('B');
    await expectLater(
      repo.transfer(fromId: a.id, toId: b.id, amount: 11, operationId: 'over'),
      throwsStateError,
    );
    await expectLater(
      repo.transfer(fromId: a.id, toId: a.id, amount: 1, operationId: 'self'),
      throwsArgumentError,
    );
    await repo.setArchived(b.id, true);
    await expectLater(
      repo.transfer(
        fromId: a.id,
        toId: b.id,
        amount: 1,
        operationId: 'archived',
      ),
      throwsStateError,
    );
    for (final amount in [0.0, -1.0, double.nan, double.infinity, .001]) {
      await expectLater(
        repo.deposit(id: a.id, amount: amount, operationId: 'invalid'),
        throwsArgumentError,
      );
    }
    expect((await repo.wallets.getWalletById(a.id))?.balance, 10);
    expect(await repo.loadTransfers(a.id), isEmpty);
  });

  test('foreign accounts cannot be edited, archived or made primary', () async {
    await db
        .collection('wallets')
        .doc('foreign')
        .set(
          WalletModel(
            id: 'foreign',
            name: 'Outra pessoa',
            balance: 100,
            ownerId: 'other',
          ).toMap(),
        );
    await expectLater(repo.setPrimary('foreign'), throwsStateError);
    await expectLater(repo.setArchived('foreign', true), throwsStateError);
    await expectLater(
      repo.save(
        id: 'foreign',
        name: 'Tentativa',
        kind: AccountKind.cash,
        bank: '',
        holder: 'Aline',
        pix: '',
      ),
      throwsStateError,
    );
    expect(
      (await db.collection('wallets').doc('foreign').get()).data()?['balance'],
      100,
    );
  });

  test('Brazilian money parsing rejects ambiguous and invalid amounts', () {
    expect(parseAccountMoney('1.234,56'), 1234.56);
    expect(parseAccountMoney('-12,50'), -12.5);
    expect(parseAccountMoney(''), 0);
    for (final input in ['1.50', '1,234', 'NaN', 'Infinity', 'abc']) {
      expect(parseAccountMoney(input), isNull);
    }
  });
}
