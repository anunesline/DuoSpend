import 'package:flutter/foundation.dart';

import '../../../home/data/models/credit_card_invoice_model.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../home/data/repositories/credit_card_repository.dart';
import '../../../home/data/repositories/wallet_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/calendar/financial_calendar_entry.dart';
import '../../domain/calendar/financial_calendar_service.dart';
import '../../domain/calendar/financial_projection.dart';

class FinancialCalendarController extends ChangeNotifier {
  final CreditCardRepository _creditCardRepository;
  final FinancialCalendarService _calendarService;
  final TransactionRepository _transactionRepository;
  final WalletRepository _walletRepository;

  FinancialCalendarController({
    CreditCardRepository? creditCardRepository,
    FinancialCalendarService calendarService =
        const FinancialCalendarService(),
    TransactionRepository? transactionRepository,
    WalletRepository? walletRepository,
  }) : _creditCardRepository =
           creditCardRepository ?? CreditCardRepository(),
       _calendarService = calendarService,
       _transactionRepository =
           transactionRepository ?? TransactionRepository(),
       _walletRepository = walletRepository ?? WalletRepository();

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
  List<TransactionModel> _transactions = const [];
  bool isSettling = false;
  double _currentBalance = 0;

  Future<void> load({
    required WalletModel wallet,
    required List<TransactionModel> transactions,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _currentBalance = wallet.balance;
      _transactions = List<TransactionModel>.unmodifiable(transactions);
      _invoices = await _loadWalletInvoices(wallet);
      _recalculate(wallet: wallet);
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
  }) {
    selectedMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month - 1,
    );
    selectedDay = null;
    _recalculate(wallet: wallet);
    notifyListeners();
  }

  void nextMonth({
    required WalletModel wallet,
  }) {
    selectedMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
    );
    selectedDay = null;
    _recalculate(wallet: wallet);
    notifyListeners();
  }

  void selectDay(DateTime day) {
    selectedDay = DateTime(day.year, day.month, day.day);
    notifyListeners();
  }

  void clearDaySelection() {
    selectedDay = null;
    notifyListeners();
  }

  Future<bool> settleEntry({
    required FinancialCalendarEntry entry,
    required WalletModel transactionWallet,
  }) async {
    final obligation = entry.transaction;

    if (isSettling ||
        obligation == null ||
        !obligation.isFinanciallyPending) {
      return false;
    }

    isSettling = true;
    errorMessage = null;
    notifyListeners();

    try {
      final sourceWalletId = obligation.paymentSourceId?.trim();
      final financialWalletId =
          sourceWalletId != null && sourceWalletId.isNotEmpty
              ? sourceWalletId
              : transactionWallet.isIndividual
                  ? transactionWallet.id
                  : null;

      if (financialWalletId == null) {
        throw StateError(
          'Selecione uma carteira individual para liquidar esta obrigação.',
        );
      }

      final financialWallet =
          await _walletRepository.getWalletById(financialWalletId);

      if (financialWallet == null) {
        throw StateError('Carteira financeira não encontrada.');
      }

      final settled = await _transactionRepository
          .settleFinancialObligation(
        obligation: obligation,
        transactionWallet: transactionWallet,
        financialWallet: financialWallet,
      );

      _transactions = List<TransactionModel>.unmodifiable(
        _transactions.map(
          (transaction) =>
              transaction.id == settled.id ? settled : transaction,
        ),
      );

      if (financialWallet.id == transactionWallet.id) {
        _currentBalance += settled.type == 'income'
            ? settled.value
            : -settled.value;
      }

      _recalculate(wallet: transactionWallet);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Erro ao liquidar obrigação: $error');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage = _formatError(error);
      return false;
    } finally {
      isSettling = false;
      notifyListeners();
    }
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
      currentBalance: _currentBalance,
      transactions: _transactions,
      invoices: _invoices,
      rangeStart: monthStart,
      rangeEnd: monthEnd,
      now: today,
    );
    monthEntries = monthProjection.entries;

    if (monthEnd.isBefore(todayOnly)) {
      projection = FinancialProjection(
        currentBalance: _currentBalance,
        projectedIncome: 0,
        projectedExpense: 0,
        projectedBalance: _currentBalance,
        entries: monthEntries,
      );
      return;
    }

    projection = _calendarService.buildProjection(
      currentBalance: _currentBalance,
      transactions: _transactions,
      invoices: _invoices,
      rangeStart: todayOnly,
      rangeEnd: monthEnd,
      now: today,
    );
  }

  String _formatError(Object error) {
    final message = error.toString();
    if (message.startsWith('Bad state: ')) {
      return message.substring('Bad state: '.length);
    }
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
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
