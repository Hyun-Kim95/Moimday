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

class EventDateOptionsScreen extends ConsumerStatefulWidget {
  const EventDateOptionsScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDateOptionsScreen> createState() => _EventDateOptionsScreenState();
}

class _EventDateOptionsScreenState extends ConsumerState<EventDateOptionsScreen> {
  final List<DateTime> _options = [];
  var _loading = false;
  var _initialized = false;

  Future<void> _save() async {
    if (OfflineWriteGuard(ref).blockWrite(context)) return;
    if (_options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('날짜 후보는 2개 이상 필요해요.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('후보를 다시 정할까요?'),
        content: const Text('기존 투표가 모두 초기화돼요. 계속할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('계속')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      await ref.read(eventsRepositoryProvider).replaceDateOptions(
        widget.eventId,
        _options.map((d) => {'startsAt': DateTimeUtils.toApiIso(d), 'isAllDay': false}).toList(),
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
      appBar: AppBar(title: const Text('날짜 후보 수정')),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (event) {
          if (!_initialized) {
            _initialized = true;
            final opts = event['options'] as List<dynamic>? ?? [];
            _options.clear();
            for (final o in opts) {
              final iso = o['startsAt'] as String?;
              if (iso != null) _options.add(DateTime.parse(iso).toLocal());
            }
            if (_options.isEmpty) {
              _options.addAll([
                DateTimeUtils.nowLocal().add(const Duration(days: 3)),
                DateTimeUtils.nowLocal().add(const Duration(days: 4)),
              ]);
            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('투표 중인 모임만 후보를 바꿀 수 있어요. (2~5개)'),
              const SizedBox(height: 16),
              ..._options.asMap().entries.map((e) {
                final i = e.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: FtDateTimeField(
                          label: '후보 ${i + 1}',
                          value: e.value,
                          onChanged: (v) => setState(() => _options[i] = v),
                        ),
                      ),
                      if (_options.length > 2)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _options.removeAt(i)),
                        ),
                    ],
                  ),
                );
              }),
              if (_options.length < 5)
                FtSecondaryButton(
                  label: '후보 추가',
                  onPressed: () => setState(() {
                    _options.add(DateTimeUtils.nowLocal().add(const Duration(days: 5)));
                  }),
                ),
              const SizedBox(height: 24),
              FtPrimaryButton(label: '후보 저장', loading: _loading, onPressed: _save),
            ],
          );
        },
      ),
    );
  }
}
