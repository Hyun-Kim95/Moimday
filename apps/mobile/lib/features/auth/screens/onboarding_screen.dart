import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ft_primary_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                '가족 일정·모임을 한곳에서.\n누가 아직 답하지 않았는지 보이고,\n마감 전에만 알려드려요.',
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
                          '푸시 알림을 켜두면 마감·독촉을 놓치지 않아요.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FtPrimaryButton(label: '시작하기', onPressed: () => context.go('/login')),
              TextButton(onPressed: () => context.push('/help'), child: const Text('푸시 알림이 안 올 때')),
            ],
          ),
        ),
      ),
    );
  }
}
