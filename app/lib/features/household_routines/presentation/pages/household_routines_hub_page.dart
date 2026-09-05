import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../domain/models/household_list.dart';
import '../../domain/models/household_task.dart';
import '../../domain/services/household_scope_id.dart';
import '../controllers/household_routines_controller.dart';
import 'household_lists_page.dart';
import 'household_routines_page.dart';

class HouseholdRoutinesHubPage extends StatefulWidget {
  final HouseholdRoutinesController controller;
  final String currentUserId;

  /// Kept temporarily for call-site compatibility. Household identity is no
  /// longer derived from a financial wallet id.
  final String? sharedHouseholdId;
  final List<String> sharedMemberIds;

  const HouseholdRoutinesHubPage({
    super.key,
    required this.controller,
    required this.currentUserId,
    this.sharedHouseholdId,
    this.sharedMemberIds = const [],
  });

  bool get hasSharedHousehold {
    final members = sharedMemberIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    return members.length >= 2 && members.contains(currentUserId.trim());
  }

  @override
  State<HouseholdRoutinesHubPage> createState() =>
      _HouseholdRoutinesHubPageState();
}

class _HouseholdRoutinesHubPageState extends State<HouseholdRoutinesHubPage> {
  bool _showShared = false;
  bool _showLists = false;
  final GlobalKey<HouseholdRoutinesPageState> _tasksPageKey = GlobalKey();

  String get _personalScopeId => HouseholdScopeId.personal(widget.currentUserId);

  void _showUnavailable(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _createList(
    String scopeId, {
    HouseholdListType? initialType,
  }) async {
    final name = TextEditingController();
    var type = initialType ?? HouseholdListType.general;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: DuoColors.orbitCardSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: DuoColors.orbitBorder.withValues(alpha: .55),
            ),
          ),
          title: Text(
            type == HouseholdListType.shopping
                ? 'Nova lista de compras'
                : 'Nova lista',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nome da lista'),
              ),
              const SizedBox(height: 14),
              SegmentedButton<HouseholdListType>(
                segments: const [
                  ButtonSegment(
                    value: HouseholdListType.general,
                    icon: Icon(Icons.list_alt_rounded),
                    label: Text('Geral'),
                  ),
                  ButtonSegment(
                    value: HouseholdListType.shopping,
                    icon: Icon(Icons.shopping_cart_outlined),
                    label: Text('Compras'),
                  ),
                ],
                selected: {type},
                onSelectionChanged: initialType == null
                    ? (selection) =>
                        setDialogState(() => type = selection.first)
                    : null,
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
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      final created = await widget.controller.createList(
        scopeId: scopeId,
        name: name.text,
        type: type,
      );
      if (created != null && mounted) setState(() => _showLists = true);
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    name.dispose();
  }

  Future<void> _runTaskAction(Future<void> Function() action) async {
    if (_showLists) {
      setState(() => _showLists = false);
      await WidgetsBinding.instance.endOfFrame;
    }
    await action();
  }

  Future<void> _openQuickActions(String scopeId) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _QuickActionsSheet(
        onTask: () {
          Navigator.pop(sheetContext);
          _runTaskAction(() async {
            await _tasksPageKey.currentState?.createTask();
          });
        },
        onList: () {
          Navigator.pop(sheetContext);
          _createList(scopeId);
        },
        onSequence: () {
          Navigator.pop(sheetContext);
          _runTaskAction(() async {
            await _tasksPageKey.currentState?.createRoutine();
          });
        },
        onPartnerReminder: () {
          Navigator.pop(sheetContext);
          _showUnavailable(
            'Abra uma tarefa compartilhada para lembrar o responsável.',
          );
        },
        onShopping: () {
          Navigator.pop(sheetContext);
          _createList(scopeId, initialType: HouseholdListType.shopping);
        },
        onOther: () {
          Navigator.pop(sheetContext);
          _showUnavailable('Use Nova tarefa para registrar esta atividade.');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isShared = _showShared && widget.hasSharedHousehold;
    final scopeId = isShared
        ? HouseholdScopeId.shared(widget.sharedMemberIds)
        : _personalScopeId;
    final scope = isShared
        ? HouseholdTaskScope.shared
        : HouseholdTaskScope.personal;
    final members = isShared
        ? HouseholdScopeId.members(scopeId)
        : <String>[widget.currentUserId];

    return Scaffold(
      backgroundColor: DuoColors.orbitBackground,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: DuoColors.orbitBackground,
        foregroundColor: DuoColors.orbitTextPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Tarefas',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -.45,
          ),
        ),
        actions: [
          IconButton(
            onPressed: null,
            tooltip: 'Busca disponível em uma próxima etapa',
            icon: const Icon(Icons.search_rounded),
          ),
          PopupMenuButton<String>(
            color: DuoColors.orbitSurface,
            tooltip: 'Mais opções',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'refresh') widget.controller.load(scopeId);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'refresh', child: Text('Atualizar')),
            ],
          ),
          const SizedBox(width: 2),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: _RoutineScopeTabs(
              showShared: isShared,
              showLists: _showLists,
              onPersonal: () => setState(() {
                _showShared = false;
                _showLists = false;
              }),
              onShared: widget.hasSharedHousehold
                  ? () => setState(() {
                      _showShared = true;
                      _showLists = false;
                    })
                  : null,
              onLists: () => setState(() => _showLists = true),
            ),
          ),
          Expanded(
            child: _showLists
                ? HouseholdListsPage(
                    key: ValueKey('lists-$scopeId'),
                    controller: widget.controller,
                    scopeId: scopeId,
                    currentUserId: widget.currentUserId,
                    showFloatingAction: false,
                  )
                : HouseholdRoutinesPage(
                    key: _tasksPageKey,
                    controller: widget.controller,
                    scopeId: scopeId,
                    scope: scope,
                    memberIds: members,
                    currentUserId: widget.currentUserId,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'household-quick-actions-$scopeId',
        onPressed: () => _openQuickActions(scopeId),
        backgroundColor: DuoColors.orbitAccent,
        foregroundColor: DuoColors.orbitBackground,
        elevation: 10,
        highlightElevation: 12,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0x66D0B8FF), width: 1.25),
        ),
        tooltip: 'Criar',
        child: const Icon(Icons.add_rounded, size: 29),
      ),
    );
  }
}

class _QuickActionsSheet extends StatelessWidget {
  final VoidCallback onTask;
  final VoidCallback onList;
  final VoidCallback onSequence;
  final VoidCallback onPartnerReminder;
  final VoidCallback onShopping;
  final VoidCallback onOther;

  const _QuickActionsSheet({
    required this.onTask,
    required this.onList,
    required this.onSequence,
    required this.onPartnerReminder,
    required this.onShopping,
    required this.onOther,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: BoxDecoration(
            color: DuoColors.orbitSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: DuoColors.orbitBorder.withValues(alpha: .58),
            ),
            boxShadow: DuoColors.orbitCardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Nova rotina',
                      style: TextStyle(
                        color: DuoColors.orbitTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: DuoColors.orbitTextSecondary,
                      size: 19,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.1,
                mainAxisSpacing: 14,
                crossAxisSpacing: 12,
                children: [
                  _QuickAction(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Nova tarefa',
                    color: DuoColors.orbitAccent,
                    onTap: onTask,
                  ),
                  _QuickAction(
                    icon: Icons.list_alt_rounded,
                    label: 'Nova lista',
                    color: DuoColors.success,
                    onTap: onList,
                  ),
                  _QuickAction(
                    icon: Icons.link_rounded,
                    label: 'Nova sequência',
                    color: DuoColors.warning,
                    onTap: onSequence,
                  ),
                  _QuickAction(
                    icon: Icons.notifications_none_rounded,
                    label: 'Lembrar parceiro',
                    color: DuoColors.orbitAccent,
                    onTap: onPartnerReminder,
                  ),
                  _QuickAction(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Compras',
                    color: const Color(0xFF4E8BFF),
                    onTap: onShopping,
                  ),
                  _QuickAction(
                    icon: Icons.more_horiz_rounded,
                    label: 'Outra',
                    color: DuoColors.orbitTextSecondary,
                    onTap: onOther,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: .28)),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DuoColors.orbitTextSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class _RoutineScopeTabs extends StatelessWidget {
  final bool showShared;
  final bool showLists;
  final VoidCallback onPersonal;
  final VoidCallback? onShared;
  final VoidCallback onLists;

  const _RoutineScopeTabs({
    required this.showShared,
    required this.showLists,
    required this.onPersonal,
    required this.onShared,
    required this.onLists,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: DuoColors.orbitCardSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: DuoColors.orbitBorder.withValues(alpha: .55),
        ),
      ),
      child: Row(
        children: [
          _tab('Minhas', !showShared && !showLists, onPersonal),
          _tab('Compartilhadas', showShared && !showLists, onShared),
          _tab('Listas', showLists, onLists),
        ],
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? DuoColors.orbitAccent.withValues(alpha: .18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(
                    color: DuoColors.orbitAccent.withValues(alpha: .25),
                  )
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onTap == null
                  ? DuoColors.orbitTextSecondary.withValues(alpha: .45)
                  : selected
                  ? DuoColors.orbitTextPrimary
                  : DuoColors.orbitTextSecondary,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
