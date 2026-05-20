import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/models/event_status.dart';
import '../shared/widgets/ft_action_chip.dart';
import '../shared/widgets/ft_avatar_row.dart';
import '../shared/widgets/ft_card.dart';
import '../shared/widgets/ft_primary_button.dart';
import '../shared/widgets/ft_secondary_button.dart';
import '../shared/widgets/ft_section_title.dart';
import '../shared/widgets/ft_status_chip.dart';

/// Debug-only design system preview.
class ComponentGalleryScreen extends StatelessWidget {
  const ComponentGalleryScreen({super.key});

  static bool get enabled => kDebugMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DS Gallery')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const FtSectionTitle('Buttons'),
          const FtPrimaryButton(label: '주요 동작'),
          const SizedBox(height: 8),
          const FtSecondaryButton(label: '보조 동작'),
          const FtSectionTitle('Chips'),
          const Wrap(
            spacing: 8,
            children: [
              FtActionChip(label: '투표 필요', kind: FtActionChipKind.poll),
              FtActionChip(label: '참석 답변', kind: FtActionChipKind.attend),
              FtStatusChip(status: EventStatus.pollOpen),
            ],
          ),
          const FtSectionTitle('Card'),
          FtCard(child: const Text('카드 콘텐츠')),
          const FtSectionTitle('Avatars'),
          const FtAvatarRow(names: ['엄마', '아빠', '지수', '동생']),
        ],
      ),
    );
  }
}
