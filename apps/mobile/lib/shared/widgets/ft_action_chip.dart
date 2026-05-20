import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum FtActionChipKind { poll, attend, neutral, cancelled }

class FtActionChip extends StatelessWidget {
  const FtActionChip({super.key, required this.label, this.kind = FtActionChipKind.neutral});

  final String label;
  final FtActionChipKind kind;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      FtActionChipKind.poll => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      FtActionChipKind.attend => (const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      FtActionChipKind.cancelled => (Colors.grey.shade300, Colors.grey.shade700),
      FtActionChipKind.neutral => (AppColors.secondaryWash, AppColors.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
