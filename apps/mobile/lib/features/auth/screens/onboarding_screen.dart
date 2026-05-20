import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/storage/onboarding_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ft_primary_button.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.family_restroom, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Moimday',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                'ê°€ì¡??¼ì •Â·ëª¨ìž„???œê³³?ì„œ.\n?„ê? ?„ì§ ?µí•˜ì§€ ?Šì•˜?”ì? ë³´ì´ê³?\në§ˆê° ?„ì—ë§??Œë ¤?œë ¤??',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '?¸ì‹œ ?Œë¦¼??ì¼œë‘ë©?ë§ˆê°Â·?…ì´‰???“ì¹˜ì§€ ?Šì•„??',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FtPrimaryButton(
                label: '?œìž‘?˜ê¸°',
                onPressed: () async {
                  await Permission.notification.request();
                  await ref.read(onboardingPrefsProvider).setCompleted();
                  ref.invalidate(onboardingCompletedProvider);
                  if (context.mounted) context.go('/login');
                },
              ),              TextButton(onPressed: () => context.push('/help'), child: const Text('?¸ì‹œ ?Œë¦¼????????)),
            ],
          ),
        ),
      ),
    );
  }
}
