import 'package:flutter/material.dart';

import '../../domain/models/household_task.dart';
import '../../domain/services/household_scope_id.dart';
import '../controllers/household_routines_controller.dart';
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

  String get _personalScopeId => HouseholdScopeId.personal(widget.currentUserId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _deliverDueReminders());
  }

  Future<void> _deliverDueReminders() async {
    final reminders = await widget.controller.reminderService.consumeDueReminders(
      recipientUserId: widget.currentUserId,
      now: DateTime.now(),
    );
    if (!mounted || reminders.isEmpty) return;

    final partnerCount = reminders.where((reminder) => reminder.kind.name == 'partner').length;
    final selfCount = reminders.length - partnerCount;
    final parts = <String>[];
    if (selfCount > 0) {
      parts.add(selfCount == 1 ? '1 lembrete seu' : '$selfCount lembretes seus');
    }
    if (partnerCount > 0) {
      parts.add(
        partnerCount == 1
            ? '1 lembrete da casa'
            : '$partnerCount lembretes da casa',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Você tem ${parts.join(' e ')}.'),
        behavior: SnackBarBehavior.floating,
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
