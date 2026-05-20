import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_handler.dart';
import '../../../core/network/offline_write_guard.dart';
import '../../../shared/widgets/event_date_label.dart';
import '../../../shared/widgets/ft_primary_button.dart';
import '../events_repository.dart';

Future<bool?> showVoteBottomSheet(
  BuildContext context,
  WidgetRef ref, {
  required String eventId,
  required List<dynamic> options,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _VoteSheet(eventId: eventId, options: options),
  );
}

class _VoteSheet extends ConsumerStatefulWidget {
  const _VoteSheet({required this.eventId, required this.options});
  final String eventId;
  final List<dynamic> options;

  @override
  ConsumerState<_VoteSheet> createState() => _VoteSheetState();
}

class _VoteSheetState extends ConsumerState<_VoteSheet> {
  final _votes = <String, String?>{};
  var _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final o in widget.options) {
      final m = o as Map<String, dynamic>;
      _votes[m['id'] as String] = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('날짜 투표', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...widget.options.map((o) {
            final m = o as Map<String, dynamic>;
            final id = m['id'] as String;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EventDateLabel(
                    iso: m['startsAt'] as String?,
                    isAllDay: m['isAllDay'] == true,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    emptySelectionAllowed: true,
                    segments: const [
                      ButtonSegment(value: 'yes', label: Text('가능')),
                      ButtonSegment(value: 'no', label: Text('불가')),
                      ButtonSegment(value: 'maybe', label: Text('미정')),
                    ],
                    selected: _votes[id] != null ? {_votes[id]!} : {},
                    onSelectionChanged: (s) => setState(() => _votes[id] = s.firstOrNull),
                  ),
                ],
              ),
            );
          }),
          if (_error != null)
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          FtPrimaryButton(
            label: '투표 제출',
            loading: _loading,
            onPressed: () async {
              if (OfflineWriteGuard(ref).blockWrite(context)) return;
              if (_votes.values.any((v) => v == null)) {
                setState(() => _error = '모든 후보에 응답해 주세요.');
                return;
              }
              setState(() => _loading = true);
              try {
                await ref.read(eventsRepositoryProvider).submitVotes(
                  widget.eventId,
                  _votes.entries
                      .map((e) => {'optionId': e.key, 'value': e.value!})
                      .toList(),
                );
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) ApiErrorHandler.show(context, e);
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
          ),
        ],
      ),
    );
  }
}
