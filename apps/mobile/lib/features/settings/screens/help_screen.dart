import 'package:flutter/material.dart';

import '../../../shared/widgets/ft_card.dart';
import '../../../shared/widgets/ft_section_title.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('?„ì?ë§?)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const FtSectionTitle('?¸ì‹œ ?Œë¦¼???¤ì? ?Šì„ ??),
          FtCard(
            child: Text(
              '???¤ì •?ì„œ Moimday ?Œë¦¼???ˆìš©??ì£¼ì„¸??\n'
              '??Android: ë°°í„°ë¦?ìµœì ???ˆì™¸ë¥??¤ì •??ì£¼ì„¸??\n'
              '??iOS: ?Œë¦¼ ê¶Œí•œ???•ì¸??ì£¼ì„¸??',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
          const FtSectionTitle('?ì£¼ ë¬»ëŠ” ì§ˆë¬¸'),
          FtCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('?…ì´‰?€ ?˜ë£¨??ëª?ë²ˆì¸ê°€??', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  'ê°™ì? ëª¨ì„Â·ê°™ì? ?¨ê³„(?¬í‘œ/ì°¸ì„)???˜ë£¨ 1?Œë§Œ ë³´ë‚¼ ???ˆì–´??',
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
