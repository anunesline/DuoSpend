import 'package:flutter/foundation.dart';

import '../../../home/data/models/credit_card_invoice_model.dart';
import '../../../home/data/models/credit_card_model.dart';
import '../../../home/data/repositories/credit_card_repository.dart';

class CreditCardController extends ChangeNotifier {
  final CreditCardRepository _repository;

  CreditCardController({
    CreditCardRepository? repository,
  }) : _repository = repository ?? CreditCardRepository();

  List<CreditCardModel> _cards = const [];
  final Map<String, List<CreditCardInvoiceModel>>
      _invoicesByCardId = {};

  bool _isLoading = false;
  final Set<String> _processingIds = {};
  String? _errorMessage;

  List<CreditCardModel> get cards =>
      List<CreditCardModel>.unmodifiable(_cards);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCards => _cards.isNotEmpty;

  bool isProcessing(String id) {
    return _processingIds.contains(id.trim());
  }

  List<CreditCardInvoiceModel> invoicesFor(String cardId) {
    return List<CreditCardInvoiceModel>.unmodifiable(
      _invoicesByCardId[cardId] ?? const [],
    );
  }

  Future<void> loadCards() async {
    _setLoading(true);

    try {
      _cards = await _repository.getCards();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Não foi possível carregar os cartões.';
      debugPrint('Erro ao carregar cartões: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<CreditCardModel?> createCard({
    required String name,
    required String walletId,
    required double creditLimit,
    required int closingDay,
    required int dueDay,
    String? lastFourDigits,
  }) async {
    if (_isLoading) {
      return null;
    }

    _setLoading(true);

    try {
      final card = await _repository.createCard(
        name: name,
        walletId: walletId,
        creditLimit: creditLimit,
        closingDay: closingDay,
        dueDay: dueDay,
        lastFourDigits: lastFourDigits,
      );

      _cards = [..._cards, card]
        ..sort((first, second) => first.name
            .toLowerCase()
            .compareTo(second.name.toLowerCase()));
      _errorMessage = null;

      return card;
    } catch (error) {
      _errorMessage = _formatError(error);
      debugPrint('Erro ao criar cartão: $error');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadInvoices(String cardId) async {
    final normalizedCardId = cardId.trim();

    if (normalizedCardId.isEmpty ||
        isProcessing(normalizedCardId)) {
      return;
    }

    _setProcessing(normalizedCardId, true);

    try {
      _invoicesByCardId[normalizedCardId] =
          await _repository.getInvoices(
        cardId: normalizedCardId,
      );
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Não foi possível carregar as faturas.';
      debugPrint('Erro ao carregar faturas: $error');
    } finally {
      _setProcessing(normalizedCardId, false);
    }
  }

  Future<bool> payInvoice({
    required CreditCardModel card,
    required CreditCardInvoiceModel invoice,
    String? walletId,
  }) async {
    final processingId = '${card.id}:${invoice.id}';

    if (isProcessing(processingId)) {
      return false;
    }

    _setProcessing(processingId, true);

    try {
      final paidInvoice = await _repository.payInvoice(
        cardId: card.id,
        invoiceId: invoice.id,
        walletId: walletId,
      );

      final invoices = List<CreditCardInvoiceModel>.from(
        _invoicesByCardId[card.id] ?? const [],
      );
      final index = invoices.indexWhere(
        (item) => item.id == paidInvoice.id,
      );

      if (index == -1) {
        invoices.insert(0, paidInvoice);
      } else {
        invoices[index] = paidInvoice;
      }

      _invoicesByCardId[card.id] = invoices;
      await loadCards();
      _errorMessage = null;

      return true;
    } catch (error) {
      _errorMessage = _formatError(error);
      debugPrint('Erro ao pagar fatura: $error');
      return false;
    } finally {
      _setProcessing(processingId, false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setProcessing(String id, bool value) {
    if (value) {
      _processingIds.add(id);
    } else {
      _processingIds.remove(id);
    }
    notifyListeners();
  }

  String _formatError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Invalid argument(s): ', '')
        .replaceFirst('Exception: ', '');
  }
}
