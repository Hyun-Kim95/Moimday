import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/datetime/date_time_utils.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/network/offline_write_guard.dart';
import '../../../shared/widgets/ft_date_time_field.dart';
import '../../../shared/widgets/ft_primary_button.dart';
import '../../../shared/widgets/ft_secondary_button.dart';
import '../events_repository.dart';
import 'event_detail_screen.dart';

class ExtendPollDeadlineScreen extends ConsumerStatefulWidget {
  const ExtendPollDeadlineScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<ExtendPollDeadlineScreen> createState() => _ExtendPollDeadlineScreenState();
}

class _ExtendPollDeadlineScreenState extends ConsumerState<ExtendPollDeadlineScreen> {
  late DateTime _deadline;
  final List<DateTime> _newOptions = [];
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _deadline = DateTimeUtils.nowLocal().add(const Duration(days: 2));
  }

  Future<void> _save() async {
    if (OfflineWriteGuard(ref).blockWrite(context)) return;
    setState(() => _loading = true);
    try {
      await ref.read(eventsRepositoryProvider).extendPollDeadline(
        widget.eventId,
        pollDeadlineAt: DateTimeUtils.toApiIso(_deadline),
        addOptions: _newOptions
            .map((d) => {'startsAt': DateTimeUtils.toApiIso(d), 'isAllDay': false})
            .toList(),
      );
      ref.invalidate(eventDetailProvider(widget.eventId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ApiErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addOption() {
    setState(() {
      _newOptions.add(DateTimeUtils.nowLocal().add(const Duration(days: 3)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventDetailProvider(widget.eventId)).valueOrNull;
    final existingCount = (event?['options'] as List<dynamic>?)?.length ?? 0;
    final canAddMore = existingCount + _newOptions.length < 5;

    return Scaffold(
      appBar: AppBar(title: const Text('투표 마감 연장')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('마감을 연장하고, 필요하면 날짜 후보를 추가할 수 있어요.'),
          const SizedBox(height: 16),
          FtDateTimeField(
            label: '투표 마감',
            value: _deadline,
            onChanged: (d) => setState(() => _deadline = d),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('추가할 날짜 후보', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('현재 $existingCount + 추가 ${_newOptions.length} / 최대 5'),
            ],
          ),
          const SizedBox(height: 8),
          ..._newOptions.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: FtDateTimeField(
                      label: '후보 ${i + 1}',
                      value: d,
                      onChanged: (v) => setState(() => _newOptions[i] = v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _newOptions.removeAt(i)),
                  ),
                ],
              ),
            );
          }),
          if (canAddMore)
            FtSecondaryButton(label: '후보 일시 추가', onPressed: _addOption),
          const SizedBox(height: 24),
          FtPrimaryButton(label: '연장하기', loading: _loading, onPressed: _save),
        ],
      ),
    );
  }
}
