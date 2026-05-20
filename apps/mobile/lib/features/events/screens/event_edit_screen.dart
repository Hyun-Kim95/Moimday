import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/datetime/date_time_utils.dart';
import '../../../core/models/event_status.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../shared/widgets/ft_date_time_field.dart';
import '../../../shared/widgets/ft_primary_button.dart';
import '../events_repository.dart';
import 'event_detail_screen.dart';

class EventEditScreen extends ConsumerStatefulWidget {
  const EventEditScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends ConsumerState<EventEditScreen> {
  final _title = TextEditingController();
  final _place = TextEditingController();
  final _memo = TextEditingController();
  DateTime? _pollDeadline;
  DateTime? _attendanceDeadline;
  var _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save(Map<String, dynamic> event) async {
    setState(() => _loading = true);
    try {
      final body = <String, dynamic>{
        'title': _title.text.trim(),
        'place': _place.text.trim().isEmpty ? null : _place.text.trim(),
        'memo': _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      };
      if (_pollDeadline != null) {
        body['pollDeadlineAt'] = DateTimeUtils.toApiIso(_pollDeadline!);
      }
      if (_attendanceDeadline != null) {
        body['attendanceDeadlineAt'] = DateTimeUtils.toApiIso(_attendanceDeadline!);
      }
      await ref.read(eventsRepositoryProvider).patchEvent(
        widget.eventId,
        event['version'] as int? ?? 1,
        body,
      );
      ref.invalidate(eventDetailProvider(widget.eventId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ApiErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('모임 편집')),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (event) {
          final status = EventStatus.fromApi(event['status'] as String? ?? '');
          if (status == EventStatus.cancelled || status == EventStatus.finalized) {
            return const Center(child: Text('편집할 수 없는 모임이에요'));
          }
          if (_title.text.isEmpty) {
            _title.text = event['title'] as String? ?? '';
            _place.text = event['place'] as String? ?? '';
            _memo.text = event['memo'] as String? ?? '';
            if (event['pollDeadlineAt'] != null) {
              _pollDeadline = DateTimeUtils.parseApi(event['pollDeadlineAt'] as String);
            }
            if (event['attendanceDeadlineAt'] != null) {
              _attendanceDeadline = DateTimeUtils.parseApi(event['attendanceDeadlineAt'] as String);
            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(controller: _title, decoration: const InputDecoration(labelText: '제목')),
              TextField(controller: _place, decoration: const InputDecoration(labelText: '장소')),
              TextField(controller: _memo, decoration: const InputDecoration(labelText: '메모')),
              if (status == EventStatus.pollOpen && _pollDeadline != null) ...[
                const SizedBox(height: 12),
                FtDateTimeField(
                  label: '투표 마감',
                  value: _pollDeadline!,
                  onChanged: (d) => setState(() => _pollDeadline = d),
                ),
              ],
              if (status == EventStatus.attendanceOpen && _attendanceDeadline != null) ...[
                const SizedBox(height: 12),
                FtDateTimeField(
                  label: '참석 마감',
                  value: _attendanceDeadline!,
                  onChanged: (d) => setState(() => _attendanceDeadline = d),
                ),
              ],
              const SizedBox(height: 24),
              FtPrimaryButton(
                label: '저장',
                loading: _loading,
                onPressed: () => _save(event),
              ),
            ],
          );
        },
      ),
    );
  }
}
