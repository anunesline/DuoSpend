import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../domain/models/household_list.dart';
import '../controllers/household_routines_controller.dart';
import 'household_list_detail_page.dart';

class HouseholdListsPage extends StatelessWidget {
  final HouseholdRoutinesController controller;
  final String scopeId;
  final String currentUserId;

  const HouseholdListsPage({
    super.key,
    required this.controller,
    required this.scopeId,
    required this.currentUserId,
  });

  Future<void> _editList(BuildContext context, [HouseholdList? list]) async {
    final name = TextEditingController(text: list?.name ?? '');
    var type = list?.type ?? HouseholdListType.shopping;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: DuoColors.orbitCardSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: DuoColors.orbitBorder.withValues(alpha: .6)),
          ),
          title: Text(list == null ? 'Nova lista' : 'Editar lista'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: list == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nome da lista',
                  hintText: 'Ex.: Compras da semana',
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<HouseholdListType>(
                segments: const [
                  ButtonSegment(
                    value: HouseholdListType.shopping,
                    icon: Icon(Icons.shopping_cart_outlined),
                    label: Text('Compras'),
                  ),
                  ButtonSegment(
                    value: HouseholdListType.general,
                    icon: Icon(Icons.list_alt_rounded),
                    label: Text('Geral'),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (selection) =>
                    setState(() => type = selection.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(list == null ? 'Criar' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      if (list == null) {
        await controller.createList(scopeId: scopeId, name: name.text, type: type);
      } else {
        await controller.updateList(list: list, name: name.text, type: type);
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    name.dispose();
  }

  Future<void> _archive(BuildContext context, HouseholdList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Arquivar lista?'),
        content: const Text(
          'Os itens e o histórico de compras serão preservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.archiveList(list);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final lists = controller.lists;
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
              children: [
                const _ListsIntro(),
                const SizedBox(height: 14),
                if (lists.isEmpty)
                  _EmptyLists(onCreate: () => _editList(context))
                else
                  ...lists.map(
                    (list) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _ListCard(
                        list: list,
                        controller: controller,
                        onOpen: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HouseholdListDetailPage(
                              controller: controller,
                              list: list,
                              currentUserId: currentUserId,
                            ),
                          ),
                        ),
                        onEdit: () => _editList(context, list),
                        onArchive: () => _archive(context, list),
                      ),
                    ),
                  ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                onPressed: () => _editList(context),
                backgroundColor: DuoColors.orbitAccent,
                foregroundColor: DuoColors.orbitBackground,
                tooltip: 'Nova lista',
                child: const Icon(Icons.add_rounded, size: 27),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ListsIntro extends StatelessWidget {
  const _ListsIntro();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: DuoColors.orbitCardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DuoColors.orbitBorder.withValues(alpha: .52)),
        ),
        child: const Row(
          children: [
            _ListIcon(icon: Icons.list_alt_rounded, color: DuoColors.orbitAccent),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suas listas',
                    style: TextStyle(
                      color: DuoColors.orbitTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Organize tarefas e compras do seu jeito.',
                    style: TextStyle(
                      color: DuoColors.orbitTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
}

class _ListCard extends StatelessWidget {
  final HouseholdList list;
  final HouseholdRoutinesController controller;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _ListCard({
    required this.list,
    required this.controller,
    required this.onOpen,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final items = controller.itemsForList(list.id);
    final purchased = items.where((item) => item.isPurchased).length;
    final color = list.isShopping ? const Color(0xFF4E8BFF) : DuoColors.orbitAccent;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 12, 7, 12),
        decoration: BoxDecoration(
          color: DuoColors.orbitCardSurface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: DuoColors.orbitBorder.withValues(alpha: .52)),
        ),
        child: Row(
          children: [
            _ListIcon(
              icon: list.isShopping
                  ? Icons.shopping_cart_outlined
                  : Icons.list_alt_rounded,
              color: color,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DuoColors.orbitTextPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items.isEmpty
                        ? (list.isShopping ? 'Lista de compras' : 'Lista geral')
                        : '$purchased de ${items.length} itens concluídos',
                    style: const TextStyle(
                      color: DuoColors.orbitTextSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: DuoColors.orbitSurface,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'archive') onArchive();
                if (value == 'delete') controller.deleteEmptyList(list);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar lista')),
                const PopupMenuItem(
                  value: 'archive',
                  child: Text('Arquivar lista'),
                ),
                if (items.isEmpty)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Excluir lista vazia'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _ListIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: color, size: 22),
      );
}

class _EmptyLists extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyLists({required this.onCreate});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: DuoColors.orbitCardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DuoColors.orbitBorder.withValues(alpha: .48)),
        ),
        child: Column(
          children: [
            const Icon(Icons.shopping_basket_outlined,
                size: 31, color: DuoColors.orbitAccent),
            const SizedBox(height: 10),
            const Text('Nenhuma lista por aqui ainda',
                style: TextStyle(
                    color: DuoColors.orbitTextPrimary,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Crie uma lista para organizar sua próxima compra.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: DuoColors.orbitTextSecondary, fontSize: 11)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar lista'),
            ),
          ],
        ),
      );
}
