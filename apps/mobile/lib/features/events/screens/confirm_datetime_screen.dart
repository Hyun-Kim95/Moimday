import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error_handler.dart';
import '../../../shared/widgets/event_date_label.dart';
import '../../../shared/widgets/ft_card.dart';
import '../../../shared/widgets/ft_primary_button.dart';
import '../events_repository.dart';
import 'event_detail_screen.dart';
import 'poll_summary_screen.dart';

class ConfirmDatetimeScreen extends ConsumerStatefulWidget {
  const ConfirmDatetimeScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<ConfirmDatetimeScreen> createState() => _ConfirmDatetimeScreenState();
}

class _ConfirmDatetimeScreenState extends ConsumerState<ConfirmDatetimeScreen> {
  String? _selectedOptionId;
  var _loading = false;

  int _yesCount(Map<String, dynamic>? summary, String optionId) {
    if (summary == null) return 0;
    final options = summary['options'] as List<dynamic>? ?? [];
    for (final o in options) {
      final m = o as Map<String, dynamic>;
      if (m['optionId'] == optionId) {
        return (m['counts'] as Map?)?['yes'] as int? ?? 0;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final summaryAsync = ref.watch(pollSummaryProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('일시 확정')),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (event) {
          final options = event['options'] as List<dynamic>? ?? [];
          if (options.isEmpty) {
            return const Center(child: Text('확정할 후보가 없어요'));
          }
          _selectedOptionId ??= (options.first as Map<String, dynamic>)['id'] as String;
          final summary = summaryAsync.valueOrNull;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('확정할 일시를 선택하세요', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ...options.map((o) {
                final m = o as Map<String, dynamic>;
                final id = m['id'] as String;
                final yes = _yesCount(summary, id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FtCard(
                    onTap: () => setState(() => _selectedOptionId = id),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: id,
                          groupValue: _selectedOptionId,
                          onChanged: (v) => setState(() => _selectedOptionId = v),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              EventDateLabel(iso: m['startsAt'] as String?, isAllDay: m['isAllDay'] == true),
                              Text('가능 $yes명', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              FtPrimaryButton(
                label: '일시 확정하기',
                loading: _loading,
                onPressed: () => _confirm(context, summary),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirm(BuildContext context, Map<String, dynamic>? summary) async {
    final optionId = _selectedOptionId;
    if (optionId == null) return;

    final yes = _yesCount(summary, optionId);
    final content = yes == 0
        ? '이 후보에 「가능」한 멤버가 아직 없어요. 그래도 이 일시로 확정할까요?'
        : '선택한 일시로 확정하면 참석 답변 단계로 넘어갑니다.';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(yes == 0 ? '가능 0명' : '일시 확정'),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('확정')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      await ref.read(eventsRepositoryProvider).confirmDatetime(widget.eventId, optionId);
      if (mounted) {
        ref.invalidate(eventDetailProvider(widget.eventId));
        context.pop();
      }
    } catch (e) {
      if (mounted) ApiErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
