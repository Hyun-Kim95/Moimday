import 'package:flutter/material.dart';

/// 긴 멤버 명단: 미리보기 칩 + 「전체 보기」 바텀시트 (30명 규모).
class FtExpandableNameList extends StatelessWidget {
  const FtExpandableNameList({
    super.key,
    required this.title,
    required this.names,
    this.previewCount = 8,
    this.emptyLabel = '없음',
  });

  final String title;
  final List<String> names;
  final int previewCount;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) {
      return Text('$title: $emptyLabel', style: Theme.of(context).textTheme.bodySmall);
    }

    final preview = names.take(previewCount).toList();
    final hidden = names.length - preview.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...preview.map((n) => Chip(label: Text(n, style: const TextStyle(fontSize: 12)))),
            if (hidden > 0)
              ActionChip(
                label: Text('+$hidden명'),
                onPressed: () => _showAll(context),
              ),
          ],
        ),
        if (names.length > previewCount)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _showAll(context),
              child: Text('전체 보기 (${names.length}명)'),
            ),
          ),
      ],
    );
  }

  void _showAll(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        builder: (_, controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: names.length,
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    child: Text(
                      names[i].isNotEmpty ? names[i][0] : '?',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  title: Text(names[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> memberDisplayNames(List<dynamic>? raw) {
  if (raw == null) return [];
  return raw
      .map((m) => (m as Map<String, dynamic>)['displayName'] as String? ?? '')
      .where((n) => n.isNotEmpty)
      .toList();
}
