import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_handler.dart';
import '../../../core/network/offline_write_guard.dart';
import '../../auth/auth_state.dart';
import '../events_repository.dart';

final eventCommentsProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, eventId) {
  return ref.watch(eventsRepositoryProvider).listComments(eventId);
});

class EventCommentsSection extends ConsumerStatefulWidget {
  const EventCommentsSection({
    super.key,
    required this.eventId,
    required this.readOnly,
    required this.onChanged,
    this.organizerId,
    this.groupAdminId,
  });

  final String eventId;
  final bool readOnly;
  final VoidCallback onChanged;
  final String? organizerId;
  final String? groupAdminId;

  @override
  ConsumerState<EventCommentsSection> createState() => _EventCommentsSectionState();
}

class _EventCommentsSectionState extends ConsumerState<EventCommentsSection> {
  final _controller = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _canDelete(Map<String, dynamic> c) {
    final myId = ref.read(sessionProvider).value?.userId;
    if (myId == null) return false;
    final authorId = c['authorId'] as String?;
    return authorId == myId ||
        authorId != null && authorId == widget.organizerId ||
        myId == widget.groupAdminId;
  }

  Future<void> _delete(String commentId) async {
    if (OfflineWriteGuard(ref).blockWrite(context)) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(eventsRepositoryProvider).deleteComment(commentId);
      ref.invalidate(eventCommentsProvider(widget.eventId));
      widget.onChanged();
    } catch (e) {
      if (mounted) ApiErrorHandler.show(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(eventCommentsProvider(widget.eventId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('댓글', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        comments.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (items) => Column(
            children: items.map((c) {
              final m = c as Map<String, dynamic>;
              final id = m['id'] as String?;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m['authorDisplayName'] as String? ?? ''),
                subtitle: Text(m['body'] as String? ?? ''),
                trailing: id != null && _canDelete(m)
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(id),
                      )
                    : null,
              );
            }).toList(),
          ),
        ),
        if (!widget.readOnly) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: '댓글 입력'),
                  maxLength: 500,
                ),
              ),
              IconButton(
                icon: _sending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: _sending ? null : () => _send(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _send() async {
    if (OfflineWriteGuard(ref).blockWrite(context)) return;
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(eventsRepositoryProvider).addComment(widget.eventId, body);
      _controller.clear();
      ref.invalidate(eventCommentsProvider(widget.eventId));
      widget.onChanged();
    } catch (e) {
      if (mounted) ApiErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
