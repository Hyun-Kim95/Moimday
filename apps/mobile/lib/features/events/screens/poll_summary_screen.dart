import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/ft_card.dart';
import '../../../shared/widgets/ft_expandable_name_list.dart';
import '../../../shared/widgets/ft_skeleton.dart';
import '../events_repository.dart';

final pollSummaryProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, eventId) {
  return ref.watch(eventsRepositoryProvider).pollSummary(eventId);
});

class PollSummaryScreen extends ConsumerWidget {
  const PollSummaryScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(pollSummaryProvider(eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('투표 현황')),
      body: summary.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: FtSkeleton(height: 120),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final options = data['options'] as List<dynamic>? ?? [];
          if (options.isEmpty) {
            return const Center(child: Text('투표 후보가 없어요'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: options.length,
            itemBuilder: (_, i) {
              final o = options[i] as Map<String, dynamic>;
              final counts = o['counts'] as Map<String, dynamic>? ?? {};
              final yes = counts['yes'] as int? ?? 0;
              final no = counts['no'] as int? ?? 0;
              final maybe = counts['maybe'] as int? ?? 0;
              final pending = counts['pending'] as int? ?? 0;
              final recommended = o['recommended'] == true;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FtCard(
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: i == 0,
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _fmt(o['startsAt'] as String? ?? ''),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (recommended)
                            Chip(
                              label: const Text('추천'),
                              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      subtitle: Text('가능 $yes · 불가 $no · 미정 $maybe · 미응답 $pending'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FtExpandableNameList(
                                title: '가능',
                                names: memberDisplayNames(o['yesMembers'] as List<dynamic>?),
                              ),
                              const SizedBox(height: 12),
                              FtExpandableNameList(
                                title: '불가',
                                names: memberDisplayNames(o['noMembers'] as List<dynamic>?),
                              ),
                              const SizedBox(height: 12),
                              FtExpandableNameList(
                                title: '미정',
                                names: memberDisplayNames(o['maybeMembers'] as List<dynamic>?),
                              ),
                              const SizedBox(height: 12),
                              FtExpandableNameList(
                                title: '미응답',
                                names: memberDisplayNames(o['pendingMembers'] as List<dynamic>?),
                                emptyLabel: '모두 응답',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _fmt(String iso) {
    try {
      return DateFormat('M월 d일 HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}
