import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error_handler.dart';
import '../../auth/auth_repository.dart';
import '../../auth/auth_state.dart';
import '../../group/group_repository.dart';
import '../../user/user_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _displayName = TextEditingController();
  var _reminders = true;
  var _loaded = false;
  var _isAdmin = false;
  String? _groupId;

  @override
  void dispose() {
    _displayName.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await ref.read(authRepositoryProvider).me();
      setState(() {
        _displayName.text = me['displayName'] as String? ?? '';
        _reminders = me['autoReminderEnabled'] as bool? ?? true;
        _isAdmin = me['isGroupAdmin'] as bool? ?? false;
        _groupId = me['activeGroupId'] as String? ?? me['groupId'] as String?;
        _loaded = true;
      });
    } catch (_) {
      setState(() => _loaded = true);
    }
  }

  Future<void> _saveName() async {
    try {
      await ref.read(userRepositoryProvider).updateProfile(displayName: _displayName.text.trim());
      await ref.read(sessionProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이름을 저장했어요')));
      }
    } catch (e) {
      if (mounted) ApiErrorHandler.show(context, e);
    }
  }

  Future<void> _leaveGroup() async {
    if (_groupId == null) return;
    String? transferTo;
    if (_isAdmin) {
      final group = await ref.read(groupRepositoryProvider).getGroup(_groupId!);
      final members = group['members'] as List<dynamic>? ?? [];
      transferTo = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('관리자 넘기기'),
          children: members
              .where((m) => (m as Map)['userId'] != ref.read(sessionProvider).value?.userId)
              .map((m) {
                final map = m as Map<String, dynamic>;
                return SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, map['userId'] as String),
                  child: Text(map['displayName'] as String? ?? ''),
                );
              })
              .toList(),
        ),
      );
      if (transferTo == null) return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('그룹 나가기'),
        content: const Text('그룹을 나가면 이 그룹의 모임에 접근할 수 없어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('나가기')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(groupRepositoryProvider).leaveGroup(_groupId!, transferAdminToUserId: transferTo);
      await ref.read(sessionProvider.notifier).refresh();
      if (mounted) context.go('/group');
    } catch (e) {
      if (mounted) ApiErrorHandler.show(context, e);
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text('계정을 삭제하면 복구할 수 없어요. 계속할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(userRepositoryProvider).deleteAccount();
      await ref.read(sessionProvider.notifier).clear();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) ApiErrorHandler.show(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _displayName,
                    decoration: const InputDecoration(labelText: '표시 이름'),
                  ),
                ),
                TextButton(onPressed: _saveName, child: const Text('저장')),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('자동 리마인더'),
            subtitle: const Text('마감 전 그룹에게 알림을 보내요'),
            value: _reminders,
            onChanged: !_loaded
                ? null
                : (v) async {
                    setState(() => _reminders = v);
                    await ref.read(apiClientProvider).patch('/users/me', data: {'autoReminderEnabled': v});
                  },
          ),
          ListTile(
            title: const Text('그룹 관리'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/group'),
          ),
          ListTile(
            title: const Text('도움말'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/help'),
          ),
          if (kDebugMode)
            ListTile(
              title: const Text('디자인 시스템 갤러리'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/dev/gallery'),
            ),
          if (_groupId != null)
            ListTile(
              title: const Text('그룹 나가기'),
              onTap: _leaveGroup,
            ),
          const Divider(),
          ListTile(
            title: Text('계정 삭제', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: _deleteAccount,
          ),
          ListTile(
            title: Text('로그아웃', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () async {
              await ref.read(sessionProvider.notifier).clear();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
