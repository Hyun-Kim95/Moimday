import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/event_status.dart';
import '../../../shared/widgets/ft_skeleton.dart';
import '../events_repository.dart';
import '../widgets/event_comments_section.dart';
import '../widgets/event_detail_actions.dart';
import '../widgets/event_detail_header.dart';

final eventDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) {
  return ref.watch(eventsRepositoryProvider).getEvent(id);
});

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('모임 상세')),
      body: eventAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              FtSkeleton(height: 32),
              SizedBox(height: 12),
              FtSkeleton(height: 80),
              SizedBox(height: 12),
              FtSkeleton(height: 120),
            ],
          ),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (event) {
          final status = EventStatus.fromApi(event['status'] as String? ?? '');
          final readOnly = status == EventStatus.cancelled || status == EventStatus.finalized;

          void reload() => ref.invalidate(eventDetailProvider(eventId));

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
                EventDetailHeader(event: event),
                const SizedBox(height: 24),
                EventDetailActions(event: event, eventId: eventId, onChanged: reload),
                const Divider(height: 40),
                EventCommentsSection(
                  eventId: eventId,
                  readOnly: readOnly,
                  onChanged: reload,
                  organizerId: event['organizerId'] as String?,
                  groupAdminId: event['groupAdminId'] as String?,
                ),
            ],
          );
        },
      ),
    );
  }
}
