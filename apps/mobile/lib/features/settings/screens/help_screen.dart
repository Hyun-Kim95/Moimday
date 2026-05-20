import 'package:flutter/material.dart';

import '../../../shared/widgets/ft_card.dart';
import '../../../shared/widgets/ft_section_title.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('도움말')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const FtSectionTitle('푸시 알림이 오지 않을 때'),
          FtCard(
            child: Text(
              '• 설정에서 Moimday 알림을 허용해 주세요.\n'
              '• Android: 배터리 최적화 예외를 설정해 주세요.\n'
              '• iOS: 알림 권한을 확인해 주세요.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
          const FtSectionTitle('자주 묻는 질문'),
          FtCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('독촉은 하루에 몇 번인가요?', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  '같은 모임·같은 단계(투표/참석)당 하루 1회만 보낼 수 있어요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
