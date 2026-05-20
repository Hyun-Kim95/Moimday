import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/event_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ft_card.dart';
import '../../../shared/widgets/ft_empty_state.dart';
import '../../../shared/widgets/ft_skeleton.dart';
import '../../../shared/widgets/ft_status_chip.dart';
import '../../auth/auth_state.dart';
import '../../group/widgets/group_switcher.dart';
import '../events_repository.dart';

final eventsListProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, filter) async {
  final groupId = ref.watch(sessionProvider).value?.groupId;
  if (groupId == null) return [];
  return ref.watch(eventsRepositoryProvider).listEvents(groupId, filter: filter);
});

class EventsListScreen extends ConsumerStatefulWidget {
  const EventsListScreen({super.key});

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
  var _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsListProvider(_filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('모임'),
        actions: [
          const GroupSwitcherAction(),
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all', child: Text('전체')),
              PopupMenuItem(value: 'my_pending', child: Text('내 미완료')),
            ],
            icon: const Icon(Icons.filter_list),
            tooltip: '필터',
          ),
        ],
      ),
      body: events.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: FtSkeleton(height: 72),
          ),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return FtEmptyState(
              message: '모임이 없어요\n새 모임을 만들어 그룹과 일정을 맞춰 보세요',
              actionLabel: '모임 만들기',
              onAction: () => context.push('/meetings/create'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final e = list[i] as Map<String, dynamic>;
              final status = EventStatus.fromApi(e['status'] as String? ?? '');
              final dday = _dday(e);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FtCard(
                  onTap: () => context.push('/events/${e['id']}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e['title'] as String? ?? '',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (dday != null)
                            Text(
                              dday,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.tertiaryAccent,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FtStatusChip(status: status),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/meetings/create'),
        icon: const Icon(Icons.add),
        label: const Text('모임 만들기'),
      ),
    );
  }

  String? _dday(Map<String, dynamic> e) {
    final target = e['confirmedStartsAt'] ?? e['pollDeadlineAt'] ?? e['attendanceDeadlineAt'];
    if (target == null) return null;
    try {
      final d = DateTime.parse(target as String).toLocal();
      final diff = d.difference(DateTime.now()).inDays;
      if (diff < 0) return null;
      if (diff == 0) return 'D-day';
      return 'D-$diff';
    } catch (_) {
      return null;
    }
  }
}
