import 'package:flutter/material.dart';

class FtSkeleton extends StatelessWidget {
  const FtSkeleton({super.key, this.height = 16, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class FtCardSkeleton extends StatelessWidget {
  const FtCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FtSkeleton(height: 14, width: 80),
            const SizedBox(height: 12),
            const FtSkeleton(height: 20),
            const SizedBox(height: 8),
            const FtSkeleton(height: 14, width: 160),
          ],
        ),
      ),
    );
  }
}
