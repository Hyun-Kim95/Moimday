import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/datetime/date_time_utils.dart';
import '../../../core/models/event_status.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/network/offline_write_guard.dart';
import '../../../shared/widgets/ft_primary_button.dart';
import '../../../shared/widgets/ft_secondary_button.dart';
import '../events_repository.dart';
import 'attendance_bottom_sheet.dart';
import 'vote_bottom_sheet.dart';

class EventDetailActions extends ConsumerWidget {
  const EventDetailActions({
    super.key,
    required this.event,
    required this.eventId,
    required this.onChanged,
  });

  final Map<String, dynamic> event;
  final String eventId;
  final VoidCallback onChanged;

  bool _isPollClosed() {
    final raw = event['pollDeadlineAt'] as String?;
    if (raw == null) return false;
    try {
      return !DateTimeUtils.parseApi(raw).isAfter(DateTimeUtils.nowLocal());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = EventStatus.fromApi(event['status'] as String? ?? '');
    final isOrganizer = event['isOrganizer'] == true;
    final options = event['options'] as List<dynamic>? ?? [];
    final pollClosed = status == EventStatus.pollOpen && _isPollClosed();

    if (status == EventStatus.finalized) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('확정된 모임이에요', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/calendar'),
            child: const Text('일정 탭에서 보기'),
          ),
        ],
      );
    }
    if (status == EventStatus.cancelled) {
      return Text('취소된 모임이에요', style: Theme.of(context).textTheme.bodyMedium);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pollClosed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '투표가 마감되었어요. 주최자가 일시를 확정하거나 마감을 연장할 수 있어요.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (status == EventStatus.pollOpen) ...[
          FtPrimaryButton(
            label: '날짜 투표하기',
            onPressed: pollClosed
                ? null
                : () async {
                    final ok = await showVoteBottomSheet(context, ref, eventId: eventId, options: options);
                    if (ok == true) onChanged();
                  },
          ),
          const SizedBox(height: 8),
          FtSecondaryButton(
            label: '투표 현황',
            onPressed: () => context.push('/events/$eventId/poll-summary'),
          ),
          if (isOrganizer) ...[
            const SizedBox(height: 8),
            FtSecondaryButton(
              label: '일시 확정',
              onPressed: () => context.push('/events/$eventId/confirm-datetime'),
            ),
            const SizedBox(height: 8),
            FtSecondaryButton(
              label: '투표 마감 연장',
              onPressed: () => context.push('/events/$eventId/extend-poll'),
            ),
            const SizedBox(height: 8),
            FtSecondaryButton(
              label: '날짜 후보 다시 정하기',
              onPressed: () => context.push('/events/$eventId/date-options'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _nudge(ref, context, 'poll'),
              child: const Text('독촉 보내기'),
            ),
          ],
        ],
        if (status == EventStatus.attendanceOpen) ...[
          FtPrimaryButton(
            label: '참석 답변하기',
            onPressed: () async {
              final ok = await showAttendanceBottomSheet(context, ref, eventId: eventId);
              if (ok == true) onChanged();
            },
          ),
          if (isOrganizer) ...[
            const SizedBox(height: 8),
            FtPrimaryButton(
              label: '모임 확정',
              onPressed: () => _finalize(ref, context),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _nudge(ref, context, 'attendance'),
              child: const Text('독촉 보내기'),
            ),
          ],
        ],
        if (isOrganizer) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.push('/events/$eventId/edit'),
            child: const Text('모임 편집'),
          ),
          TextButton(
            onPressed: () => _cancel(ref, context),
            child: const Text('모임 취소'),
          ),
        ],
      ],
    );
  }

  Future<void> _nudge(WidgetRef ref, BuildContext context, String phase) async {
    if (OfflineWriteGuard(ref).blockWrite(context)) return;
    try {
      final r = await ref.read(eventsRepositoryProvider).nudge(eventId, phase);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${r['sentCount']}명에게 독촉을 보냈어요')),
        );
      }
      onChanged();
    } catch (e) {
      if (context.mounted) ApiErrorHandler.show(context, e);
    }
  }

  Future<void> _finalize(WidgetRef ref, BuildContext context) async {
    if (OfflineWriteGuard(ref).blockWrite(context)) return;
    try {
      await ref.read(eventsRepositoryProvider).finalizeEvent(eventId);
      onChanged();
    } catch (e) {
      if (context.mounted) ApiErrorHandler.show(context, e, onRetry: onChanged);
    }
  }

  Future<void> _cancel(WidgetRef ref, BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('모임 취소'),
        content: const Text('모든 멤버에게 취소 알림이 가요. 계속할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('아니요')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('모임 취소')),
        ],
      ),
    );
    if (ok != true) return;
    if (OfflineWriteGuard(ref).blockWrite(context)) return;
    try {
      await ref.read(eventsRepositoryProvider).cancelEvent(eventId);
      onChanged();
    } catch (e) {
      if (context.mounted) ApiErrorHandler.show(context, e);
    }
  }
}
