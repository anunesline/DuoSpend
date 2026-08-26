import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/home/data/models/credit_card_model.dart';
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/home/data/repositories/credit_card_repository.dart';
import 'package:app/features/home/data/repositories/wallet_repository.dart';
import 'package:app/features/receipt_scanner/application/receipt_transaction_item_mapper.dart';
import 'package:app/features/receipt_scanner/domain/models/receipt_scan_item.dart';
import 'package:app/features/receipt_scanner/domain/models/receipt_transaction_draft.dart';
import 'package:app/features/transactions/data/repositories/balance_settlement_repository.dart';
import 'package:app/features/transactions/data/repositories/transaction_repository.dart';
import 'package:app/features/transactions/data/models/transaction_item_model.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/transactions/domain/financial_split/financial_split_service.dart';
import 'package:app/features/transactions/domain/models/payment_method.dart';
import 'package:app/features/transactions/domain/models/shared_transaction_confirmation_status.dart';
import 'package:app/features/transactions/domain/purchase/services/balance_settlement_synchronizer.dart';
import 'package:app/features/transactions/transaction/usecases/create_transaction_usecase.dart';
import 'package:app/features/transactions/presentation/controllers/transaction_controller.dart';

class _DelayedTransactionRepository extends TransactionRepository {
  final Completer<void> release = Completer<void>();
  int writes = 0;

  _DelayedTransactionRepository({
    required FakeFirebaseFirestore firestore,
    required MockFirebaseAuth auth,
  }) : super(firestore: firestore, auth: auth);

  @override
  Future<void> addTransactions(
    List<TransactionModel> transactions, {
    WalletModel? wallet,
  }) async {
    writes++;
    await release.future;
  }
}

void main() {
  const userId = 'aline';
  const partnerId = 'matheus';

  MockFirebaseAuth auth() => MockFirebaseAuth(
        mockUser: MockUser(uid: userId),
        signedIn: true,
      );

  WalletModel individualWallet({
    required String id,
    double balance = 1000,
  }) => WalletModel(
        id: id,
        name: id,
        balance: balance,
        ownerId: userId,
        memberIds: const [userId],
        createdAt: DateTime(2026, 8, 26),
        updatedAt: DateTime(2026, 8, 26),
      );

  WalletModel sharedWallet() => WalletModel(
        id: 'casa',
        name: 'Casa',
        balance: 0,
        type: WalletType.shared,
        ownerId: userId,
        memberIds: const [userId, partnerId],
        createdAt: DateTime(2026, 8, 26),
        updatedAt: DateTime(2026, 8, 26),
      );

  ReceiptTransactionDraft draft() => ReceiptTransactionDraft(
        description: 'Mercado Duo',
        purchaseDate: DateTime(2026, 8, 25),
        amount: 30,
        paymentMethodSuggestion: 'pix',
        items: const [
          ReceiptScanItem(
            description: 'Arroz',
            quantity: 2,
            unit: 'un',
            unitPrice: 15,
            totalPrice: 30,
          ),
        ],
      );

  Future<CreateTransactionUseCase> useCase({
    required FakeFirebaseFirestore firestore,
    required WalletModel financialWallet,
  }) async {
    await firestore
        .collection('wallets')
        .doc(financialWallet.id)
        .set(financialWallet.toMap());
    final signedInAuth = auth();
    final transactionRepository = TransactionRepository(
      firestore: firestore,
      auth: signedInAuth,
    );
    return CreateTransactionUseCase(
      transactionRepository: transactionRepository,
      walletRepository: WalletRepository(
        firestore: firestore,
        auth: signedInAuth,
      ),
      creditCardRepository: CreditCardRepository(
        firestore: firestore,
        auth: signedInAuth,
      ),
      financialSplitService: const FinancialSplitService(),
      settlementSynchronizer: BalanceSettlementSynchronizer(
        transactionRepository: transactionRepository,
        settlementRepository: BalanceSettlementRepository(
          firestore: firestore,
          auth: signedInAuth,
        ),
      ),
    );
  }

  List<TransactionItemModel> mapItems(ReceiptTransactionDraft value) =>
      const ReceiptTransactionItemMapper().map(
        items: value.items,
        category: 'Alimentação',
        subcategory: 'Mercado',
        taxonomyId: 'mercado',
        createdAt: DateTime(2026, 8, 26),
      );

  group('handoff Scanner Fiscal -> Nova Transação', () {
    test('cancelar ou apenas manter um draft não persiste transação', () async {
      final firestore = FakeFirebaseFirestore();
      final value = draft();

      expect(value.canContinueToTransaction, isTrue);
      final transactions = await firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();
      expect(transactions.docs, isEmpty);
    });

    test('confirma draft em carteira individual pelo fluxo financeiro normal',
        () async {
      final firestore = FakeFirebaseFirestore();
      final financialWallet = individualWallet(id: 'inter');
      final transactionWallet = individualWallet(id: 'compras');
      final create = await useCase(
        firestore: firestore,
        financialWallet: financialWallet,
      );
      final value = draft();

      final result = await create(
        transactionId: 'receipt-solo',
        description: value.description,
        value: value.amount!,
        type: 'expense',
        walletId: transactionWallet.id,
        wallet: transactionWallet,
        category: 'Alimentação',
        subcategory: 'Mercado',
        paidByMemberId: userId,
        purchaseFor: 'self',
        partnerMemberId: null,
        financialWalletId: financialWallet.id,
        paymentMethod: PaymentMethod.pix,
        paymentSourceId: financialWallet.id,
        transactionDate: value.purchaseDate,
        items: mapItems(value),
      );

      final transactions = await firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();
      final savedFinancialWallet =
          await firestore.collection('wallets').doc(financialWallet.id).get();

      expect(transactions.docs, hasLength(1));
      expect(result.transaction.date, value.purchaseDate);
      expect(result.transaction.items.single.name, 'Arroz');
      expect(savedFinancialWallet.data()!['balance'], 970);
    });

    test('confirma draft compartilhado mantendo confirmação bilateral pendente',
        () async {
      final firestore = FakeFirebaseFirestore();
      final financialWallet = individualWallet(id: 'inter');
      final transactionWallet = sharedWallet();
      final create = await useCase(
        firestore: firestore,
        financialWallet: financialWallet,
      );
      final value = draft();

      final result = await create(
        transactionId: 'receipt-shared',
        description: value.description,
        value: value.amount!,
        type: 'expense',
        walletId: transactionWallet.id,
        wallet: transactionWallet,
        category: 'Alimentação',
        subcategory: 'Mercado',
        paidByMemberId: userId,
        purchaseFor: 'both',
        partnerMemberId: partnerId,
        financialWalletId: financialWallet.id,
        paymentMethod: PaymentMethod.pix,
        paymentSourceId: financialWallet.id,
        transactionDate: value.purchaseDate,
        items: mapItems(value),
      );

      final transactions = await firestore
          .collection('wallets')
          .doc(transactionWallet.id)
          .collection('transactions')
          .get();
      final savedFinancialWallet =
          await firestore.collection('wallets').doc(financialWallet.id).get();

      expect(transactions.docs, hasLength(1));
      expect(
        result.transaction.confirmationStatus,
        SharedTransactionConfirmationStatus.pending,
      );
      expect(result.transaction.memberShares, {userId: 15, partnerId: 15});
      expect(savedFinancialWallet.data()!['balance'], 1000);
    });

    test('confirma draft no cartão uma vez, sem débito imediato', () async {
      final firestore = FakeFirebaseFirestore();
      final financialWallet = individualWallet(id: 'inter');
      final transactionWallet = individualWallet(id: 'compras');
      final card = CreditCardModel(
        id: 'card-1',
        ownerMemberId: userId,
        walletId: financialWallet.id,
        name: 'Cartão',
        creditLimit: 1000,
        closingDay: 20,
        dueDay: 10,
      );
      await firestore.collection('creditCards').doc(card.id).set(card.toMap());
      final create = await useCase(
        firestore: firestore,
        financialWallet: financialWallet,
      );
      final value = draft();

      await create(
        transactionId: 'receipt-card',
        description: value.description,
        value: value.amount!,
        type: 'expense',
        walletId: transactionWallet.id,
        wallet: transactionWallet,
        category: 'Alimentação',
        subcategory: 'Mercado',
        paidByMemberId: userId,
        purchaseFor: 'self',
        partnerMemberId: null,
        financialWalletId: financialWallet.id,
        paymentMethod: PaymentMethod.creditCard,
        paymentSourceId: card.id,
        transactionDate: value.purchaseDate,
        items: mapItems(value),
      );

      final charges = await firestore
          .collection('creditCards')
          .doc(card.id)
          .collection('charges')
          .get();
      final savedFinancialWallet =
          await firestore.collection('wallets').doc(financialWallet.id).get();

      expect(charges.docs, hasLength(1));
      expect(savedFinancialWallet.data()!['balance'], 1000);
    });

    test('duplo toque durante a confirmação cria uma única operação',
        () async {
      final firestore = FakeFirebaseFirestore();
      final financialWallet = individualWallet(id: 'inter');
      final signedInAuth = auth();
      await firestore
          .collection('wallets')
          .doc(financialWallet.id)
          .set(financialWallet.toMap());
      final repository = _DelayedTransactionRepository(
        firestore: firestore,
        auth: signedInAuth,
      );
      final create = CreateTransactionUseCase(
        transactionRepository: repository,
        walletRepository: WalletRepository(
          firestore: firestore,
          auth: signedInAuth,
        ),
        financialSplitService: const FinancialSplitService(),
        settlementSynchronizer: BalanceSettlementSynchronizer(
          transactionRepository: repository,
          settlementRepository: BalanceSettlementRepository(
            firestore: firestore,
            auth: signedInAuth,
          ),
        ),
      );
      final controller = TransactionController(createTransactionUseCase: create);
      final value = draft();

      final firstSave = controller.saveTransaction(
        transactionId: 'receipt-double-tap',
        description: value.description,
        value: value.amount!,
        type: 'expense',
        walletId: 'compras',
        wallet: individualWallet(id: 'compras'),
        category: 'Alimentação',
        subcategory: 'Mercado',
        paidByMemberId: userId,
        purchaseFor: 'self',
        financialWalletId: financialWallet.id,
        paymentMethod: PaymentMethod.pix,
        paymentSourceId: financialWallet.id,
      );
      await Future<void>.delayed(Duration.zero);

      await expectLater(
        controller.saveTransaction(
          transactionId: 'receipt-double-tap',
          description: value.description,
          value: value.amount!,
          type: 'expense',
          walletId: 'compras',
          wallet: individualWallet(id: 'compras'),
          category: 'Alimentação',
          subcategory: 'Mercado',
          paidByMemberId: userId,
          purchaseFor: 'self',
          financialWalletId: financialWallet.id,
          paymentMethod: PaymentMethod.pix,
          paymentSourceId: financialWallet.id,
        ),
        throwsStateError,
      );
      expect(repository.writes, 1);

      repository.release.complete();
      await firstSave;
    });
  });
}
