import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dev/component_gallery_screen.dart';
import '../../features/auth/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/events/screens/confirm_datetime_screen.dart';
import '../../features/events/screens/event_create_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/events/screens/event_edit_screen.dart';
import '../../features/events/screens/events_list_screen.dart';
import '../../features/events/screens/event_date_options_screen.dart';
import '../../features/events/screens/extend_poll_deadline_screen.dart';
import '../../features/events/screens/poll_summary_screen.dart';
import '../../features/group/screens/group_screen.dart';
import '../../features/group/screens/invite_accept_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/settings/screens/help_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../storage/onboarding_prefs.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefreshListenable();
  ref.listen(sessionProvider, (_, __) => refresh.refresh());
  ref.listen(onboardingCompletedProvider, (_, __) => refresh.refresh());

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final onboarding = ref.read(onboardingCompletedProvider);
      final path = state.matchedLocation;

      if (session.isLoading || onboarding.isLoading) return null;

      final loggedIn = session.valueOrNull != null;
      final hasGroup = session.valueOrNull?.hasGroup ?? false;
      final onboardingDone = onboarding.valueOrNull ?? false;
      final public = path == '/onboarding' ||
          path == '/login' ||
          path == '/help' ||
          path.startsWith('/invite/');

      if (path == '/') {
        if (!onboardingDone) return '/onboarding';
        return loggedIn ? (hasGroup ? '/home' : '/group') : '/login';
      }

      if (!loggedIn && !public) return '/login';
      if (loggedIn && (path == '/login' || path == '/onboarding')) {
        return hasGroup ? '/home' : '/group';
      }
      if (loggedIn && !hasGroup && path != '/group' && !public && !path.startsWith('/events/')) {
        return '/group';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _BootstrapScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/group', builder: (_, __) => const GroupScreen()),
      GoRoute(path: '/help', builder: (_, __) => const HelpScreen()),
      GoRoute(
        path: '/invite/:token',
        builder: (_, s) => InviteAcceptScreen(token: s.pathParameters['token']!),
      ),
      GoRoute(
        path: '/events/:id',
        builder: (_, s) => EventDetailScreen(eventId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'poll-summary',
            builder: (_, s) => PollSummaryScreen(eventId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'confirm-datetime',
            builder: (_, s) => ConfirmDatetimeScreen(eventId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'edit',
            builder: (_, s) => EventEditScreen(eventId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'extend-poll',
            builder: (_, s) => ExtendPollDeadlineScreen(eventId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'date-options',
            builder: (_, s) => EventDateOptionsScreen(eventId: s.pathParameters['id']!),
          ),
        ],
      ),
      if (kDebugMode)
        GoRoute(path: '/dev/gallery', builder: (_, __) => const ComponentGalleryScreen()),
      GoRoute(path: '/meetings/create', builder: (_, __) => const EventCreateScreen()),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/meetings', builder: (_, __) => const EventsListScreen()),
          GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class RouterRefreshListenable extends ChangeNotifier {
  void refresh() => notifyListeners();
}
