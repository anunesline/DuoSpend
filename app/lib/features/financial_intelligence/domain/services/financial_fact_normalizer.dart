import '../../../../shared/knowledge/taxonomy/duo_taxonomy.dart';
import '../../../finances/data/financial_accounts_repository.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../transactions/data/models/balance_settlement_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/domain/services/recurring_transaction_service.dart';
import '../facts/financial_facts.dart';

/// Pure FI-A normalization layer.
///
/// It derives only facts already supported by the persisted financial domain.
/// It intentionally performs no aggregation, comparison, pattern detection,
/// signal generation, or user-facing interpretation.
class FinancialFactNormalizer {
  const FinancialFactNormalizer({
    this._recurringTransactionService = const RecurringTransactionService(),
  });

  final RecurringTransactionService _recurringTransactionService;

  FinancialFactNormalizationResult normalize(
    FinancialFactNormalizationInput input,
  ) {
    final referenceDate = _dateOnly(input.referenceAt);
    final rangeEnd = _dateOnly(input.commitmentRangeEnd);
    if (rangeEnd.isBefore(referenceDate)) {
      throw ArgumentError(
        'O fim do intervalo de compromissos não pode anteceder a referência.',
      );
    }

    final facts = <FinancialFactBundle>[];
    final suppressed = <FinancialSuppressedSource>[];
    final walletId = input.wallet.id.trim();

    for (final transaction in _orderedTransactions(input.transactions)) {
      if (transaction.walletId.trim() != walletId) {
        suppressed.add(
          FinancialSuppressedSource(
            kind: FinancialFactSourceKind.transaction,
            id: transaction.id,
            reason: FinancialFactSuppressionReason.foreignWalletSource,
          ),
        );
        continue;
      }

      facts.add(
        _fromTransaction(
          transaction: transaction,
          input: input,
          referenceDate: referenceDate,
          commitmentRangeEnd: rangeEnd,
        ),
      );

      if (transaction.isRecurring) {
        facts.addAll(
          _futureRecurringCommitments(
            transaction: transaction,
            input: input,
            referenceDate: referenceDate,
            rangeEnd: rangeEnd,
          ),
        );
      }
    }

    for (final source in input.invoices) {
      final invoice = source.invoice;
      final belongsToCardWallet = source.walletId.trim() == walletId;
      final paidFromWallet = invoice.paymentWalletId?.trim() == walletId;
      if (!belongsToCardWallet && !paidFromWallet) {
        suppressed.add(
          FinancialSuppressedSource(
            kind: FinancialFactSourceKind.creditCardInvoice,
            id: _invoiceSourceId(invoice.cardId, invoice.id),
            reason: FinancialFactSuppressionReason.foreignWalletSource,
          ),
        );
        continue;
      }
      facts.add(
        _fromInvoice(
          source: source,
          wallet: input.wallet,
          referenceDate: referenceDate,
        ),
      );
    }

    for (final transfer in input.transfers) {
      final isFromWallet = transfer.fromId.trim() == walletId;
      final isToWallet = transfer.toId.trim() == walletId;
      if (!isFromWallet && !isToWallet) {
        suppressed.add(
          FinancialSuppressedSource(
            kind: FinancialFactSourceKind.accountTransfer,
            id: transfer.id,
            reason: FinancialFactSuppressionReason.foreignWalletSource,
          ),
        );
        continue;
      }
      facts.add(
        _fromTransfer(
          transfer: transfer,
          wallet: input.wallet,
          isFromWallet: isFromWallet,
          isToWallet: isToWallet,
        ),
      );
    }

    for (final settlement in input.settlements) {
      final isPayerWallet = settlement.payerWalletId?.trim() == walletId;
      final isReceiverWallet = settlement.receiverWalletId?.trim() == walletId;
      if (!isPayerWallet && !isReceiverWallet) {
        suppressed.add(
          FinancialSuppressedSource(
            kind: FinancialFactSourceKind.settlement,
            id: settlement.id,
            reason: FinancialFactSuppressionReason.foreignWalletSource,
          ),
        );
        continue;
      }
      facts.add(
        _fromSettlement(
          settlement: settlement,
          wallet: input.wallet,
          isPayerWallet: isPayerWallet,
          isReceiverWallet: isReceiverWallet,
          referenceDate: referenceDate,
        ),
      );
    }

    return FinancialFactNormalizationResult(
      facts: List.unmodifiable(facts),
      suppressedSources: List.unmodifiable(suppressed),
    );
  }

  FinancialFactBundle _fromTransaction({
    required TransactionModel transaction,
    required FinancialFactNormalizationInput input,
    required DateTime referenceDate,
    required DateTime commitmentRangeEnd,
  }) {
    final date = _dateOnly(transaction.date);
    final isFuture = date.isAfter(referenceDate);
    final source = _transactionSource(transaction, input.wallet);
    final validType =
        transaction.type == 'income' || transaction.type == 'expense';
    final validAmount = _isPositiveAmount(transaction.value);
    final responsibility = _responsibilitiesFor(transaction);

    FinancialEconomicFact? economic;
    FinancialFactSuppressionReason? economicReason;
    if (!validType || !validAmount) {
      economicReason = FinancialFactSuppressionReason.invalidSource;
    } else if (transaction.isSettlement) {
      economicReason =
          FinancialFactSuppressionReason.settlementIsNotEconomicConsumption;
    } else if (transaction.isInstallment && isFuture) {
      economicReason =
          FinancialFactSuppressionReason.futureInstallmentIsNotEconomic;
    } else if (transaction.isRecurring && isFuture) {
      economicReason =
          FinancialFactSuppressionReason.futureRecurringOccurrenceIsNotEconomic;
    } else if (isFuture) {
      economicReason = FinancialFactSuppressionReason.futureDatedTransaction;
    } else if (transaction.isFinanciallyPending) {
      economicReason = FinancialFactSuppressionReason.pendingTransaction;
    } else if (transaction.isSettledByInvoice &&
        transaction.type != 'expense') {
      economicReason = FinancialFactSuppressionReason.invalidSource;
    } else if (transaction.isFinanciallySettled ||
        transaction.isSettledByInvoice) {
      economic = FinancialEconomicFact(
        nature: transaction.type == 'income'
            ? FinancialEconomicNature.income
            : FinancialEconomicNature.expense,
        amount: transaction.value,
        occurredAt: transaction.date,
      );
    } else {
      economicReason = FinancialFactSuppressionReason.invalidSource;
    }

    FinancialCashFact? cash;
    FinancialFactSuppressionReason? cashReason;
    if (!validType || !validAmount) {
      cashReason = FinancialFactSuppressionReason.invalidSource;
    } else if (transaction.isSettlement) {
      cashReason =
          FinancialFactSuppressionReason.settlementCashRequiresSettlementRecord;
    } else if (transaction.isSettledByInvoice) {
      cashReason = FinancialFactSuppressionReason
          .invoicePurchaseHasNoImmediateCashEffect;
    } else if (!transaction.isFinanciallySettled) {
      cashReason = FinancialFactSuppressionReason.pendingTransaction;
    } else {
      final settledAt = _dateOnly(
        transaction.financialSettledAt ?? transaction.date,
      );
      if (settledAt.isAfter(referenceDate)) {
        cashReason = FinancialFactSuppressionReason.futureDatedSettlement;
      } else {
        cash = FinancialCashFact(
          nature: transaction.type == 'income'
              ? FinancialCashNature.inflow
              : FinancialCashNature.outflow,
          amount: transaction.value,
          occurredAt: transaction.financialSettledAt ?? transaction.date,
        );
      }
    }

    FinancialKnownCommitment? commitment;
    FinancialFactSuppressionReason? commitmentReason;
    if (!validType || !validAmount) {
      commitmentReason = FinancialFactSuppressionReason.invalidSource;
    } else if (transaction.isSettlement) {
      commitmentReason =
          FinancialFactSuppressionReason.settlementIsNotKnownCommitment;
    } else if (transaction.isRecurring) {
      commitmentReason =
          FinancialFactSuppressionReason.recurringHandledAsVirtualCommitment;
    } else if (transaction.isInstallment && isFuture) {
      if (date.isAfter(commitmentRangeEnd)) {
        commitmentReason =
            FinancialFactSuppressionReason.installmentOutsideCommitmentHorizon;
      } else {
        commitment = FinancialKnownCommitment(
          kind: FinancialCommitmentKind.installment,
          amount: transaction.value,
          dueAt: transaction.date,
        );
      }
    } else if (transaction.isFinanciallyPending) {
      commitment = FinancialKnownCommitment(
        kind: FinancialCommitmentKind.pending,
        amount: transaction.value,
        dueAt: transaction.date,
      );
    } else if (transaction.isSettledByInvoice) {
      commitmentReason =
          FinancialFactSuppressionReason.creditCardPurchaseRequiresInvoiceLink;
    } else {
      commitmentReason =
          FinancialFactSuppressionReason.settledTransactionIsNotCommitment;
    }

    return FinancialFactBundle(
      source: source,
      economic: economic,
      cash: cash,
      commitment: commitment,
      responsibilities: responsibility.values,
      economicSuppressionReason: economicReason,
      cashSuppressionReason: cashReason,
      commitmentSuppressionReason: commitmentReason,
      responsibilitySuppressionReason: responsibility.reason,
    );
  }

  List<FinancialFactBundle> _futureRecurringCommitments({
    required TransactionModel transaction,
    required FinancialFactNormalizationInput input,
    required DateTime referenceDate,
    required DateTime rangeEnd,
  }) {
    if (!_isPositiveAmount(transaction.value)) return const [];
    final start = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day + 1,
    );
    final occurrences = _recurringTransactionService.generateOccurrences(
      transaction: transaction,
      rangeStart: start,
      rangeEnd: rangeEnd,
    );
    return List.unmodifiable(
      occurrences.map((occurrence) {
        final occurrenceId =
            '${transaction.id}@${occurrence.toIso8601String()}';
        return FinancialFactBundle(
          source: FinancialFactSource(
            kind: FinancialFactSourceKind.recurringOccurrence,
            id: occurrenceId,
            relatedSourceId: transaction.id,
            walletId: input.wallet.id,
            walletScope: _scopeFor(input.wallet),
            category: _canonicalCategory(transaction.category),
            subcategory: _text(transaction.subcategory),
            paidByMemberId: _text(transaction.paidByMemberId),
            purchaseFor: _text(transaction.purchaseFor),
            paymentSourceId: _text(transaction.paymentSourceId),
            recurringId: _text(transaction.recurringId),
          ),
          commitment: FinancialKnownCommitment(
            kind: FinancialCommitmentKind.recurring,
            amount: transaction.value,
            dueAt: occurrence,
          ),
          economicSuppressionReason: FinancialFactSuppressionReason
              .futureRecurringOccurrenceIsNotEconomic,
          cashSuppressionReason: FinancialFactSuppressionReason
              .futureRecurringOccurrenceIsNotEconomic,
          responsibilitySuppressionReason:
              FinancialFactSuppressionReason.unconfirmedSharedResponsibility,
        );
      }),
    );
  }

  FinancialFactBundle _fromInvoice({
    required FinancialCardInvoiceSource source,
    required WalletModel wallet,
    required DateTime referenceDate,
  }) {
    final invoice = source.invoice;
    final validAmount = _isPositiveAmount(invoice.total);
    final paidFromSelectedWallet = invoice.paymentWalletId?.trim() == wallet.id;
    FinancialCashFact? cash;
    FinancialFactSuppressionReason? cashReason;
    FinancialKnownCommitment? commitment;
    FinancialFactSuppressionReason? commitmentReason;

    if (!validAmount) {
      cashReason = FinancialFactSuppressionReason.invalidSource;
      commitmentReason = FinancialFactSuppressionReason.invalidSource;
    } else if (invoice.isPaid) {
      if (paidFromSelectedWallet && invoice.paidAt != null) {
        final paidAt = _dateOnly(invoice.paidAt!);
        if (paidAt.isAfter(referenceDate)) {
          cashReason = FinancialFactSuppressionReason.futureDatedSettlement;
        } else {
          cash = FinancialCashFact(
            nature: FinancialCashNature.invoicePaymentOut,
            amount: invoice.total,
            occurredAt: invoice.paidAt!,
          );
        }
      } else {
        cashReason =
            FinancialFactSuppressionReason.paidInvoiceMissingCashEvidence;
      }
      commitmentReason =
          FinancialFactSuppressionReason.paidInvoiceIsNotCommitment;
    } else {
      cashReason = FinancialFactSuppressionReason.openInvoiceHasNoCashEffect;
      commitment = FinancialKnownCommitment(
        kind: FinancialCommitmentKind.creditCardInvoice,
        amount: invoice.total,
        dueAt: invoice.dueDate,
      );
    }

    return FinancialFactBundle(
      source: FinancialFactSource(
        kind: FinancialFactSourceKind.creditCardInvoice,
        id: _invoiceSourceId(invoice.cardId, invoice.id),
        walletId: wallet.id,
        walletScope: _scopeFor(wallet),
        relatedSourceId: source.walletId,
        invoiceReferenceYear: invoice.referenceYear,
        invoiceReferenceMonth: invoice.referenceMonth,
        invoiceClosingDate: invoice.closingDate,
        invoiceDueDate: invoice.dueDate,
        invoicePaidAt: invoice.paidAt,
      ),
      cash: cash,
      commitment: commitment,
      economicSuppressionReason:
          FinancialFactSuppressionReason.invoiceIsNotEconomic,
      cashSuppressionReason: cashReason,
      commitmentSuppressionReason: commitmentReason,
    );
  }

  FinancialFactBundle _fromTransfer({
    required AccountTransfer transfer,
    required WalletModel wallet,
    required bool isFromWallet,
    required bool isToWallet,
  }) {
    final valid =
        _isPositiveAmount(transfer.amount) &&
        transfer.fromId.trim() != transfer.toId.trim() &&
        isFromWallet != isToWallet;
    return FinancialFactBundle(
      source: FinancialFactSource(
        kind: FinancialFactSourceKind.accountTransfer,
        id: transfer.id,
        walletId: wallet.id,
        walletScope: _scopeFor(wallet),
      ),
      cash: valid
          ? FinancialCashFact(
              nature: isFromWallet
                  ? FinancialCashNature.internalTransferOut
                  : FinancialCashNature.internalTransferIn,
              amount: transfer.amount,
              occurredAt: transfer.date,
            )
          : null,
      economicSuppressionReason:
          FinancialFactSuppressionReason.transferIsNotEconomic,
      cashSuppressionReason: valid
          ? null
          : FinancialFactSuppressionReason.invalidSource,
      commitmentSuppressionReason:
          FinancialFactSuppressionReason.transferIsNotCommitment,
    );
  }

  FinancialFactBundle _fromSettlement({
    required BalanceSettlementModel settlement,
    required WalletModel wallet,
    required bool isPayerWallet,
    required bool isReceiverWallet,
    required DateTime referenceDate,
  }) {
    final settledAt = settlement.settledAt;
    final valid =
        settlement.isSettled &&
        settledAt != null &&
        _isPositiveAmount(settlement.amount) &&
        isPayerWallet != isReceiverWallet;
    final future =
        settledAt != null &&
        valid &&
        _dateOnly(settledAt).isAfter(referenceDate);
    return FinancialFactBundle(
      source: FinancialFactSource(
        kind: FinancialFactSourceKind.settlement,
        id: settlement.id,
        walletId: wallet.id,
        walletScope: _scopeFor(wallet),
        relatedSourceId: settlement.walletId,
        paidByMemberId: _text(settlement.fromMemberId),
        purchaseFor: 'partner',
      ),
      cash: valid && !future
          ? FinancialCashFact(
              nature: isPayerWallet
                  ? FinancialCashNature.settlementOut
                  : FinancialCashNature.settlementIn,
              amount: settlement.amount,
              occurredAt: settledAt,
            )
          : null,
      economicSuppressionReason:
          FinancialFactSuppressionReason.settlementIsNotEconomicConsumption,
      cashSuppressionReason: !valid
          ? FinancialFactSuppressionReason
                .settlementCashRequiresSettlementRecord
          : future
          ? FinancialFactSuppressionReason.futureDatedSettlement
          : null,
      commitmentSuppressionReason:
          FinancialFactSuppressionReason.settlementIsNotKnownCommitment,
    );
  }

  FinancialFactSource _transactionSource(
    TransactionModel transaction,
    WalletModel wallet,
  ) {
    return FinancialFactSource(
      kind: FinancialFactSourceKind.transaction,
      id: transaction.id,
      walletId: wallet.id,
      walletScope: _scopeFor(wallet),
      category: _canonicalCategory(transaction.category),
      subcategory: _text(transaction.subcategory),
      paidByMemberId: _text(transaction.paidByMemberId),
      purchaseFor: _text(transaction.purchaseFor),
      paymentSourceId: _text(transaction.paymentSourceId),
      installmentGroupId: _text(transaction.installmentGroupId),
      installmentNumber: transaction.installmentNumber,
      installmentCount: transaction.installmentCount,
      recurringId: _text(transaction.recurringId),
    );
  }

  _ResponsibilityResolution _responsibilitiesFor(TransactionModel transaction) {
    if (!transaction.hasFinancialSplit) {
      return const _ResponsibilityResolution();
    }
    if (!transaction.canAffectSharedBalance) {
      return const _ResponsibilityResolution(
        reason: FinancialFactSuppressionReason.unconfirmedSharedResponsibility,
      );
    }
    final shares = transaction.memberShares;
    final normalized = <FinancialMemberResponsibility>[];
    var totalInCents = 0;
    for (final entry in shares.entries) {
      final memberId = _text(entry.key);
      if (memberId == null || !_isPositiveAmount(entry.value)) {
        return const _ResponsibilityResolution(
          reason: FinancialFactSuppressionReason.invalidMemberResponsibilities,
        );
      }
      totalInCents += (entry.value * 100).round();
      normalized.add(
        FinancialMemberResponsibility(memberId: memberId, amount: entry.value),
      );
    }
    if (normalized.isEmpty ||
        totalInCents != (transaction.value * 100).round()) {
      return const _ResponsibilityResolution(
        reason: FinancialFactSuppressionReason.invalidMemberResponsibilities,
      );
    }
    return _ResponsibilityResolution(values: List.unmodifiable(normalized));
  }

  List<TransactionModel> _orderedTransactions(
    Iterable<TransactionModel> transactions,
  ) {
    final ordered = transactions.toList()
      ..sort((first, second) {
        final date = first.date.compareTo(second.date);
        return date == 0 ? first.id.compareTo(second.id) : date;
      });
    return ordered;
  }

  FinancialWalletScope _scopeFor(WalletModel wallet) => wallet.isShared
      ? FinancialWalletScope.sharedWallet
      : FinancialWalletScope.individualWallet;

  String _invoiceSourceId(String cardId, String invoiceId) =>
      '$cardId:$invoiceId';

  String? _canonicalCategory(String value) {
    final normalized = value.trim();
    return normalized.isEmpty
        ? null
        : DuoTaxonomy.canonicalCategory(normalized);
  }

  String? _text(Object? value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  bool _isPositiveAmount(double value) => value.isFinite && value > 0;

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class _ResponsibilityResolution {
  const _ResponsibilityResolution({this.values = const [], this.reason});

  final List<FinancialMemberResponsibility> values;
  final FinancialFactSuppressionReason? reason;
}
