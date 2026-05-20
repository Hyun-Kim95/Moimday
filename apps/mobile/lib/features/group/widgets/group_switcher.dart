import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_state.dart';
import '../../home/home_providers.dart';
import '../group_repository.dart';

/// 앱바 액션: 활성 그룹 전환 (2개 이상일 때만 표시).
class GroupSwitcherAction extends ConsumerWidget {
  const GroupSwitcherAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    if (session == null || session.groups.length < 2) {
      return const SizedBox.shrink();
    }

    final active = session.groups
        .where((g) => g.id == session.activeGroupId)
        .firstOrNull;
    final label = active?.name ?? '그룹';

    return TextButton.icon(
      onPressed: () => _openSheet(context, ref, session),
      icon: const Icon(Icons.swap_horiz, size: 20),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      style: TextButton.styleFrom(
        maximumSize: const Size(160, 48),
      ),
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref,
    Session session,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text('그룹 선택', style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ...session.groups.map((g) {
              final selected = g.id == session.activeGroupId;
              return ListTile(
                leading: Icon(
                  selected ? Icons.check_circle : Icons.group_outlined,
                  color: selected ? Theme.of(ctx).colorScheme.primary : null,
                ),
                title: Text(g.name),
                subtitle: Text('${g.memberCount}명'),
                onTap: () => Navigator.pop(ctx, g.id),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked == null || picked == session.activeGroupId) return;

    try {
      await ref.read(groupRepositoryProvider).setActiveGroup(picked);
      await ref.read(sessionProvider.notifier).refresh();
      ref.invalidate(homeDataProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('그룹 전환에 실패했어요: $e')),
        );
      }
    }
  }
}
