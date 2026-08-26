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
  late DateTime? _purchaseDate;
  late String? _paymentMethodSuggestion;
  late List<ReceiptScanItem> _items;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.draft.description,
    );
    _amountController = TextEditingController(
      text: _formatAmount(widget.draft.amount),
    );
    _purchaseDate = widget.draft.purchaseDate;
    _paymentMethodSuggestion = widget.draft.paymentMethodSuggestion;
    _items = List.of(widget.draft.items);
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
    purchaseDate: _purchaseDate,
    paymentMethodSuggestion: _paymentMethodSuggestion,
    items: List.unmodifiable(_items),
  );

  Future<void> _selectDate() async {
    final initialDate = _purchaseDate ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (selectedDate == null || !mounted) return;
    setState(() => _purchaseDate = selectedDate);
  }

  double? get _itemsTotal {
    if (_items.isEmpty || _items.any((item) => item.totalPrice == null)) {
      return null;
    }

    return _items.fold<double>(
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

  double? _parseNumber(String value) {
    final rawValue = value.trim();
    if (rawValue.isEmpty) return null;
    final normalized = rawValue.contains(',')
        ? rawValue.replaceAll('.', '').replaceAll(',', '.')
        : rawValue;
    return double.tryParse(normalized);
  }

  void _updateItem(int index, ReceiptScanItem item) {
    setState(() => _items[index] = item);
  }

  Widget _buildItem(int index) {
    final item = _items[index];
    return ExpansionTile(
      key: ValueKey('receipt-item-$index-${item.description}'),
      title: Text(item.description.isEmpty ? 'Item sem descrição' : item.description),
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
      children: [
        TextFormField(
          initialValue: item.description,
          decoration: const InputDecoration(labelText: 'Descrição'),
          onChanged: (value) => _updateItem(
            index,
            item.copyWith(description: value),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: item.quantity == null
                    ? ''
                    : _formatAmount(item.quantity),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantidade'),
                onChanged: (value) => _updateItem(
                  index,
                  item.copyWith(
                    quantity: _parseNumber(value),
                    clearQuantity: value.trim().isEmpty,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                initialValue: item.unit ?? 'un',
                decoration: const InputDecoration(labelText: 'Unidade'),
                onChanged: (value) => _updateItem(
                  index,
                  item.copyWith(unit: value),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: _formatAmount(item.unitPrice),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Valor unitário'),
          onChanged: (value) => _updateItem(
            index,
            item.copyWith(
              unitPrice: _parseNumber(value),
              clearUnitPrice: value.trim().isEmpty,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: _formatAmount(item.totalPrice),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Valor total do item'),
          onChanged: (value) => _updateItem(
            index,
            item.copyWith(
              totalPrice: _parseNumber(value),
              clearTotalPrice: value.trim().isEmpty,
            ),
          ),
        ),
      ],
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
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                _purchaseDate == null
                    ? 'Informar data da compra'
                    : 'Data: ${_formatDate(_purchaseDate!)}',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethodSuggestion,
              decoration: const InputDecoration(
                labelText: 'Forma de pagamento sugerida',
              ),
              items: const [
                DropdownMenuItem(value: 'pix', child: Text('Pix')),
                DropdownMenuItem(
                  value: 'creditCard',
                  child: Text('Cartão de crédito'),
                ),
                DropdownMenuItem(
                  value: 'debitCard',
                  child: Text('Cartão de débito'),
                ),
                DropdownMenuItem(value: 'cash', child: Text('Dinheiro')),
              ],
              onChanged: (value) {
                setState(() => _paymentMethodSuggestion = value);
              },
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Itens reconhecidos',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...List.generate(_items.length, _buildItem),
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
