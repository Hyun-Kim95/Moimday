import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_repository.dart';

/// FCM: `--dart-define=FCM_USE_FIREBASE=true` + Firebase 프로젝트 설정 시 실제 토큰 등록.
/// 기본값은 개발용 토큰(PoC).
final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(ref.watch(authRepositoryProvider));
});

class PushService {
  PushService(this._auth);
  final AuthRepository _auth;

  static const _useFirebase = bool.fromEnvironment('FCM_USE_FIREBASE', defaultValue: false);

  Future<void> register() async {
    if (_useFirebase) {
      try {
        await _registerFirebaseToken();
        return;
      } catch (e, st) {
        debugPrint('FCM register failed, falling back to dev token: $e\n$st');
      }
    }
    await registerDevToken();
  }

  Future<void> _registerFirebaseToken() async {
    // Optional dependency: add firebase_core + firebase_messaging and google-services when enabling.
    // ignore: avoid_dynamic_calls
    final messaging = await _loadFirebaseMessaging();
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) throw StateError('FCM token empty');
    final platform = Platform.isIOS ? 'ios' : 'android';
    await _auth.registerPushToken(platform, token);
    messaging.onMessageOpenedApp.listen((msg) {
      debugPrint('FCM opened: ${msg.data}');
    });
  }

  Future<dynamic> _loadFirebaseMessaging() async {
    throw UnsupportedError(
      'FCM_USE_FIREBASE=true requires firebase_messaging in pubspec and Firebase init in main.dart',
    );
  }

  Future<void> registerDevToken() async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    final token = 'dev-fcm-$platform-${DateTime.now().millisecondsSinceEpoch}';
    await _auth.registerPushToken(platform, token);
  }
}
