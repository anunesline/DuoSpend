import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../domain/models/household_list.dart';
import '../../domain/models/household_list_item.dart';

typedef HouseholdMemberNameResolver = String? Function(String userId);

String householdPurchaseEventSourceLabel(
  HouseholdListItemPurchaseEvent event,
) =>
    event.source == 'financialTransaction'
        ? 'via transação'
        : 'marcado na lista';

class HouseholdListHistoryPage extends StatefulWidget {
  final HouseholdList list;
  final Future<List<HouseholdListItemPurchaseEvent>> Function() loadEvents;
  final HouseholdMemberNameResolver resolveMemberName;

  const HouseholdListHistoryPage({
    super.key,
    required this.list,
    required this.loadEvents,
    required this.resolveMemberName,
  });

  @override
  State<HouseholdListHistoryPage> createState() =>
      _HouseholdListHistoryPageState();
}

class _HouseholdListHistoryPageState extends State<HouseholdListHistoryPage> {
  late Future<List<HouseholdListItemPurchaseEvent>> _events;

  @override
  void initState() {
    super.initState();
    _events = widget.loadEvents();
  }

  Future<void> _refresh() async {
    final events = widget.loadEvents();
    setState(() => _events = events);
    await events;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DuoColors.orbitBackground,
        appBar: AppBar(
          backgroundColor: DuoColors.orbitBackground,
          foregroundColor: DuoColors.orbitTextPrimary,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Histórico',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        body: FutureBuilder<List<HouseholdListItemPurchaseEvent>>(
          future: _events,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: DuoColors.orbitAccent,
                ),
              );
            }
            if (snapshot.hasError) {
              return _HistoryMessage(
                icon: Icons.cloud_off_rounded,
                title: 'Não foi possível carregar o histórico',
                subtitle: 'Puxe para atualizar e tente novamente.',
                onRefresh: _refresh,
              );
            }
            final events = [...?snapshot.data]
              ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
            if (events.isEmpty) {
              return _HistoryMessage(
                icon: Icons.history_toggle_off_rounded,
                title: 'Nenhuma compra registrada',
                subtitle:
                    'As compras marcadas nesta lista aparecerão aqui.',
                onRefresh: _refresh,
              );
            }
            return RefreshIndicator(
              color: DuoColors.orbitAccent,
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _HistoryIntro(listName: widget.list.name),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: DuoColors.orbitCardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: DuoColors.orbitBorder.withValues(alpha: .5),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (var index = 0;
                            index < events.length;
                            index++) ...[
                          _HistoryTile(
                            event: events[index],
                            memberName: events[index].purchasedBy == null
                                ? null
                                : widget.resolveMemberName(
                                    events[index].purchasedBy!,
                                  ),
                          ),
                          if (index != events.length - 1)
                            Divider(
                              height: 1,
                              indent: 58,
                              color: DuoColors.orbitBorder.withValues(alpha: .4),
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
      );
}

class _HistoryIntro extends StatelessWidget {
  final String listName;

  const _HistoryIntro({required this.listName});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DuoColors.orbitAccent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: DuoColors.orbitAccent,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compras registradas',
                  style: TextStyle(
                    color: DuoColors.orbitTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  listName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DuoColors.orbitTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _HistoryTile extends StatelessWidget {
  final HouseholdListItemPurchaseEvent event;
  final String? memberName;

  const _HistoryTile({required this.event, required this.memberName});

  @override
  Widget build(BuildContext context) {
    final resolvedName = memberName?.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: DuoColors.success.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: DuoColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.displayName,
                  style: const TextStyle(
                    color: DuoColors.orbitTextPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy • HH:mm').format(event.purchasedAt),
                  style: const TextStyle(
                    color: DuoColors.orbitTextSecondary,
                    fontSize: 11.5,
                  ),
                ),
                if (resolvedName != null && resolvedName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Por $resolvedName',
                    style: const TextStyle(
                      color: DuoColors.orbitTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: DuoColors.orbitAccent.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              householdPurchaseEventSourceLabel(event),
              style: const TextStyle(
                color: DuoColors.orbitAccent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onRefresh;

  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: DuoColors.orbitAccent,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 96, 24, 32),
          children: [
            Icon(icon, size: 38, color: DuoColors.orbitAccent),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DuoColors.orbitTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DuoColors.orbitTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}
