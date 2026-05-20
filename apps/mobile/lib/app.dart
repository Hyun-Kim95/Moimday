import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/unauthorized_handler.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_state.dart';

class MoimdayApp extends ConsumerStatefulWidget {
  const MoimdayApp({super.key});

  @override
  ConsumerState<MoimdayApp> createState() => _MoimdayAppState();
}

class _MoimdayAppState extends ConsumerState<MoimdayApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    globalUnauthorizedHandler = () async {
      await ref.read(sessionProvider.notifier).clear();
    };
    _listenDeepLinks();
  }

  void _listenDeepLinks() {
    _appLinks.uriLinkStream.listen(_routeDeepLink);
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _routeDeepLink(uri);
    });
  }

  void _routeDeepLink(Uri uri) {
    final router = ref.read(routerProvider);
    if (uri.scheme == 'moimday' && uri.host == 'invite') {
      final token = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (token.isNotEmpty) router.go('/invite/$token');
      return;
    }
    final inviteIdx = uri.pathSegments.indexOf('invite');
    if (inviteIdx >= 0 && inviteIdx + 1 < uri.pathSegments.length) {
      router.go('/invite/${uri.pathSegments[inviteIdx + 1]}');
      return;
    }
    final eventIdx = uri.pathSegments.indexOf('events');
    if (eventIdx >= 0 && eventIdx + 1 < uri.pathSegments.length) {
      router.go('/events/${uri.pathSegments[eventIdx + 1]}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Moimday',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
