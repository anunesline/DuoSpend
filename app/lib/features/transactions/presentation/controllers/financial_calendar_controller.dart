import 'package:flutter/foundation.dart';

import '../../../home/data/models/credit_card_invoice_model.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../home/data/repositories/credit_card_repository.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/calendar/financial_calendar_entry.dart';
import '../../domain/calendar/financial_calendar_service.dart';
import '../../domain/calendar/financial_projection.dart';

class FinancialCalendarController extends ChangeNotifier {
  final CreditCardRepository _creditCardRepository;
  final FinancialCalendarService _calendarService;

  FinancialCalendarController({
    CreditCardRepository? creditCardRepository,
    FinancialCalendarService calendarService =
        const FinancialCalendarService(),
  }) : _creditCardRepository =
           creditCardRepository ?? CreditCardRepository(),
       _calendarService = calendarService;

  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  DateTime? selectedDay;
  bool isLoading = false;
  String? errorMessage;
  FinancialProjection projection = FinancialProjection.empty(0);
  List<FinancialCalendarEntry> monthEntries = const [];
  List<CreditCardInvoiceModel> _invoices = const [];

  Future<void> load({
    required WalletModel wallet,
    required List<TransactionModel> transactions,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _invoices = await _loadWalletInvoices(wallet);
      _recalculate(
        wallet: wallet,
        transactions: transactions,
      );
    } catch (error, stackTrace) {
      debugPrint('Erro ao carregar calendário financeiro: $error');
      debugPrintStack(stackTrace: stackTrace);
      projection = FinancialProjection.empty(wallet.balance);
      monthEntries = const [];
      errorMessage = 'Não foi possível carregar o calendário financeiro.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void previousMonth({
    required WalletModel wallet,
    required List<TransactionModel> transactions,
  }) {
    selectedMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month - 1,
    );
    selectedDay = null;
    _recalculate(wallet: wallet, transactions: transactions);
    notifyListeners();
  }

  void nextMonth({
    required WalletModel wallet,
    required List<TransactionModel> transactions,
  }) {
    selectedMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
    );
    selectedDay = null;
    _recalculate(wallet: wallet, transactions: transactions);
    notifyListeners();
  }

  void selectDay(DateTime day) {
    selectedDay = DateTime(day.year, day.month, day.day);
    notifyListeners();
  }

  List<FinancialCalendarEntry> get visibleEntries {
    final day = selectedDay;
    if (day == null) {
      return monthEntries;
    }

    return List<FinancialCalendarEntry>.unmodifiable(
      monthEntries.where(
        (entry) =>
            entry.date.year == day.year &&
            entry.date.month == day.month &&
            entry.date.day == day.day,
      ),
    );
  }

  void _recalculate({
    required WalletModel wallet,
    required List<TransactionModel> transactions,
  }) {
    final monthStart = DateTime(selectedMonth.year, selectedMonth.month);
    final monthEnd = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
      23,
      59,
      59,
    );
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final monthProjection = _calendarService.buildProjection(
      currentBalance: wallet.balance,
      transactions: transactions,
      invoices: _invoices,
      rangeStart: monthStart,
      rangeEnd: monthEnd,
      now: today,
    );
    monthEntries = monthProjection.entries;

    if (monthEnd.isBefore(todayOnly)) {
      projection = FinancialProjection(
        currentBalance: wallet.balance,
        projectedIncome: 0,
        projectedExpense: 0,
        projectedBalance: wallet.balance,
        entries: monthEntries,
      );
      return;
    }

    projection = _calendarService.buildProjection(
      currentBalance: wallet.balance,
      transactions: transactions,
      invoices: _invoices,
      rangeStart: todayOnly,
      rangeEnd: monthEnd,
      now: today,
    );
  }

  Future<List<CreditCardInvoiceModel>> _loadWalletInvoices(
    WalletModel wallet,
  ) async {
    if (!wallet.isIndividual) {
      return const [];
    }

    final cards = await _creditCardRepository.getCards();
    final linkedCards = cards.where((card) => card.walletId == wallet.id);
    final invoices = <CreditCardInvoiceModel>[];

    for (final card in linkedCards) {
      invoices.addAll(
        await _creditCardRepository.getInvoices(cardId: card.id),
      );
    }

    return List<CreditCardInvoiceModel>.unmodifiable(invoices);
  }
}
