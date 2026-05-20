import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/connectivity_status.dart';
import '../../../shared/widgets/ft_action_chip.dart';
import '../../../shared/widgets/ft_error_banner.dart';
import '../../../shared/widgets/ft_card.dart';
import '../../../shared/widgets/ft_empty_state.dart';
import '../../../shared/widgets/ft_scaffold.dart';
import '../../../shared/widgets/ft_section_title.dart';
import '../../../shared/widgets/ft_skeleton.dart';
import '../../group/widgets/group_switcher.dart';
import '../home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeDataProvider);
    final online = ref.watch(connectivityStatusProvider).valueOrNull ?? true;

    return FtTabScaffold(
      title: '홈',
      actions: const [GroupSwitcherAction()],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/meetings/create'),
        label: const Text('모임 만들기'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!online)
            FtErrorBanner(
              message: '오프라인이에요. 연결되면 최신 정보를 불러올게요.',
              onRetry: () => ref.invalidate(homeDataProvider),
            ),
          Expanded(
            child: home.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(20),
          children: const [FtCardSkeleton(), SizedBox(height: 8), FtCardSkeleton()],
        ),
        error: (e, _) => FtEmptyState(
          message: '$e',
          actionLabel: '다시 시도',
          onAction: () => ref.invalidate(homeDataProvider),
        ),
        data: (map) {
          final actions = map['actionRequired'] as List<dynamic>? ?? [];
          final upcoming = map['upcomingFinalized'] as List<dynamic>? ?? [];
          final pending = map['familyPending'] as List<dynamic>? ?? [];

          if (actions.isEmpty && upcoming.isEmpty && pending.isEmpty) {
            return FtEmptyState(
              message: '예정된 일정이 없어요',
              actionLabel: '모임 만들기',
              onAction: () => context.push('/meetings/create'),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
            children: [
              if (actions.isNotEmpty) ...[
                const FtSectionTitle('내가 할 일'),
                ...actions.map((a) => _ActionCard(item: a as Map<String, dynamic>)),
                const SizedBox(height: 16),
              ],
              if (upcoming.isNotEmpty) ...[
                const FtSectionTitle('다가오는 확정 일정'),
                ...upcoming.map((u) => _UpcomingCard(item: u as Map<String, dynamic>)),
                const SizedBox(height: 16),
              ],
              if (pending.isNotEmpty) ...[
                const FtSectionTitle('그룹 미완료'),
                ...pending.map((p) => _PendingCard(item: p as Map<String, dynamic>)),
              ],
            ],
          );
        },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final isPoll = item['actionType'] == 'poll';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FtCard(
        onTap: () => context.push('/events/${item['eventId']}'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'] as String? ?? '', style: Theme.of(context).textTheme.titleMedium),
                  if (item['deadlineAt'] != null)
                    Text(
                      '마감 ${_formatDeadline(item['deadlineAt'] as String)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            FtActionChip(
              label: isPoll ? '투표 필요' : '참석 답변',
              kind: isPoll ? FtActionChipKind.poll : FtActionChipKind.attend,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FtCard(
        onTap: () => context.push('/events/${item['eventId']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['title'] as String? ?? '', style: Theme.of(context).textTheme.titleMedium),
            Text(_formatDeadline(item['startsAt'] as String? ?? ''), style: Theme.of(context).textTheme.bodySmall),
            if (item['place'] != null) Text(item['place'] as String, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.item});
  final Map<String, dynamic> item;

  static const _previewCount = 4;

  @override
  Widget build(BuildContext context) {
    final title = item['eventTitle'] as String? ?? '모임';
    final allNames = (item['pendingDisplayNames'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((s) => s.isNotEmpty)
        .toList();
    final phase = item['phase'] == 'poll' ? '투표' : '참석';
    final preview = allNames.take(_previewCount).join(', ');
    final extra = allNames.length - _previewCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FtCard(
        onTap: () => context.push('/events/${item['eventId']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              extra > 0 ? '$phase 미완료: $preview 외 $extra명' : '$phase 미완료: $preview',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (allNames.length > _previewCount)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _showNames(context, allNames, phase),
                  child: Text('미완료 전체 (${allNames.length}명)'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showNames(BuildContext context, List<String> names, String phase) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text('$phase 미완료 (${names.length}명)', style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ...names.map((n) => ListTile(title: Text(n))),
          ],
        ),
      ),
    );
  }
}

String _formatDeadline(String iso) {
  try {
    return DateFormat('M월 d일 HH:mm').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return iso;
  }
}
