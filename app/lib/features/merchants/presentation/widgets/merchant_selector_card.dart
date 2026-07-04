import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/merchant_model.dart';
import '../../domain/merchant_types.dart';
import '../controllers/merchant_selector_controller.dart';

class MerchantSelectorCard extends StatefulWidget {
  const MerchantSelectorCard({
    super.key,
    this.initialValue = '',
    this.label = 'Onde você comprou?',
    this.hintText = 'Comece digitando o nome da loja...',
    this.onMerchantSelected,
    this.onCleared,
  });

  final String initialValue;
  final String label;
  final String hintText;
  final ValueChanged<MerchantModel>? onMerchantSelected;
  final VoidCallback? onCleared;

  @override
  State<MerchantSelectorCard> createState() => _MerchantSelectorCardState();
}

class _MerchantSelectorCardState extends State<MerchantSelectorCard> {
  late final TextEditingController _textController;
  late final MerchantSelectorController _controller;

  @override
  void initState() {
    super.initState();

    _controller = MerchantSelectorController();

    _textController = TextEditingController(
      text: widget.initialValue,
    );

    if (widget.initialValue.isNotEmpty) {
      _controller.search(widget.initialValue);
      _emitManualMerchant(widget.initialValue);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onChanged(String value) async {
    await _controller.search(value);

    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      widget.onCleared?.call();
      setState(() {});
      return;
    }

    _emitManualMerchant(trimmedValue);

    setState(() {});
  }

  void _selectMerchant(MerchantModel merchant) {
    _controller.selectMerchant(merchant);
    _textController.text = merchant.name;

    widget.onMerchantSelected?.call(merchant);

    setState(() {});
  }

  void _clear() {
    _textController.clear();
    _controller.clearSelection();

    widget.onCleared?.call();

    setState(() {});
  }

  void _emitManualMerchant(String name) {
    final normalizedName = _normalize(name);

    final manualMerchant = MerchantModel(
      id: 'manual_$normalizedName',
      name: name.trim(),
      type: MerchantTypes.other,
      defaultFinancialCategory: 'Compras',
      defaultFinancialSubcategory: 'Outros',
      aliases: [name.trim()],
      icon: 'storefront',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onMerchantSelected?.call(manualMerchant);
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _textController,
                  onChanged: (value) {
                    _onChanged(value);
                  },
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    prefixIcon: const Icon(Icons.storefront),
                    border: const OutlineInputBorder(),
                    suffixIcon: _textController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _clear,
                          ),
                  ),
                ),
                if (_controller.isLoading) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const LinearProgressIndicator(),
                ],
                if (_controller.hasSuggestions) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  ..._controller.suggestions.map(
                    (merchant) => ListTile(
                      dense: true,
                      leading: const CircleAvatar(
                        child: Icon(Icons.storefront),
                      ),
                      title: Text(merchant.name),
                      subtitle: Text(
                        merchant.defaultFinancialCategory,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _selectMerchant(merchant),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}