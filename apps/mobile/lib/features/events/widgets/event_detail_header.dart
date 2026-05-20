import 'package:flutter/material.dart';
import '../../../core/datetime/date_time_utils.dart';
import '../../../core/models/event_status.dart';
import '../../../shared/widgets/ft_avatar_row.dart';
import '../../../shared/widgets/ft_status_chip.dart';

class EventDetailHeader extends StatelessWidget {
  const EventDetailHeader({super.key, required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final status = EventStatus.fromApi(event['status'] as String? ?? '');
    final deadline = event['pollDeadlineAt'] ?? event['attendanceDeadlineAt'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(event['title'] as String? ?? '', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        FtStatusChip(status: status),
        if (deadline != null) ...[
          const SizedBox(height: 8),
          Text(
            '마감 ${DateTimeUtils.formatDisplayFromIso(deadline as String)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (event['place'] != null) ...[
          const SizedBox(height: 4),
          Text('장소: ${event['place']}', style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (event['confirmedStartsAt'] != null) ...[
          const SizedBox(height: 4),
          Text(
            '일시: ${DateTimeUtils.formatDisplayFromIso(event['confirmedStartsAt'] as String, isAllDay: event['isAllDay'] == true)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 16),
        Text('아직 응답하지 않은 멤버', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FtAvatarRow(
          names: _asNames(
            status == EventStatus.pollOpen
                ? event['pendingPollDisplayNames']
                : event['pendingAttendDisplayNames'],
          ),
          onShowAll: () => _showAllNames(context, _asNames(
            status == EventStatus.pollOpen
                ? event['pendingPollDisplayNames']
                : event['pendingAttendDisplayNames'],
          )),
        ),
      ],
    );
  }

  List<String> _asNames(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  void _showAllNames(BuildContext context, List<String> names) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text('미응답 멤버 (${names.length}명)', style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ...names.map((n) => ListTile(title: Text(n))),
          ],
        ),
      ),
    );
  }
}
