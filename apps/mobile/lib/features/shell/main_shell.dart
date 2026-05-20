import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    int index = 0;
    if (loc.startsWith('/meetings')) index = 1;
    if (loc.startsWith('/calendar')) index = 2;
    if (loc.startsWith('/notifications')) index = 3;
    if (loc.startsWith('/settings')) index = 4;

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        indicatorColor: AppColors.secondaryWash,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/meetings');
            case 2:
              context.go('/calendar');
            case 3:
              context.go('/notifications');
            case 4:
              context.go('/settings');
          }
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: scheme.onSurfaceVariant),
            selectedIcon: Icon(Icons.home, color: scheme.primary),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined, color: scheme.onSurfaceVariant),
            selectedIcon: Icon(Icons.groups, color: scheme.primary),
            label: '모임',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined, color: scheme.onSurfaceVariant),
            selectedIcon: Icon(Icons.calendar_month, color: scheme.primary),
            label: '일정',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined, color: scheme.onSurfaceVariant),
            selectedIcon: Icon(Icons.notifications, color: scheme.primary),
            label: '알림',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: scheme.onSurfaceVariant),
            selectedIcon: Icon(Icons.settings, color: scheme.primary),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
