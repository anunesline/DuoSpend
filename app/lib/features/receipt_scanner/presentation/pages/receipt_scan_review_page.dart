import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/receipt_scan_item.dart';
import '../../domain/models/receipt_transaction_draft.dart';

/// Prévia editável do resultado de OCR. Esta tela não conhece repositórios,
/// carteiras ou controllers financeiros: ela apenas devolve um rascunho.
class ReceiptScanReviewPage extends StatefulWidget {
  final ReceiptTransactionDraft draft;

  const ReceiptScanReviewPage({
    super.key,
    required this.draft,
  });

  @override
  State<ReceiptScanReviewPage> createState() =>
      _ReceiptScanReviewPageState();
}

class _ReceiptScanReviewPageState extends State<ReceiptScanReviewPage> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.draft.description,
    );
    _amountController = TextEditingController(
      text: _formatAmount(widget.draft.amount),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double? get _amount {
    final rawValue = _amountController.text.trim();
    final normalized = rawValue.contains(',')
        ? rawValue.replaceAll('.', '').replaceAll(',', '.')
        : rawValue;
    return double.tryParse(normalized);
  }

  ReceiptTransactionDraft get _draft => widget.draft.copyWith(
    description: _descriptionController.text.trim(),
    amount: _amount,
  );

  double? get _itemsTotal {
    if (widget.draft.items.isEmpty ||
        widget.draft.items.any((item) => item.totalPrice == null)) {
      return null;
    }

    return widget.draft.items.fold<double>(
      0,
      (total, item) => total + item.totalPrice!,
    );
  }

  bool get _hasTotalDivergence {
    final itemsTotal = _itemsTotal;
    final amount = _amount;
    return itemsTotal != null &&
        amount != null &&
        (itemsTotal - amount).abs() >= 0.01;
  }

  void _continue() {
    final draft = _draft;
    if (!draft.canContinueToTransaction) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe estabelecimento e valor antes de continuar.'),
        ),
      );
      return;
    }

    Navigator.pop(context, draft);
  }

  String _formatAmount(double? amount) {
    if (amount == null) return '';
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _buildItem(ReceiptScanItem item) {
    final quantity = item.quantity;
    final unitPrice = item.unitPrice;
    final details = <String>[];
    if (quantity != null) details.add('Qtd. $quantity');
    if (unitPrice != null) {
      details.add('Unit. R\$ ${_formatAmount(unitPrice)}');
    }
    if (item.totalPrice != null) {
      details.add('Total R\$ ${_formatAmount(item.totalPrice)}');
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.description),
      subtitle: details.isEmpty ? null : Text(details.join(' • ')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar nota')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Confira os dados reconhecidos antes de criar a transação.',
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Estabelecimento ou descrição',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor total',
                prefixText: 'R\$ ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (widget.draft.purchaseDate != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Data reconhecida: '
                '${_formatDate(widget.draft.purchaseDate!)}',
              ),
            ],
            if (widget.draft.paymentMethodSuggestion != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pagamento sugerido: '
                '${widget.draft.paymentMethodSuggestion}',
              ),
            ],
            if (widget.draft.items.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Itens reconhecidos',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...widget.draft.items.map(_buildItem),
            ],
            if (_hasTotalDivergence) ...[
              const SizedBox(height: AppSpacing.md),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'A soma dos itens diverge do total informado. '
                    'Revise antes de continuar.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _draft.canContinueToTransaction ? _continue : null,
              child: const Text('Continuar para a transação'),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Nenhuma movimentação será criada nesta etapa.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
