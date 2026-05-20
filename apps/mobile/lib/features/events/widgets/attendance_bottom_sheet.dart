import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_handler.dart';
import '../../../shared/widgets/ft_primary_button.dart';
import '../events_repository.dart';

Future<bool?> showAttendanceBottomSheet(BuildContext context, WidgetRef ref, {required String eventId}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _AttendanceSheet(eventId: eventId),
  );
}

class _AttendanceSheet extends ConsumerStatefulWidget {
  const _AttendanceSheet({required this.eventId});
  final String eventId;

  @override
  ConsumerState<_AttendanceSheet> createState() => _AttendanceSheetState();
}

class _AttendanceSheetState extends ConsumerState<_AttendanceSheet> {
  var _value = 'attend';
  final _note = TextEditingController();
  var _loading = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
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
          Text('참석 답변', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'attend', label: Text('참석')),
              ButtonSegment(value: 'decline', label: Text('불참')),
              ButtonSegment(value: 'maybe', label: Text('미정')),
            ],
            selected: {_value},
            onSelectionChanged: (s) => setState(() => _value = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: '메모 (선택)'),
            maxLength: 100,
          ),
          FtPrimaryButton(
            label: '답변 저장',
            loading: _loading,
            onPressed: () async {
              setState(() => _loading = true);
              try {
                await ref.read(eventsRepositoryProvider).submitResponse(
                  widget.eventId,
                  _value,
                  note: _note.text.trim().isEmpty ? null : _note.text.trim(),
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
