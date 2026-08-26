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

    final titles = <String>[];
    for (final reminder in reminders) {
      final task = await widget.controller.taskRepository.getTaskById(reminder.taskId);
      final title = task?.title.trim();
      if (title != null && title.isNotEmpty && !titles.contains(title)) {
        titles.add(title);
      }
    }
    if (!mounted) return;

    final message = titles.isEmpty
        ? (reminders.length == 1
            ? 'Você tem 1 lembrete de tarefa.'
            : 'Você tem ${reminders.length} lembretes de tarefas.')
        : titles.length == 1
            ? 'Lembrete: ${titles.first}'
            : 'Lembretes: ${titles.take(3).join(', ')}${titles.length > 3 ? '…' : ''}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
