import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error_handler.dart';
import '../../../core/util/invite_token_parser.dart';
import '../../../shared/widgets/ft_card.dart';
import '../../../shared/widgets/ft_primary_button.dart';
import '../../../shared/widgets/ft_secondary_button.dart';
import '../../auth/auth_state.dart';
import '../group_repository.dart';
import '../widgets/group_admin_section.dart';

class GroupScreen extends ConsumerStatefulWidget {
  const GroupScreen({super.key});

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> {
  final _name = TextEditingController();
  final _inviteToken = TextEditingController();
  var _loading = false;
  String? _inviteUrl;
  Map<String, dynamic>? _activeGroupDetail;

  @override
  void dispose() {
    _name.dispose();
    _inviteToken.dispose();
    super.dispose();
  }

  Future<void> _loadActiveGroup() async {
    final gid = ref.read(sessionProvider).value?.activeGroupId;
    if (gid == null) {
      setState(() => _activeGroupDetail = null);
      return;
    }
    final g = await ref.read(groupRepositoryProvider).getGroup(gid);
    if (mounted) setState(() => _activeGroupDetail = g);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadActiveGroup());
  }

  Future<void> _create() async {
    setState(() => _loading = true);
    try {
      await ref.read(groupRepositoryProvider).createGroup(_name.text.trim());
      await ref.read(sessionProvider.notifier).refresh();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) _showGroupError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    final token = parseInviteToken(_inviteToken.text);
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('초대 링크 또는 토큰을 입력해 주세요')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(groupRepositoryProvider).acceptInvite(token);
      await ref.read(sessionProvider.notifier).refresh();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) _showGroupError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _switchTo(String groupId) async {
    setState(() => _loading = true);
    try {
      await ref.read(groupRepositoryProvider).setActiveGroup(groupId);
      await ref.read(sessionProvider.notifier).refresh();
      await _loadActiveGroup();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) ApiErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showGroupError(BuildContext context, Object e) {
    final api = ApiErrorHandler.parse(e);
    if (api?.code == 'GROUP_FULL' || api?.code == 'USER_GROUP_LIMIT') {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(api!.code == 'GROUP_FULL' ? '정원 초과' : '그룹 수 제한'),
          content: Text(api.message),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인'))],
        ),
      );
      return;
    }
    if (api?.code == 'ALREADY_MEMBER') {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('이미 참여 중'),
          content: Text(api!.message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/home');
              },
              child: const Text('홈으로'),
            ),
          ],
        ),
      );
      return;
    }
    ApiErrorHandler.show(context, e);
  }

  Future<void> _shareInvite() async {
    final gid = ref.read(sessionProvider).value?.activeGroupId;
    if (gid == null) return;
    final res = await ref.read(groupRepositoryProvider).createInvite(gid);
    setState(() => _inviteUrl = res['inviteUrl'] as String?);
    if (_inviteUrl != null) {
      await Clipboard.setData(ClipboardData(text: _inviteUrl!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('초대 링크를 복사했어요')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    final groups = session?.groups ?? [];
    final activeId = session?.activeGroupId;
    final maxMembers = _activeGroupDetail?['maxMembers'] as int? ?? 30;
    final count = _activeGroupDetail?['memberCount'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('그룹')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (groups.isNotEmpty) ...[
            Text('내 그룹', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            ...groups.map((g) {
              final selected = g.id == activeId;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    selected ? Icons.check_circle : Icons.group_outlined,
                    color: selected ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(g.name),
                  subtitle: Text('${g.memberCount}명 · ${g.isAdmin ? '관리자' : '구성원'}'),
                  trailing: selected
                      ? const Text('사용 중')
                      : TextButton(onPressed: _loading ? null : () => _switchTo(g.id), child: const Text('전환')),
                  onTap: selected ? null : (_loading ? null : () => _switchTo(g.id)),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
          if (activeId != null) ...[
            FtCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activeGroupDetail?['name'] as String? ?? '그룹',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('구성원 $count/$maxMembers', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FtPrimaryButton(label: '초대 링크 복사', onPressed: _shareInvite),
            const SizedBox(height: 8),
            FtSecondaryButton(
              label: '카카오톡으로 공유',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('카카오 공유는 다음 버전에서 연결됩니다')),
                );
              },
            ),
            if (_inviteUrl != null) ...[
              const SizedBox(height: 12),
              SelectableText(_inviteUrl!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 24),
            FtPrimaryButton(label: '홈으로', onPressed: () => context.go('/home')),
            const SizedBox(height: 32),
          ],
          Text('새 그룹 만들기', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: '그룹 이름', hintText: '우리 가족'),
          ),
          const SizedBox(height: 12),
          FtPrimaryButton(label: '그룹 만들기', loading: _loading, onPressed: _create),
          const SizedBox(height: 32),
          Text('초대 링크로 참여', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _inviteToken,
            decoration: const InputDecoration(
              labelText: '초대 링크 또는 토큰',
              hintText: 'moimday://invite/...',
            ),
          ),
          const SizedBox(height: 12),
          FtSecondaryButton(label: '참여하기', onPressed: _loading ? null : _join),
        ],
      ),
    );
  }
}
