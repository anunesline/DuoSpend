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
  bool _showLists = false;
  bool _quickActionsExpanded = true;
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

  @override
  Widget build(BuildContext context) {
    final sharedScopeId = widget.hasSharedHousehold
        ? HouseholdScopeId.shared(widget.sharedMemberIds)
        : null;
    final loadScopeIds = <String>[
      _personalScopeId,
      if (sharedScopeId != null) sharedScopeId,
    ];
    final members = <String>{
      widget.currentUserId,
      if (sharedScopeId != null) ...HouseholdScopeId.members(sharedScopeId),
    }.toList(growable: false);

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
              if (value == 'refresh') widget.controller.loadScopes(loadScopeIds);
              if (value == 'lists') setState(() => _showLists = true);
              if (value == 'tasks') setState(() => _showLists = false);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'tasks', child: Text('Tarefas')),
              PopupMenuItem(value: 'lists', child: Text('Listas')),
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
            child: _ExpandableQuickActions(
              expanded: _quickActionsExpanded,
              onToggle: () => setState(
                () => _quickActionsExpanded = !_quickActionsExpanded,
              ),
              onTask: () => _runTaskAction(() async {
                await _tasksPageKey.currentState?.createTask();
              }),
              onList: () => _createList(_personalScopeId),
              onSequence: () => _runTaskAction(() async {
                await _tasksPageKey.currentState?.createRoutine();
              }),
              onPartnerReminder: () => _showUnavailable(
                'Abra uma tarefa compartilhada para lembrar o responsável.',
              ),
              onShopping: () => setState(() => _showLists = true),
            ),
          ),
          Expanded(
            child: _showLists
                ? HouseholdListsPage(
                    key: const ValueKey('lists-unified'),
                    controller: widget.controller,
                    scopeId: _personalScopeId,
                    currentUserId: widget.currentUserId,
                    showFloatingAction: false,
                  )
                : HouseholdRoutinesPage(
                    key: _tasksPageKey,
                    controller: widget.controller,
                    scopeId: _personalScopeId,
                    scope: HouseholdTaskScope.personal,
                    memberIds: members,
                    currentUserId: widget.currentUserId,
                    loadScopeIds: loadScopeIds,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'household-task-create',
        onPressed: () => _runTaskAction(() async {
          await _tasksPageKey.currentState?.createTask();
        }),
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

class _ExpandableQuickActions extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onTask;
  final VoidCallback onList;
  final VoidCallback onSequence;
  final VoidCallback onPartnerReminder;
  final VoidCallback onShopping;

  const _ExpandableQuickActions({
    required this.expanded,
    required this.onToggle,
    required this.onTask,
    required this.onList,
    required this.onSequence,
    required this.onPartnerReminder,
    required this.onShopping,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: DuoColors.orbitCardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DuoColors.orbitBorder.withValues(alpha: .46),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      color: DuoColors.orbitAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Criar e organizar',
                        style: TextStyle(
                          color: DuoColors.orbitTextPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: DuoColors.orbitTextSecondary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Nova tarefa',
                            color: DuoColors.orbitAccent,
                            onTap: onTask,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.list_alt_rounded,
                            label: 'Nova lista',
                            color: DuoColors.success,
                            onTap: onList,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.link_rounded,
                            label: 'Nova sequência',
                            color: DuoColors.warning,
                            onTap: onSequence,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Spacer(),
                        Expanded(
                          flex: 3,
                          child: _QuickAction(
                            icon: Icons.notifications_none_rounded,
                            label: 'Lembrar parceiro',
                            color: DuoColors.orbitAccent,
                            onTap: onPartnerReminder,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: _QuickAction(
                            icon: Icons.shopping_cart_outlined,
                            label: 'Compras',
                            color: const Color(0xFF4E8BFF),
                            onTap: onShopping,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
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
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: .28)),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DuoColors.orbitTextSecondary,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
