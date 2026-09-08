import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../domain/models/household_list.dart';
import '../../domain/models/household_list_item.dart';
import '../controllers/household_routines_controller.dart';
import 'household_list_history_page.dart';

class HouseholdListDetailPage extends StatefulWidget {
  final HouseholdRoutinesController controller;
  final HouseholdList list;
  final String currentUserId;

  const HouseholdListDetailPage({
    super.key,
    required this.controller,
    required this.list,
    required this.currentUserId,
  });

  @override
  State<HouseholdListDetailPage> createState() => _HouseholdListDetailPageState();
}

class _HouseholdListDetailPageState extends State<HouseholdListDetailPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadListItems(widget.list.id);
  }

  Future<void> _editItem([HouseholdListItem? item]) async {
    final name = TextEditingController(text: item?.displayName ?? '');
    final quantity = TextEditingController(
      text: item?.quantity?.toString() ?? '',
    );
    final unit = TextEditingController(text: item?.unit ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DuoColors.orbitCardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: DuoColors.orbitBorder.withValues(alpha: .6)),
        ),
        title: Text(item == null ? 'Adicionar item' : 'Editar item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: item == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: widget.list.isShopping ? 'Produto' : 'Item',
                  hintText: widget.list.isShopping ? 'Ex.: Leite integral' : null,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantity,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Quantidade',
                        hintText: 'Opcional',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: unit,
                      decoration: const InputDecoration(
                        labelText: 'Unidade',
                        hintText: 'Ex.: un',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(item == null ? 'Adicionar' : 'Salvar'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final parsedQuantity = num.tryParse(quantity.text.replaceAll(',', '.'));
      if (item == null) {
        await widget.controller.createListItem(
          list: widget.list,
          displayName: name.text,
          quantity: parsedQuantity,
          unit: unit.text,
        );
      } else {
        await widget.controller.updateListItem(
          item: item,
          displayName: name.text,
          quantity: parsedQuantity,
          unit: unit.text,
        );
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    name.dispose();
    quantity.dispose();
    unit.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.orbitBackground,
      appBar: AppBar(
        backgroundColor: DuoColors.orbitBackground,
        foregroundColor: DuoColors.orbitTextPrimary,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.list.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          if (widget.list.isShopping)
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HouseholdListHistoryPage(
                    list: widget.list,
                    loadEvents: () =>
                        widget.controller.loadListPurchaseHistory(widget.list),
                    resolveMemberName: widget.controller.resolvedMemberName,
                  ),
                ),
              ),
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('Histórico'),
              style: TextButton.styleFrom(
                foregroundColor: DuoColors.orbitAccent,
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final items = widget.controller.itemsForList(widget.list.id);
          final purchased = items.where((item) => item.isPurchased).length;
          return RefreshIndicator(
            color: DuoColors.orbitAccent,
            onRefresh: () => widget.controller.loadListItems(widget.list.id),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
              children: [
                _ListProgress(
                  list: widget.list,
                  total: items.length,
                  purchased: purchased,
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const _ItemsEmpty()
                else
                  Container(
                    decoration: BoxDecoration(
                      color: DuoColors.orbitCardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: DuoColors.orbitBorder.withValues(alpha: .52),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (var index = 0; index < items.length; index++) ...[
                          _ListItemTile(
                            item: items[index],
                            onChanged: (value) =>
                                widget.controller.setListItemPurchased(
                              item: items[index],
                              purchased: value ?? false,
                              completedBy: widget.currentUserId,
                            ),
                            onEdit: () => _editItem(items[index]),
                            onDelete: () =>
                                widget.controller.deleteListItem(items[index]),
                          ),
                          if (index != items.length - 1)
                            Divider(
                              height: 1,
                              indent: 62,
                              color: DuoColors.orbitBorder.withValues(alpha: .5),
                            ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _editItem,
        backgroundColor: DuoColors.orbitAccent,
        foregroundColor: DuoColors.orbitBackground,
        icon: const Icon(Icons.add_rounded),
        label: Text(widget.list.isShopping ? 'Adicionar item' : 'Adicionar'),
      ),
    );
  }
}

class _ListProgress extends StatelessWidget {
  final HouseholdList list;
  final int total;
  final int purchased;
  const _ListProgress({required this.list, required this.total, required this.purchased});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : purchased / total;
    final color = list.isShopping ? const Color(0xFF4E8BFF) : DuoColors.orbitAccent;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DuoColors.orbitCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DuoColors.orbitBorder.withValues(alpha: .52)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              list.isShopping ? Icons.shopping_basket_outlined : Icons.list_alt_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0 ? 'Adicione o primeiro item' : '$purchased de $total itens',
                  style: const TextStyle(
                    color: DuoColors.orbitTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: DuoColors.orbitBackground,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListItemTile extends StatelessWidget {
  final HouseholdListItem item;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ListItemTile({
    required this.item,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final quantity = item.quantity == null
        ? null
        : '${item.quantity}${item.unit == null || item.unit!.isEmpty ? '' : ' ${item.unit}'}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 7, 5, 7),
      child: Row(
        children: [
          Checkbox(
            value: item.isPurchased,
            activeColor: DuoColors.success,
            shape: const CircleBorder(),
            visualDensity: VisualDensity.standard,
            onChanged: onChanged,
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              item.displayName,
              style: TextStyle(
                color: item.isPurchased
                    ? DuoColors.orbitTextSecondary
                    : DuoColors.orbitTextPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                decoration: item.isPurchased ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (quantity != null)
            Text(quantity,
                style: const TextStyle(
                    color: DuoColors.orbitTextSecondary, fontSize: 11)),
          PopupMenuButton<String>(
            color: DuoColors.orbitSurface,
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar item')),
              PopupMenuItem(value: 'delete', child: Text('Remover item')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemsEmpty extends StatelessWidget {
  const _ItemsEmpty();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: DuoColors.orbitCardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DuoColors.orbitBorder.withValues(alpha: .48)),
        ),
        child: const Column(
          children: [
            Icon(Icons.add_shopping_cart_rounded,
                size: 30, color: DuoColors.orbitAccent),
            SizedBox(height: 8),
            Text('Sua lista está vazia',
                style: TextStyle(
                    color: DuoColors.orbitTextPrimary,
                    fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text('Adicione os itens que você precisa lembrar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: DuoColors.orbitTextSecondary, fontSize: 11)),
          ],
        ),
      );
}
