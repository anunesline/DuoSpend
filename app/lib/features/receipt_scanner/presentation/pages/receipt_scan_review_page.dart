import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/knowledge/products/product_repository.dart';
import '../../../transactions/data/models/product_model.dart';
import '../../application/receipt_product_identity_resolver.dart';
import '../../domain/models/receipt_scan_item.dart';
import '../../domain/models/receipt_transaction_draft.dart';

/// Prévia editável do resultado de OCR. Esta tela não conhece repositórios,
/// carteiras ou controllers financeiros: ela apenas devolve um rascunho.
class ReceiptScanReviewPage extends StatefulWidget {
  final ReceiptTransactionDraft draft;
  final ProductRepository? productRepository;

  const ReceiptScanReviewPage({
    super.key,
    required this.draft,
    this.productRepository,
  });

  @override
  State<ReceiptScanReviewPage> createState() => _ReceiptScanReviewPageState();
}

class _ReceiptScanReviewPageState extends State<ReceiptScanReviewPage> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _discountController;
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
    _discountController = TextEditingController(
      text: _formatAmount(widget.draft.discount),
    );
    _purchaseDate = widget.draft.purchaseDate;
    _paymentMethodSuggestion = widget.draft.paymentMethodSuggestion;
    _items = List.of(widget.draft.items);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _discountController.dispose();
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
    discount: _parseNumber(_discountController.text),
    clearDiscount: _discountController.text.trim().isEmpty,
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

  void _continue() {
    final draft = _draft.copyWith(
      items: List.unmodifiable(
        _items.map((item) {
          final repository = widget.productRepository;
          final resolved = repository == null
              ? null
              : ReceiptProductIdentityResolver(
                  repository,
                ).existingForScan(item);
          return item.productId == null && resolved != null
              ? item.copyWith(productId: resolved.id)
              : item;
        }),
      ),
    );
    if (!draft.canContinueToTransaction) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            draft.hasTotalDivergence
                ? 'Revise a divergência entre itens e total antes de continuar.'
                : 'Revise estabelecimento, itens, quantidade, unidade e preços antes de continuar.',
          ),
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

  Future<void> _selectProduct(int index) async {
    final repository = widget.productRepository;
    if (repository == null) return;
    var query = '';
    final selected = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) {
          final matches = repository.search(query).take(60).toList();
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.65,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar produto específico',
                    ),
                    onChanged: (value) => update(() => query = value),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, position) {
                        final product = matches[position];
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            [
                              product.brand,
                              product.defaultUnit,
                            ].where((part) => part.isNotEmpty).join(' · '),
                          ),
                          onTap: () => Navigator.pop(context, product),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (selected == null || !mounted) return;
    _updateItem(
      index,
      _items[index].copyWith(productId: selected.id, brand: selected.brand),
    );
  }

  Widget _buildItem(int index) {
    final item = _items[index];
    return ExpansionTile(
      key: ValueKey('receipt-item-$index-${item.description}'),
      title: Text(
        item.description.isEmpty ? 'Item sem descrição' : item.description,
      ),
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
      children: [
        TextFormField(
          initialValue: item.description,
          decoration: const InputDecoration(labelText: 'Descrição'),
          onChanged: (value) => _updateItem(
            index,
            item.copyWith(description: value, clearProductId: true),
          ),
        ),
        if (item.originalDescription != null &&
            item.originalDescription != item.description)
          Text('Texto lido: ${item.originalDescription}'),
        TextFormField(
          initialValue: item.brand ?? '',
          decoration: const InputDecoration(labelText: 'Marca, se conhecida'),
          onChanged: (value) => _updateItem(
            index,
            item.copyWith(brand: value, clearProductId: true),
          ),
        ),
        TextButton(
          onPressed: widget.productRepository == null
              ? null
              : () => _selectProduct(index),
          child: Text(
            item.productId == null
                ? 'Vincular produto existente'
                : 'Produto: ${widget.productRepository?.findById(item.productId!)?.name ?? item.productId}',
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                initialValue: item.unit ?? '',
                decoration: const InputDecoration(labelText: 'Unidade'),
                onChanged: (value) => _updateItem(
                  index,
                  item.copyWith(unit: value, clearProductId: true),
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
        TextButton.icon(
          onPressed: () => setState(() => _items.removeAt(index)),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Remover item'),
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
            if (widget.draft.subtotal != null)
              Text(
                'Subtotal reconhecido: ${_formatAmount(widget.draft.subtotal)}',
              ),
            TextField(
              controller: _discountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Desconto total'),
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
            TextButton.icon(
              onPressed: () => setState(
                () => _items.add(const ReceiptScanItem(description: '')),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar item'),
            ),
            if (_draft.hasTotalDivergence) ...[
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
