import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/datetime/date_time_utils.dart';
import '../../../shared/widgets/ft_card.dart';
import '../../../shared/widgets/ft_empty_state.dart';
import '../../../shared/widgets/ft_skeleton.dart';
import '../../auth/auth_state.dart';
import '../../home/home_repository.dart';

final calendarProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final groupId = ref.watch(sessionProvider).value?.groupId;
  if (groupId == null) return [];
  final res = await ref.watch(homeRepositoryProvider).getCalendar(groupId);
  return res['items'] as List<dynamic>? ?? [];
});

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  var _focused = DateTime.now();
  DateTime? _selected;

  List<dynamic> _forDay(List<dynamic> items, DateTime day) {
    return items.where((raw) {
      final m = raw as Map<String, dynamic>;
      final s = DateTimeUtils.parseApi(m['startsAt'] as String);
      return s.year == day.year && s.month == day.month && s.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cal = ref.watch(calendarProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('일정')),
      body: cal.when(
        loading: () => const Center(child: FtSkeleton(height: 200)),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return const FtEmptyState(message: '확정된 일정이 없어요');
          }
          final selected = _selected ?? DateTime.now();
          final dayItems = _forDay(items, selected);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2035),
                focusedDay: _focused,
                selectedDayPredicate: (d) => isSameDay(_selected, d),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selected = selectedDay;
                    _focused = focusedDay;
                  });
                },
                eventLoader: (day) => _forDay(items, day),
                calendarStyle: const CalendarStyle(markersMaxCount: 1),
              ),
              const SizedBox(height: 16),
              Text(
                DateFormat('M월 d일').format(selected),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (dayItems.isEmpty)
                const Text('이 날 확정된 일정이 없어요')
              else
                ...dayItems.map((raw) {
                  final m = raw as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FtCard(
                      onTap: () => context.push('/events/${m['eventId']}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['title'] as String? ?? '', style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            DateTimeUtils.formatDisplayFromIso(m['startsAt'] as String?),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
