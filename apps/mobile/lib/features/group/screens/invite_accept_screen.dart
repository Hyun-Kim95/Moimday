import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error_handler.dart';
import '../group_repository.dart';
import '../../auth/auth_state.dart';

class InviteAcceptScreen extends ConsumerStatefulWidget {
  const InviteAcceptScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends ConsumerState<InviteAcceptScreen> {
  var _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _accept());
  }

  Future<void> _accept() async {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) {
      if (mounted) context.go('/login');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(groupRepositoryProvider).acceptInvite(widget.token);
      await ref.read(sessionProvider.notifier).refresh();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) ApiErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('초대 참여')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : const Text('초대를 처리하지 못했어요. 다시 시도해 주세요.'),
      ),
    );
  }
}
