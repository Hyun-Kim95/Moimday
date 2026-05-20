import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error_handler.dart';
import '../../../core/network/offline_write_guard.dart';
import '../../auth/auth_state.dart';
import '../group_repository.dart';

class GroupAdminSection extends ConsumerWidget {
  const GroupAdminSection({
    super.key,
    required this.groupDetail,
    required this.onChanged,
  });

  final Map<String, dynamic> groupDetail;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final myId = session?.userId;
    final adminId = groupDetail['adminUserId'] as String?;
    final isAdmin = myId != null && myId == adminId;
    final members = (groupDetail['members'] as List<dynamic>?) ?? [];
    final groupId = groupDetail['id'] as String;

    if (!isAdmin) {
      return OutlinedButton(
        onPressed: () => _leave(context, ref, groupId, isAdmin: false),
        child: const Text('그룹 나가기'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('그룹 관리', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...members.map((m) {
          final map = m as Map<String, dynamic>;
          final uid = map['userId'] as String;
          final name = map['displayName'] as String? ?? '';
          final memberIsAdmin = map['isAdmin'] == true;
          if (uid == myId) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('$name (나)'),
              subtitle: const Text('관리자'),
            );
          }
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(name),
            subtitle: Text(memberIsAdmin ? '관리자' : '구성원'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (OfflineWriteGuard(ref).blockWrite(context)) return;
                final repo = ref.read(groupRepositoryProvider);
                try {
                  if (v == 'remove') {
                    final ok = await _confirm(context, '이 멤버를 그룹에서 보낼까요?');
                    if (ok != true) return;
                    await repo.removeMember(groupId, uid);
                  } else if (v == 'transfer') {
                    final ok = await _confirm(context, '관리자 권한을 $name 님에게 넘길까요?');
                    if (ok != true) return;
                    await repo.transferAdmin(groupId, uid);
                  }
                  onChanged();
                } catch (e) {
                  if (context.mounted) ApiErrorHandler.show(context, e);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'transfer', child: Text('관리자 이관')),
                const PopupMenuItem(value: 'remove', child: Text('멤버보내기')),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => _leave(context, ref, groupId, isAdmin: true, members: members, myId: myId),
          child: const Text('그룹 나가기'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _deleteGroup(context, ref, groupId),
          child: Text('그룹 해체', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    );
  }

  Future<bool?> _confirm(BuildContext context, String msg) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(msg),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('확인')),
          ],
        ),
      );

  Future<void> _leave(
    BuildContext context,
    WidgetRef ref,
    String groupId, {
    required bool isAdmin,
    List<dynamic>? members,
    String? myId,
  }) async {
    if (OfflineWriteGuard(ref).blockWrite(context)) return;
    String? transferTo;
    if (isAdmin && (members?.length ?? 0) > 1) {
      final others = members!
          .map((m) => m as Map<String, dynamic>)
          .where((m) => m['userId'] != myId)
          .toList();
      if (others.isNotEmpty) {
        transferTo = await showDialog<String>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('관리자를 넘길 멤버 선택'),
            children: others
                .map(
                  (m) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, m['userId'] as String),
                    child: Text(m['displayName'] as String? ?? ''),
                  ),
                )
                .toList(),
          ),
        );
        if (transferTo == null) return;
      }
    }
    final ok = await _confirm(context, '그룹에서 나갈까요?');
    if (ok != true) return;
    try {
      await ref.read(groupRepositoryProvider).leaveGroup(groupId, transferAdminToUserId: transferTo);
      await ref.read(sessionProvider.notifier).refresh();
      if (context.mounted) context.go('/home');
    } catch (e) {
      if (context.mounted) ApiErrorHandler.show(context, e);
    }
  }

  Future<void> _deleteGroup(BuildContext context, WidgetRef ref, String groupId) async {
    if (OfflineWriteGuard(ref).blockWrite(context)) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('그룹 해체'),
        content: const Text('그룹과 데이터가 삭제돼요. 진행 중인 모임은 취소 처리됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('해체'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(groupRepositoryProvider).deleteGroup(groupId);
      await ref.read(sessionProvider.notifier).refresh();
      if (context.mounted) context.go('/group');
    } catch (e) {
      if (context.mounted) ApiErrorHandler.show(context, e);
    }
  }
}
