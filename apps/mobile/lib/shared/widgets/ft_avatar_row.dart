import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class FtAvatarRow extends StatelessWidget {
  const FtAvatarRow({super.key, required this.names, this.max = 8, this.onShowAll});

  final List<String> names;
  final int max;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) {
      return Text('모두 응답했어요', style: Theme.of(context).textTheme.bodySmall);
    }
    final shown = names.take(max).toList();
    final extra = names.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...shown.map((n) => _AvatarBadge(label: n)),
            if (extra > 0)
              GestureDetector(
                onTap: onShowAll,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.secondaryWash,
                  child: Text('+$extra', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                ),
              ),
          ],
        ),
        if (extra > 0 && onShowAll != null)
          TextButton(
            onPressed: onShowAll,
            child: Text('전체 보기 (${names.length}명)'),
          ),
      ],
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final initial = label.isEmpty ? '?' : label[0];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 48,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
