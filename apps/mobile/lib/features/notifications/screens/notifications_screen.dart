import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/ft_card.dart';
import '../../../shared/widgets/ft_empty_state.dart';
import '../../../shared/widgets/ft_skeleton.dart';
import '../notifications_repository.dart';

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(notificationsRepositoryProvider).list();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationsRepositoryProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('전체 읽음'),
          ),
        ],
      ),
      body: notes.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 5,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: FtSkeleton(height: 64),
          ),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return const FtEmptyState(message: '알림이 없어요');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final n = items[i] as Map<String, dynamic>;
              final read = n['readAt'] != null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FtCard(
                  onTap: () async {
                    await ref.read(notificationsRepositoryProvider).markRead(n['id'] as String);
                    ref.invalidate(notificationsProvider);
                    final eid = n['eventId'] as String?;
                    if (eid != null && context.mounted) context.push('/events/$eid');
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n['title'] as String? ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(n['body'] as String? ?? '', style: Theme.of(context).textTheme.bodyMedium),
                      if (n['createdAt'] != null)
                        Text(
                          _fmt(n['createdAt'] as String),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
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
      return DateFormat('M/d HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}
