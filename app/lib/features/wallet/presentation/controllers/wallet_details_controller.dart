import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../goals/data/repositories/savings_goal_repository.dart';
import '../../../goals/domain/models/savings_goal.dart';
import '../../../home/data/models/credit_card_invoice_model.dart';
import '../../../home/data/models/credit_card_model.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../home/data/repositories/credit_card_repository.dart';
import '../../../home/data/repositories/wallet_repository.dart';
import '../../../reports/domain/models/financial_report.dart';
import '../../../reports/domain/services/financial_report_service.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../../transactions/domain/calendar/financial_calendar_entry.dart';
import '../../../transactions/domain/calendar/financial_calendar_service.dart';
import '../../../transactions/domain/calendar/financial_projection.dart';

class WalletDetailsData {
  final WalletModel wallet;
  final List<TransactionModel> transactions;
  final List<CreditCardModel> cards;
  final List<CreditCardInvoiceModel> invoices;
  final List<SavingsGoal> goals;

  const WalletDetailsData({
    required this.wallet,
    this.transactions = const [],
    this.cards = const [],
    this.invoices = const [],
    this.goals = const [],
  });

  static Future<WalletDetailsData> load(WalletModel wallet) async {
    final cardsRepository = CreditCardRepository();
    final (freshWallet, transactions, allCards, goals) = await (
      WalletRepository().getWalletById(wallet.id),
      TransactionRepository().getTransactionsByWallet(
        wallet.id,
        wallet: wallet,
      ),
      cardsRepository.getCards(),
      SavingsGoalRepository().getGoalsByWallet(wallet.id),
    ).wait;
    if (freshWallet == null) {
      throw StateError('Carteira indisponível.');
    }
    final cards = allCards.where((card) => card.walletId == wallet.id).toList();
    final invoices = await Future.wait(
      cards.map((card) => cardsRepository.getInvoices(cardId: card.id)),
    );
    return WalletDetailsData(
      wallet: freshWallet,
      transactions: transactions,
      cards: cards,
      invoices: invoices.expand((items) => items).toList(),
      goals: goals,
    );
  }
}

/// Read-only view state. Financial projections use the existing calendar engine.
class WalletDetailsController extends ChangeNotifier {
  final Future<WalletDetailsData> Function(WalletModel) _loader;
  final DateTime Function() _clock;
  final _calendar = const FinancialCalendarService();
  late WalletDetailsData data;
  late DateTime periodStart;
  late DateTime periodEnd;
  bool loading = true;
  bool valuesVisible = true;
  String? error;
  bool _disposed = false;
  int _loadVersion = 0;

  WalletDetailsController({
    required WalletModel wallet,
    Future<WalletDetailsData> Function(WalletModel)? loader,
    DateTime Function()? clock,
  }) : _loader = loader ?? WalletDetailsData.load,
       _clock = clock ?? DateTime.now {
    data = WalletDetailsData(wallet: wallet);
    periodStart = DateTime(today.year, today.month);
    periodEnd = monthEnd;
  }

  DateTime get today {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get monthEnd => DateTime(today.year, today.month + 1, 0);

  Future<void> load() async {
    final version = ++_loadVersion;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _loader(data.wallet);
      if (_disposed || version != _loadVersion) return;
      data = result;
    } catch (_) {
      if (_disposed || version != _loadVersion) return;
      error = 'Não foi possível atualizar a carteira. Tente novamente.';
    } finally {
      if (!_disposed && version == _loadVersion) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void selectPeriod(DateTime start, DateTime end) {
    periodStart = DateTime(start.year, start.month, start.day);
    periodEnd = DateTime(end.year, end.month, end.day);
    notifyListeners();
  }

  void toggleVisibility() {
    valuesVisible = !valuesVisible;
    notifyListeners();
  }

  bool _inPeriod(DateTime date) =>
      !date.isBefore(periodStart) &&
      date.isBefore(periodEnd.add(const Duration(days: 1)));

  List<TransactionModel> get periodTransactions =>
      data.transactions.where((t) => _inPeriod(t.date)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  // Settled cash flow only: credit purchases affect cash at invoice payment.
  Iterable<TransactionModel> get _settledInPeriod => data.transactions.where(
    (t) => t.isFinanciallySettled && _inPeriod(t.financialSettledAt ?? t.date),
  );

  double get income => _settledInPeriod
      .where((t) => t.type == 'income')
      .fold(0.0, (total, t) => total + t.value);

  double get expense => _settledInPeriod
      .where((t) => t.type == 'expense')
      .fold(0.0, (total, t) => total + t.value);

  double get incomeRatio =>
      income + expense == 0 ? 0 : income / (income + expense);
  double get expenseRatio =>
      income + expense == 0 ? 0 : expense / (income + expense);

  double get currentMonthChange {
    final start = DateTime(today.year, today.month);
    final end = today.add(const Duration(days: 1));
    return data.transactions
        .where((t) {
          final date = t.financialSettledAt ?? t.date;
          return t.isFinanciallySettled &&
              !date.isBefore(start) &&
              date.isBefore(end);
        })
        .fold(
          0.0,
          (total, t) => total + (t.type == 'income' ? t.value : -t.value),
        );
  }

  FinancialProjection get forecast => _calendar.buildProjection(
    currentBalance: data.wallet.balance,
    transactions: data.transactions,
    invoices: data.invoices,
    rangeStart: today,
    rangeEnd: monthEnd,
    now: today,
  );

  List<FinancialCalendarEntry> get upcoming => _calendar
      .buildProjection(
        currentBalance: data.wallet.balance,
        transactions: data.transactions,
        invoices: data.invoices,
        rangeStart: today,
        rangeEnd: DateTime(today.year + 1, today.month, today.day),
        now: today,
      )
      .entries
      .where((entry) => entry.isProjected)
      .take(3)
      .toList();

  CreditCardInvoiceModel? currentInvoice(String cardId) {
    final invoices =
        data.invoices
            .where((invoice) => invoice.cardId == cardId && !invoice.isPaid)
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return invoices.isEmpty ? null : invoices.first;
  }

  int get activeGoalCount => data.goals.where((goal) => goal.isActive).length;

  FinancialReport get categoryReport => const FinancialReportService().build(
    transactions: data.transactions,
    startDate: periodStart,
    endDate: periodEnd,
    referenceDate: today,
  );

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
