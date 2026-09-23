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
  final double? subtotal;
  final double? discount;
  final String? paymentMethodSuggestion;
  final List<ReceiptScanItem> items;

  const ReceiptTransactionDraft({
    required this.description,
    this.purchaseDate,
    this.amount,
    this.subtotal,
    this.discount,
    this.paymentMethodSuggestion,
    this.items = const [],
  });

  factory ReceiptTransactionDraft.fromScanResult(ReceiptScanResult result) {
    return ReceiptTransactionDraft(
      description: result.merchant ?? '',
      purchaseDate: result.date,
      amount: result.totalAmount,
      subtotal: result.subtotal,
      discount: result.discount,
      paymentMethodSuggestion: result.paymentMethodSuggestion,
      items: List.unmodifiable(result.items),
    );
  }

  bool get canContinueToTransaction {
    return description.trim().isNotEmpty &&
        purchaseDate != null &&
        amount != null &&
        amount! > 0 &&
        amount!.isFinite &&
        (discount == null || (discount!.isFinite && discount! >= 0)) &&
        !hasTotalDivergence &&
        items.isNotEmpty &&
        items.every(
          (item) =>
              item.description.trim().isNotEmpty &&
              item.quantity != null &&
              item.quantity! > 0 &&
              item.unit?.trim().isNotEmpty == true &&
              item.unitPrice != null &&
              item.unitPrice! > 0 &&
              item.totalPrice != null &&
              item.totalPrice! > 0,
        );
  }

  /// Total dos itens somente quando todos têm valor total conhecido.
  ///
  /// A revisão usa este cálculo para exigir uma decisão explícita do usuário
  /// em vez de escolher silenciosamente entre total fiscal e soma dos itens.
  double? get itemsTotal {
    if (items.isEmpty || items.any((item) => item.totalPrice == null)) {
      return null;
    }

    return items.fold<double>(0, (total, item) => total + item.totalPrice!);
  }

  bool get hasTotalDivergence {
    final resolvedItemsTotal = itemsTotal;
    return resolvedItemsTotal != null &&
        amount != null &&
        (resolvedItemsTotal - (discount ?? 0) - amount!).abs() >= 0.01;
  }

  ReceiptTransactionDraft copyWith({
    String? description,
    DateTime? purchaseDate,
    double? amount,
    double? subtotal,
    double? discount,
    String? paymentMethodSuggestion,
    List<ReceiptScanItem>? items,
    bool clearPurchaseDate = false,
    bool clearAmount = false,
    bool clearDiscount = false,
    bool clearPaymentMethodSuggestion = false,
  }) {
    return ReceiptTransactionDraft(
      description: description ?? this.description,
      purchaseDate: clearPurchaseDate
          ? null
          : purchaseDate ?? this.purchaseDate,
      amount: clearAmount ? null : amount ?? this.amount,
      subtotal: subtotal ?? this.subtotal,
      discount: clearDiscount ? null : discount ?? this.discount,
      paymentMethodSuggestion: clearPaymentMethodSuggestion
          ? null
          : paymentMethodSuggestion ?? this.paymentMethodSuggestion,
      items: items ?? this.items,
    );
  }
}
