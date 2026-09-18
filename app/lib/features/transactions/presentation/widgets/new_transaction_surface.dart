import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/knowledge/products/product_repository.dart';
import '../../data/models/product_model.dart';
import '../../domain/purchase/models/purchase_item_model.dart';
import '../controllers/purchase_controller.dart';

const transactionAccent = Color(0xFFCD8FFF);
const transactionMuted = Color(0xFFC2C2CA);

String formatTransactionQuantity(double value) =>
    NumberFormat('0.###', 'pt_BR').format(value);

/// Presentation components private to the Nova Transação flow.
class TransactionPanel extends StatelessWidget {
  final Widget child;
  final bool outlined;
  const TransactionPanel({
    super.key,
    required this.child,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D141D), Color(0xFF090F17)],
      ),
      borderRadius: BorderRadius.circular(outlined ? 10 : 14),
      border: Border.all(
        color: outlined ? const Color(0xFF38254E) : const Color(0xFF1B202A),
      ),
    ),
    child: child,
  );
}

class TransactionCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const TransactionCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xFF101020),
      foregroundColor: transactionAccent,
      side: const BorderSide(color: Color(0xFF252038)),
    ),
    icon: Icon(icon, size: 22),
  );
}

class TransactionField extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String value;
  final String? detail;
  final Color? detailColor;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool filledIcon;
  final bool showChevron;
  const TransactionField({
    super.key,
    required this.icon,
    this.label,
    required this.value,
    this.detail,
    this.detailColor,
    this.trailing,
    required this.onTap,
    this.filledIcon = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: filledIcon
                  ? const [Color(0xFF8040B9), Color(0xFF51217D)]
                  : const [Color(0xFF151427), Color(0xFF0B101B)],
            ),
            border: Border.all(
              color: filledIcon
                  ? const Color(0xFF9151C5)
                  : const Color(0xFF1B1B30),
            ),
          ),
          child: Icon(
            icon,
            size: 23,
            color: filledIcon ? Colors.white : transactionAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null) ...[
                Text(
                  label!,
                  style: const TextStyle(color: transactionMuted, fontSize: 11),
                ),
                const SizedBox(height: 3),
              ],
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
              if (detail != null) ...[
                const SizedBox(height: 3),
                Text(
                  detail!,
                  style: TextStyle(
                    fontSize: 12,
                    color: detailColor ?? transactionMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Flexible(child: trailing!),
        ],
        if (showChevron) ...[
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: transactionMuted, size: 21),
        ],
      ],
    ),
  );
}

class TransactionTypeTabs extends StatelessWidget {
  final String type;
  final ValueChanged<String> onChanged;
  const TransactionTypeTabs({
    super.key,
    required this.type,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF0A1018),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF1B202A)),
    ),
    child: Row(
      children: [
        for (final entry in [
          ('expense', 'Despesa', Icons.south),
          ('income', 'Receita', Icons.north),
        ])
          Expanded(
            child: Semantics(
              selected: type == entry.$1,
              button: true,
              child: InkWell(
                onTap: () => onChanged(entry.$1),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: type == entry.$1
                        ? const LinearGradient(
                            colors: [Color(0xFF583283), Color(0xFF45266F)],
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        entry.$3,
                        size: 21,
                        color: entry.$1 == 'income'
                            ? const Color(0xFF4FD66C)
                            : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.$2,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      if (entry.$1 == 'expense') ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class TransactionQuantityControl extends StatelessWidget {
  final double quantity;
  final ValueChanged<double>? onChanged;
  const TransactionQuantityControl({
    super.key,
    required this.quantity,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _button(
        Icons.remove,
        'Diminuir quantidade',
        quantity > 0 && onChanged != null
            ? () => onChanged!(
                (quantity - 1).clamp(0, double.infinity).toDouble(),
              )
            : null,
      ),
      SizedBox(
        width: 30,
        child: Text(
          formatTransactionQuantity(quantity),
          textAlign: TextAlign.center,
          style: const TextStyle(color: transactionAccent, fontSize: 12),
        ),
      ),
      _button(
        Icons.add,
        'Aumentar quantidade',
        onChanged == null ? null : () => onChanged!(quantity + 1),
      ),
    ],
  );

  Widget _button(IconData icon, String tooltip, VoidCallback? callback) =>
      SizedBox(
        width: 36,
        height: 40,
        child: IconButton(
          onPressed: callback,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          iconSize: 20,
          style: IconButton.styleFrom(
            foregroundColor: transactionAccent,
            side: const BorderSide(color: Color(0xFF39274E)),
          ),
          icon: Icon(icon),
        ),
      );
}

class NewTransactionItemsSheet extends StatefulWidget {
  final PurchaseController controller;
  final ProductRepository productRepository;
  final Future<void> Function(ProductModel?) onAdd;
  final Future<void> Function(String name, double unitPrice) onCreateInline;
  final Future<void> Function(PurchaseItemModel) onEdit;
  final ValueChanged<PurchaseItemModel> onRemove;
  final ValueChanged<PurchaseItemModel> onRestore;
  final void Function(PurchaseItemModel, double) onQuantityChanged;
  final void Function(PurchaseItemModel, double) onUnitPriceChanged;
  final VoidCallback onScan;
  const NewTransactionItemsSheet({
    super.key,
    required this.controller,
    required this.productRepository,
    required this.onAdd,
    required this.onCreateInline,
    required this.onEdit,
    required this.onRemove,
    required this.onRestore,
    required this.onQuantityChanged,
    required this.onUnitPriceChanged,
    required this.onScan,
  });

  @override
  State<NewTransactionItemsSheet> createState() =>
      _NewTransactionItemsSheetState();
}

class _NewTransactionItemsSheetState extends State<NewTransactionItemsSheet> {
  final _search = TextEditingController();
  final _inlinePrice = TextEditingController();
  // Only deselected rows are retained for re-selection during this sheet session.
  // Selected items and totals always come directly from the existing controller.
  final Map<String, String> _draftPrices = {};
  bool _openingEditor = false;
  String _money(double amount) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$').format(amount);

  PurchaseItemModel _catalogItem(
    ProductModel product, {
    double quantity = 1,
    double? unitPrice,
  }) {
    final price =
        unitPrice ??
        double.tryParse(
          (_draftPrices[product.id] ?? '').replaceAll(',', '.'),
        ) ??
        (product.lastPrice > 0 ? product.lastPrice : product.averagePrice);
    return PurchaseItemModel(
      id: '${product.id}-${DateTime.now().microsecondsSinceEpoch}',
      purchaseId: '',
      productId: product.id,
      name: product.name,
      brand: product.brand,
      quantity: quantity,
      unit: product.defaultUnit,
      unitPrice: price,
      totalPrice: price * quantity,
      taxonomyId: product.taxonomyId,
      financialCategory: product.productCategoryName,
      financialSubcategory: '',
      productCategoryId: product.productCategoryId,
      productCategoryName: product.productCategoryName,
      createdAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    _inlinePrice.dispose();
    super.dispose();
  }

  Future<void> _edit(Future<void> Function() action) async {
    if (_openingEditor || widget.controller.isSaving) return;
    setState(() => _openingEditor = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _openingEditor = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final selected = {
        for (final item in widget.controller.items) item.id: item,
      };
      final query = widget.productRepository.normalize(_search.text);
      final products = widget.productRepository.search(_search.text).toList();
      final enabled = !_openingEditor && !widget.controller.isSaving;
      final selectedByProduct = <String, PurchaseItemModel>{
        for (final item in selected.values)
          if (item.productId != null) item.productId!: item,
      };
      final representedProductIds = <String>{};
      final productRows = <Widget>[];
      for (final product in products) {
        final item = selectedByProduct[product.id];
        if (item != null) representedProductIds.add(product.id);
        productRows.add(_productRow(product, item, enabled));
      }
      productRows.addAll(
        selected.values
            .where(
              (item) =>
                  !representedProductIds.contains(item.productId) &&
                  widget.productRepository
                      .normalize('${item.name} ${item.brand}')
                      .contains(query),
            )
            .map((item) => _itemRow(item, true, enabled)),
      );
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            12 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF656976),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Adicionar itens',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar itens',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: transactionMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar item',
                          hintStyle: const TextStyle(color: transactionMuted),
                          isDense: true,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: transactionMuted,
                            size: 18,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF29313C),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Scanner fiscal',
                      onPressed: enabled ? widget.onScan : null,
                      icon: const Icon(
                        Icons.document_scanner_outlined,
                        color: transactionAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (productRows.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: query.isEmpty
                              ? const Text(
                                  'Nenhum item adicionado. Adicione o primeiro item da compra.',
                                  style: TextStyle(color: transactionMuted),
                                  textAlign: TextAlign.center,
                                )
                              : TransactionPanel(
                                  outlined: true,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Novo item',
                                        style: TextStyle(
                                          color: transactionAccent,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Cadastrar “${_search.text.trim()}” na compra',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: _inlinePrice,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: const InputDecoration(
                                          labelText: 'Preço unitário',
                                          prefixText: r'R$ ',
                                          isDense: true,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          onPressed: enabled
                                              ? () async {
                                                  final price = double.tryParse(
                                                    _inlinePrice.text
                                                        .trim()
                                                        .replaceAll(',', '.'),
                                                  );
                                                  if (price == null ||
                                                      price <= 0)
                                                    return;
                                                  await _edit(
                                                    () => widget.onCreateInline(
                                                      _search.text.trim(),
                                                      price,
                                                    ),
                                                  );
                                                  if (mounted)
                                                    _inlinePrice.clear();
                                                }
                                              : null,
                                          icon: const Icon(Icons.add),
                                          label: const Text(
                                            'Cadastrar e adicionar',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Você poderá completar depois a marca e outros dados do catálogo.',
                                        style: TextStyle(
                                          color: transactionMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ...productRows,
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: enabled
                        ? () => _edit(() => widget.onAdd(null))
                        : null,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar novo item'),
                    style: TextButton.styleFrom(
                      foregroundColor: transactionAccent,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF231B34),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF342249)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${selected.length} ${selected.length == 1 ? 'item selecionado' : 'itens selecionados'}',
                          style: const TextStyle(
                            color: transactionAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Total: ${_money(widget.controller.total)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: transactionAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _productRow(
    ProductModel product,
    PurchaseItemModel? item,
    bool enabled,
  ) => _itemLine(
    productId: product.id,
    name: product.name,
    brand: product.brand,
    quantity: item?.quantity ?? 0,
    initialPrice: item == null
        ? (_draftPrices[product.id] ??
              (product.lastPrice > 0
                  ? product.lastPrice.toStringAsFixed(2)
                  : product.averagePrice.toStringAsFixed(2)))
        : item.unitPrice.toStringAsFixed(2),
    item: item,
    product: product,
    enabled: enabled,
  );

  Widget _itemRow(PurchaseItemModel item, bool selected, bool enabled) =>
      _itemLine(
        productId: item.productId ?? item.id,
        name: item.name,
        brand: item.brand,
        quantity: item.quantity,
        initialPrice: item.unitPrice.toStringAsFixed(2),
        item: item,
        enabled: enabled,
      );

  Widget _itemLine({
    required String productId,
    required String name,
    required String brand,
    required double quantity,
    required String initialPrice,
    required PurchaseItemModel? item,
    ProductModel? product,
    required bool enabled,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: item != null && enabled
                ? () => _edit(() => widget.onEdit(item))
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                  if (brand.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      brand,
                      style: const TextStyle(
                        fontSize: 11,
                        color: transactionMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: TextFormField(
            key: ValueKey('item-price-$productId'),
            initialValue: initialPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: enabled
                ? (value) {
                    final price = double.tryParse(value.replaceAll(',', '.'));
                    if (price == null || price < 0) return;
                    _draftPrices[productId] = value;
                    if (item != null) {
                      widget.onUnitPriceChanged(item, price);
                    }
                    setState(() {});
                  }
                : null,
            decoration: InputDecoration(
              prefixText: r'R$ ',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 9,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF39274E),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: transactionAccent,
                ),
              ),
            ),
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
        const SizedBox(width: 6),
        TransactionQuantityControl(
          quantity: quantity,
          onChanged: enabled
              ? (quantity) {
                  if (item == null) {
                    if (product != null && quantity > 0) {
                      widget.onRestore(
                        _catalogItem(product, quantity: quantity),
                      );
                    }
                  } else if (quantity <= 0) {
                    widget.onRemove(item);
                  } else {
                    widget.onQuantityChanged(item, quantity);
                  }
                }
              : null,
        ),
      ],
    ),
  );
}
