import 'receipt_scan_item.dart';
import 'receipt_scan_result.dart';

/// Rascunho temporário que alimenta a tela de revisão.
///
/// Não é um `TransactionModel`, não possui carteira e não persiste dados.
/// A tela de Nova Transação completa os campos financeiros e, somente após a
/// confirmação do usuário, aciona o fluxo financeiro já existente.
class ReceiptTransactionDraft {
  final String description;
  final DateTime? purchaseDate;
  final double? amount;
  final String? paymentMethodSuggestion;
  final List<ReceiptScanItem> items;

  const ReceiptTransactionDraft({
    required this.description,
    this.purchaseDate,
    this.amount,
    this.paymentMethodSuggestion,
    this.items = const [],
  });

  factory ReceiptTransactionDraft.fromScanResult(ReceiptScanResult result) {
    return ReceiptTransactionDraft(
      description: result.merchant ?? '',
      purchaseDate: result.date,
      amount: result.totalAmount,
      paymentMethodSuggestion: result.paymentMethodSuggestion,
      items: List.unmodifiable(result.items),
    );
  }

  bool get canContinueToTransaction {
    return description.trim().isNotEmpty && amount != null && amount! > 0;
  }

  ReceiptTransactionDraft copyWith({
    String? description,
    DateTime? purchaseDate,
    double? amount,
    String? paymentMethodSuggestion,
    List<ReceiptScanItem>? items,
    bool clearPurchaseDate = false,
    bool clearAmount = false,
    bool clearPaymentMethodSuggestion = false,
  }) {
    return ReceiptTransactionDraft(
      description: description ?? this.description,
      purchaseDate: clearPurchaseDate
          ? null
          : purchaseDate ?? this.purchaseDate,
      amount: clearAmount ? null : amount ?? this.amount,
      paymentMethodSuggestion: clearPaymentMethodSuggestion
          ? null
          : paymentMethodSuggestion ?? this.paymentMethodSuggestion,
      items: items ?? this.items,
    );
  }
}
