import 'package:flutter/material.dart';

import '../../domain/models/household_task.dart';
import '../controllers/household_routines_controller.dart';
import 'household_routines_page.dart';

class HouseholdRoutinesHubPage extends StatefulWidget {
  final HouseholdRoutinesController controller;
  final String currentUserId;
  final String? sharedHouseholdId;
  final List<String> sharedMemberIds;

  const HouseholdRoutinesHubPage({
    super.key,
    required this.controller,
    required this.currentUserId,
    this.sharedHouseholdId,
    this.sharedMemberIds = const [],
  });

  bool get hasSharedHousehold =>
      sharedHouseholdId != null && sharedHouseholdId!.trim().isNotEmpty;

  @override
  State<HouseholdRoutinesHubPage> createState() =>
      _HouseholdRoutinesHubPageState();
}

class _HouseholdRoutinesHubPageState extends State<HouseholdRoutinesHubPage> {
  bool _showShared = false;

  String get _personalScopeId => 'user:${widget.currentUserId}';

  @override
  Widget build(BuildContext context) {
    final isShared = _showShared && widget.hasSharedHousehold;
    final scopeId = isShared
        ? 'household:${widget.sharedHouseholdId}'
        : _personalScopeId;
    final scope = isShared
        ? HouseholdTaskScope.shared
        : HouseholdTaskScope.personal;
    final members = isShared
        ? widget.sharedMemberIds
        : <String>[widget.currentUserId];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotinas da Casa'),
        bottom: widget.hasSharedHousehold
            ? PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.person_rounded),
                        label: Text('Eu'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.groups_rounded),
                        label: Text('Nós'),
                      ),
                    ],
                    selected: {_showShared},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _showShared = selection.first;
                      });
                    },
                  ),
                ),
              )
            : null,
      ),
      body: HouseholdRoutinesPage(
        key: ValueKey(scopeId),
        controller: widget.controller,
        scopeId: scopeId,
        scope: scope,
        memberIds: members,
        currentUserId: widget.currentUserId,
        embedInScaffold: true,
      ),
    );
  }
}
