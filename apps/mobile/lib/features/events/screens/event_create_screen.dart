import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/datetime/date_time_utils.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/network/offline_write_guard.dart';
import '../../../shared/widgets/ft_date_time_field.dart';
import '../../../shared/widgets/ft_primary_button.dart';
import '../../auth/auth_state.dart';
import '../events_repository.dart';

class _PollOption {
  _PollOption() : startsAt = DateTimeUtils.defaultFirstCandidate(), isAllDay = false;
  DateTime startsAt;
  bool isAllDay;
}

class EventCreateScreen extends ConsumerStatefulWidget {
  const EventCreateScreen({super.key});

  @override
  ConsumerState<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends ConsumerState<EventCreateScreen> {
  final _title = TextEditingController();
  final _place = TextEditingController();
  final _memo = TextEditingController();
  var _mode = 'poll';
  var _loading = false;
  String? _validationError;

  late List<_PollOption> _pollOptions;
  late DateTime _pollDeadline;
  late DateTime _fixedStart;
  late DateTime _fixedAttendanceDeadline;
  var _fixedAllDay = false;

  @override
  void initState() {
    super.initState();
    final first = DateTimeUtils.defaultFirstCandidate();
    _pollOptions = [_PollOption()..startsAt = first, _PollOption()..startsAt = first.add(const Duration(days: 1))];
    _syncPollDeadline();
    _fixedStart = DateTimeUtils.defaultFirstCandidate();
    _fixedAttendanceDeadline = DateTimeUtils.defaultAttendanceDeadline(_fixedStart);
  }

  void _syncPollDeadline() {
    final earliest = _pollOptions.map((o) => o.startsAt).reduce((a, b) => a.isBefore(b) ? a : b);
    _pollDeadline = DateTimeUtils.defaultPollDeadline(earliest);
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (OfflineWriteGuard(ref).blockWrite(context)) return;
    if (_title.text.trim().isEmpty) {
      setState(() => _validationError = '제목을 입력해 주세요.');
      return;
    }

    final groupId = ref.read(sessionProvider).value?.groupId;
    if (groupId == null) return;

    String? err;
    if (_mode == 'poll') {
      err = DateTimeUtils.validatePollCreate(
        _pollDeadline,
        _pollOptions.map((o) => o.startsAt).toList(),
      );
    } else {
      err = DateTimeUtils.validateFixedCreate(_fixedStart, _fixedAttendanceDeadline);
    }
    if (err != null) {
      setState(() => _validationError = err);
      return;
    }

    setState(() {
      _loading = true;
      _validationError = null;
    });
    try {
      final repo = ref.read(eventsRepositoryProvider);
      Map<String, dynamic> event;
      if (_mode == 'poll') {
        event = await repo.createPollEvent(groupId, {
          'title': _title.text.trim(),
          'mode': 'poll',
          'place': _place.text.trim().isEmpty ? null : _place.text.trim(),
          'memo': _memo.text.trim().isEmpty ? null : _memo.text.trim(),
          'pollDeadlineAt': DateTimeUtils.toApiIso(_pollDeadline),
          'options': _pollOptions
              .map((o) => {
                    'startsAt': DateTimeUtils.toApiIso(o.startsAt),
                    'isAllDay': o.isAllDay,
                  })
              .toList(),
        });
      } else {
        event = await repo.createFixedEvent(groupId, {
          'title': _title.text.trim(),
          'mode': 'fixed',
          'place': _place.text.trim().isEmpty ? null : _place.text.trim(),
          'memo': _memo.text.trim().isEmpty ? null : _memo.text.trim(),
          'confirmedStartsAt': DateTimeUtils.toApiIso(_fixedStart),
          'isAllDay': _fixedAllDay,
          'attendanceDeadlineAt': DateTimeUtils.toApiIso(_fixedAttendanceDeadline),
        });
      }
      if (mounted) context.go('/events/${event['id']}');
    } catch (e) {
      if (mounted) ApiErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('모임 만들기')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: '제목')),
          const SizedBox(height: 12),
          TextField(controller: _place, decoration: const InputDecoration(labelText: '장소 (선택)')),
          const SizedBox(height: 8),
          TextField(controller: _memo, decoration: const InputDecoration(labelText: '메모 (선택)')),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'poll', label: Text('날짜 투표')),
              ButtonSegment(value: 'fixed', label: Text('일시 확정')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          if (_mode == 'poll') ...[
            const SizedBox(height: 16),
            FtDateTimeField(
              label: '투표 마감',
              value: _pollDeadline,
              onChanged: (d) => setState(() => _pollDeadline = d),
            ),
            const SizedBox(height: 16),
            Text('후보 일시 (2~5개)', style: Theme.of(context).textTheme.titleSmall),
            ...List.generate(_pollOptions.length, (i) {
              final o = _pollOptions[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FtDateTimeField(
                            label: '후보 ${i + 1}',
                            value: o.startsAt,
                            isAllDay: o.isAllDay,
                            showAllDayToggle: true,
                            onAllDayChanged: (v) => setState(() => o.isAllDay = v),
                            onChanged: (d) {
                              setState(() {
                                o.startsAt = d;
                                _syncPollDeadline();
                              });
                            },
                          ),
                        ),
                        if (_pollOptions.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => setState(() {
                              _pollOptions.removeAt(i);
                              _syncPollDeadline();
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (_pollOptions.length < 5)
              TextButton(
                onPressed: () => setState(() {
                  _pollOptions.add(_PollOption()
                    ..startsAt = _pollOptions.last.startsAt.add(const Duration(days: 1)));
                }),
                child: const Text('후보 추가'),
              ),
          ] else ...[
            const SizedBox(height: 16),
            FtDateTimeField(
              label: '모임 일시',
              value: _fixedStart,
              isAllDay: _fixedAllDay,
              showAllDayToggle: true,
              onAllDayChanged: (v) => setState(() {
                _fixedAllDay = v;
                _fixedAttendanceDeadline = DateTimeUtils.defaultAttendanceDeadline(_fixedStart);
              }),
              onChanged: (d) => setState(() {
                _fixedStart = d;
                _fixedAttendanceDeadline = DateTimeUtils.defaultAttendanceDeadline(d);
              }),
            ),
            const SizedBox(height: 12),
            FtDateTimeField(
              label: '참석 마감',
              value: _fixedAttendanceDeadline,
              onChanged: (d) => setState(() => _fixedAttendanceDeadline = d),
            ),
          ],
          if (_validationError != null) ...[
            const SizedBox(height: 12),
            Text(_validationError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FtPrimaryButton(label: '저장', loading: _loading, onPressed: _save),
        ],
      ),
    );
  }
}
