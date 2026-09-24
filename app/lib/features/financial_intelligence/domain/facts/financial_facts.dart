import '../../../finances/data/financial_accounts_repository.dart';
import '../../../home/data/models/credit_card_invoice_model.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../transactions/data/models/balance_settlement_model.dart';
import '../../../transactions/data/models/transaction_model.dart';

/// The persisted source from which a normalized financial fact was derived.
enum FinancialFactSourceKind {
  transaction,
  recurringOccurrence,
  creditCardInvoice,
  accountTransfer,
  settlement,
}

enum FinancialWalletScope { individualWallet, sharedWallet }

enum FinancialEconomicNature { income, expense }

enum FinancialCashNature {
  inflow,
  outflow,
  internalTransferIn,
  internalTransferOut,
  invoicePaymentOut,
  settlementIn,
  settlementOut,
}

enum FinancialCommitmentKind {
  pending,
  installment,
  recurring,
  creditCardInvoice,
}

enum FinancialCommitmentDirection { inflow, outflow }

enum FinancialFactEligibility { eligible, conditionallyEligible, suppressed }

/// Why a source deliberately has no fact in one of the financial dimensions.
///
/// Suppression is a valid deterministic result. It prevents later layers from
/// turning missing evidence into an inferred financial fact.
enum FinancialFactSuppressionReason {
  invalidSource,
  foreignWalletSource,
  unsupportedTransactionType,
  futureDatedTransaction,
  futureDatedSettlement,
  pendingTransaction,
  invoicePurchaseHasNoImmediateCashEffect,
  creditCardPurchaseRequiresInvoiceLink,
  settlementIsNotEconomicConsumption,
  settlementCashRequiresSettlementRecord,
  settlementIsNotKnownCommitment,
  transferIsNotEconomic,
  transferIsNotCommitment,
  invoiceIsNotEconomic,
  openInvoiceHasNoCashEffect,
  paidInvoiceIsNotCommitment,
  paidInvoiceMissingCashEvidence,
  settledTransactionIsNotCommitment,
  recurringHandledAsVirtualCommitment,
  futureInstallmentIsNotEconomic,
  installmentOutsideCommitmentHorizon,
  futureRecurringOccurrenceIsNotEconomic,
  unconfirmedSharedResponsibility,
  invalidMemberResponsibilities,
}

class FinancialFactSource {
  const FinancialFactSource({
    required this.kind,
    required this.id,
    required this.walletId,
    required this.walletScope,
    this.relatedSourceId,
    this.category,
    this.subcategory,
    this.paidByMemberId,
    this.purchaseFor,
    this.paymentSourceId,
    this.installmentGroupId,
    this.installmentNumber,
    this.installmentCount,
    this.recurringId,
    this.invoiceReferenceYear,
    this.invoiceReferenceMonth,
    this.invoiceClosingDate,
    this.invoiceDueDate,
    this.invoicePaidAt,
  });

  final FinancialFactSourceKind kind;
  final String id;
  final String walletId;
  final FinancialWalletScope walletScope;
  final String? relatedSourceId;
  final String? category;
  final String? subcategory;
  final String? paidByMemberId;
  final String? purchaseFor;
  final String? paymentSourceId;
  final String? installmentGroupId;
  final int? installmentNumber;
  final int? installmentCount;
  final String? recurringId;
  final int? invoiceReferenceYear;
  final int? invoiceReferenceMonth;
  final DateTime? invoiceClosingDate;
  final DateTime? invoiceDueDate;
  final DateTime? invoicePaidAt;
}

class FinancialEconomicFact {
  const FinancialEconomicFact({
    required this.nature,
    required this.amount,
    required this.occurredAt,
  });

  final FinancialEconomicNature nature;
  final double amount;
  final DateTime occurredAt;
}

class FinancialCashFact {
  const FinancialCashFact({
    required this.nature,
    required this.amount,
    required this.occurredAt,
  });

  final FinancialCashNature nature;
  final double amount;
  final DateTime occurredAt;
}

class FinancialKnownCommitment {
  const FinancialKnownCommitment({
    required this.kind,
    required this.direction,
    required this.amount,
    required this.dueAt,
  });

  final FinancialCommitmentKind kind;
  final FinancialCommitmentDirection direction;
  final double amount;
  final DateTime dueAt;
}

/// A share attributes one economic fact. It is never an additional expense.
class FinancialMemberResponsibility {
  const FinancialMemberResponsibility({
    required this.memberId,
    required this.amount,
  });

  final String memberId;
  final double amount;
}

/// Composition root for a single persisted source or deterministic virtual
/// recurrence occurrence. Each dimension is optional by design.
class FinancialFactBundle {
  const FinancialFactBundle({
    required this.source,
    this.economic,
    this.cash,
    this.commitment,
    this.responsibilities = const [],
    this.economicSuppressionReason,
    this.cashSuppressionReason,
    this.commitmentSuppressionReason,
    this.responsibilitySuppressionReason,
  });

  final FinancialFactSource source;
  final FinancialEconomicFact? economic;
  final FinancialCashFact? cash;
  final FinancialKnownCommitment? commitment;
  final List<FinancialMemberResponsibility> responsibilities;
  final FinancialFactSuppressionReason? economicSuppressionReason;
  final FinancialFactSuppressionReason? cashSuppressionReason;
  final FinancialFactSuppressionReason? commitmentSuppressionReason;
  final FinancialFactSuppressionReason? responsibilitySuppressionReason;
}

class FinancialSuppressedSource {
  const FinancialSuppressedSource({
    required this.kind,
    required this.id,
    required this.reason,
  });

  final FinancialFactSourceKind kind;
  final String id;
  final FinancialFactSuppressionReason reason;
}

class FinancialCardInvoiceSource {
  const FinancialCardInvoiceSource({
    required this.invoice,
    required this.walletId,
  });

  /// The provable wallet scope of the card/invoice, usually the card wallet.
  final String walletId;
  final CreditCardInvoiceModel invoice;
}

class FinancialFactNormalizationInput {
  const FinancialFactNormalizationInput({
    required this.wallet,
    required this.referenceAt,
    required this.commitmentRangeEnd,
    this.transactions = const [],
    this.invoices = const [],
    this.transfers = const [],
    this.settlements = const [],
  });

  final WalletModel wallet;
  final DateTime referenceAt;
  final DateTime commitmentRangeEnd;
  final List<TransactionModel> transactions;
  final List<FinancialCardInvoiceSource> invoices;
  final List<AccountTransfer> transfers;
  final List<BalanceSettlementModel> settlements;
}

class FinancialFactNormalizationResult {
  const FinancialFactNormalizationResult({
    required this.facts,
    required this.suppressedSources,
  });

  final List<FinancialFactBundle> facts;
  final List<FinancialSuppressedSource> suppressedSources;

  Iterable<FinancialEconomicFact> get economicFacts =>
      facts.map((fact) => fact.economic).whereType<FinancialEconomicFact>();

  Iterable<FinancialCashFact> get cashFacts =>
      facts.map((fact) => fact.cash).whereType<FinancialCashFact>();

  Iterable<FinancialKnownCommitment> get commitments => facts
      .map((fact) => fact.commitment)
      .whereType<FinancialKnownCommitment>();
}
