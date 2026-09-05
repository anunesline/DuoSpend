import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_colors.dart';
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

  String get _personalScopeId => HouseholdScopeId.personal(widget.currentUserId);

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
        toolbarHeight: 58,
        backgroundColor: DuoColors.orbitBackground,
        foregroundColor: DuoColors.orbitTextPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Rotinas',
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
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
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
                  )
                : HouseholdRoutinesPage(
                    key: ValueKey(scopeId),
                    controller: widget.controller,
                    scopeId: scopeId,
                    scope: scope,
                    memberIds: members,
                    currentUserId: widget.currentUserId,
                    embedInScaffold: true,
                  ),
            ),
          ),
        ],
      ),
    );
  }
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
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DuoColors.orbitCardSurface,
        borderRadius: BorderRadius.circular(14),
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
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? DuoColors.orbitAccent.withValues(alpha: .18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
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
