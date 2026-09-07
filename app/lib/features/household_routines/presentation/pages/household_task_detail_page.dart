import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../domain/models/household_task.dart';
import '../controllers/household_routines_controller.dart';

class HouseholdTaskDetailPage extends StatelessWidget {
  final HouseholdTask task;
  final HouseholdRoutinesController controller;
  final String currentUserId;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onCancel;
  final Future<void> Function()? onRemind;

  const HouseholdTaskDetailPage({
    super.key,
    required this.task,
    required this.controller,
    required this.currentUserId,
    this.onEdit,
    this.onCancel,
    this.onRemind,
  });

  bool get _isShared => task.scope == HouseholdTaskScope.shared;

  String get _scopeLabel => _isShared ? 'Compartilhada' : 'Pessoal';

  String? get _assigneeName {
    final id = task.assigneeId;
    if (id == null || id.trim().isEmpty) return null;
    return controller.memberName(id, currentUserId: currentUserId);
  }

  String? get _frequencyLabel {
    final days = task.repeatEveryDays;
    if (days == null || days <= 0) return null;
    if (days == 1) return 'Todos os dias';
    if (days == 7 && task.dueAt != null) {
      const weekdays = [
        'segunda-feira',
        'terça-feira',
        'quarta-feira',
        'quinta-feira',
        'sexta-feira',
        'sábado',
        'domingo',
      ];
      return 'Toda ${weekdays[task.dueAt!.weekday - 1]}';
    }
    return 'A cada $days dias';
  }

  String? get _dateLabel => task.dueAt == null ? null : _timeLabel(task.dueAt!);

  @override
  Widget build(BuildContext context) {
    final accent = task.isCompleted
        ? DuoColors.success
        : task.dueAt != null && task.dueAt!.isBefore(DateTime.now())
        ? DuoColors.error
        : DuoColors.orbitAccent;
    final canRemindPartner =
        _isShared &&
        task.isPending &&
        task.assigneeId != null &&
        task.assigneeId != currentUserId &&
        onRemind != null;

    return Scaffold(
      backgroundColor: DuoColors.orbitBackground,
      appBar: AppBar(
        toolbarHeight: 52,
        backgroundColor: DuoColors.orbitBackground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: DuoColors.orbitTextPrimary,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: 'Voltar',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 24),
          ),
        ),
        actions: [
          if (task.isPending && (onEdit != null || onCancel != null))
            PopupMenuButton<String>(
              color: DuoColors.orbitSurface,
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) async {
                if (value == 'edit' && onEdit != null) await onEdit!();
                if (value == 'cancel' && onCancel != null) {
                  await onCancel!();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar tarefa'),
                  ),
                if (onCancel != null)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text('Cancelar tarefa'),
                  ),
              ],
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: DuoColors.success.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: DuoColors.success.withValues(alpha: .26),
                    ),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: DuoColors.success,
                    size: 35,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusPill(
                        label: _scopeLabel,
                        color: _isShared
                            ? DuoColors.success
                            : DuoColors.orbitAccent,
                      ),
                      const SizedBox(height: 9),
                      Text(
                        task.title,
                        style: TextStyle(
                          color: task.isCompleted
                              ? DuoColors.orbitTextSecondary
                              : DuoColors.orbitTextPrimary,
                          fontSize: 22,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (task.notes?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        Text(
                          task.notes!.trim(),
                          style: const TextStyle(
                            color: DuoColors.orbitTextSecondary,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 38),
            _TaskAttributes(
              assigneeName: _assigneeName,
              assigneeAvatar:
                  _isShared && task.assigneeId != null && _assigneeName != null
                  ? _ResolvedMemberAvatar(
                      name: _assigneeName!,
                      photoUrl: controller.memberPhotoUrl(task.assigneeId!),
                    )
                  : null,
              frequencyLabel: _frequencyLabel,
              dateLabel: _dateLabel,
            ),
            const SizedBox(height: 15),
            _FollowUpCard(
              completedAt: task.completedAt,
              canRemindPartner: canRemindPartner,
              onRemind: onRemind,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskAttributes extends StatelessWidget {
  final String? assigneeName;
  final Widget? assigneeAvatar;
  final String? frequencyLabel;
  final String? dateLabel;

  const _TaskAttributes({
    required this.assigneeName,
    required this.assigneeAvatar,
    required this.frequencyLabel,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (assigneeName != null)
        _DetailRow(
          icon: Icons.person_outline_rounded,
          label: 'Responsável',
          value: assigneeName!,
          valuePrefix: assigneeAvatar,
        ),
      if (frequencyLabel != null)
        _DetailRow(
          icon: Icons.repeat_rounded,
          label: 'Frequência',
          value: frequencyLabel!,
        ),
      if (dateLabel != null)
        _DetailRow(
          icon: Icons.schedule_rounded,
          label: 'Horário',
          value: dateLabel!,
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();
    return _DetailsCard(children: rows);
  }
}

class _DetailsCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: DuoColors.orbitCardSurface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: DuoColors.orbitBorder.withValues(alpha: .76)),
    ),
    child: Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1)
            Divider(
              height: 1,
              indent: 43,
              color: DuoColors.orbitBorder.withValues(alpha: .42),
            ),
        ],
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? valuePrefix;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valuePrefix,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    child: Row(
      children: [
        Icon(icon, color: DuoColors.orbitTextSecondary, size: 15),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: DuoColors.orbitTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (valuePrefix != null) ...[
                valuePrefix!,
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DuoColors.orbitTextPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ResolvedMemberAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const _ResolvedMemberAvatar({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final normalizedPhoto = photoUrl?.trim();
    return CircleAvatar(
      radius: 14,
      backgroundColor: DuoColors.orbitAccent.withValues(alpha: .18),
      backgroundImage: normalizedPhoto == null || normalizedPhoto.isEmpty
          ? null
          : NetworkImage(normalizedPhoto),
      child: normalizedPhoto == null || normalizedPhoto.isEmpty
          ? Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: const TextStyle(
                color: DuoColors.orbitAccent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  final DateTime? completedAt;
  final bool canRemindPartner;
  final Future<void> Function()? onRemind;

  const _FollowUpCard({
    required this.completedAt,
    required this.canRemindPartner,
    required this.onRemind,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(11, 14, 11, 11),
    decoration: BoxDecoration(
      color: DuoColors.orbitCardSurface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: DuoColors.orbitBorder.withValues(alpha: .7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acompanhamento',
          style: TextStyle(
            color: DuoColors.orbitAccent,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (completedAt != null)
          Row(
            children: [
              _FollowUpEventCard(
                label: 'Concluída',
                value: _shortEventDate(completedAt!),
                icon: Icons.check_circle_outline_rounded,
                color: DuoColors.success,
              ),
            ],
          )
        else
          const Padding(
            padding: EdgeInsets.fromLTRB(1, 3, 1, 4),
            child: Text(
              'Ainda não há eventos registrados para esta tarefa.',
              style: TextStyle(
                color: DuoColors.orbitTextSecondary,
                fontSize: 10.5,
                height: 1.35,
              ),
            ),
          ),
        if (canRemindPartner) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () async => onRemind!(),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: DuoColors.orbitAccent.withValues(alpha: .19),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: DuoColors.orbitAccent.withValues(alpha: .56),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFFD0B8FF),
                        size: 19,
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Lembrar parceiro',
                        style: TextStyle(
                          color: Color(0xFFD0B8FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _FollowUpEventCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _FollowUpEventCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 114,
    height: 66,
    padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: .18)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: DuoColors.orbitTextPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

String _timeLabel(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _shortEventDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month • $hour:$minute';
}
