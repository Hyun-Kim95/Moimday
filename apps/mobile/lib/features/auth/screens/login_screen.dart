import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/legal_urls.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/services/push_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ft_primary_button.dart';
import '../../../shared/widgets/ft_secondary_button.dart';
import '../auth_repository.dart';
import '../auth_state.dart';
import '../social_sign_in_service.dart';

final _socialSignInProvider = Provider<SocialSignInService>((_) => SocialSignInService());

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  var _ageOk = false;
  var _loading = false;
  String? _error;

  bool get _canSignIn => _ageOk && !_loading;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없어요.')),
        );
      }
    }
  }

  Future<void> _finishLogin(Map<String, dynamic> data) async {
    await ref.read(pushServiceProvider).register();
    await ref.read(sessionProvider.notifier).refresh();
    final user = data['user'] as Map<String, dynamic>;
    if (!mounted) return;
    context.go(user['hasGroup'] == true ? '/home' : '/group');
  }

  Future<void> _signIn(Future<SocialSignInResult> Function() obtain) async {
    if (!_ageOk) {
      setState(() => _error = '만 14세 이상 동의가 필요해요.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await obtain();
      final data = await ref.read(authRepositoryProvider).signInWithOAuth(
            provider: cred.provider,
            idToken: cred.idToken,
            accessToken: cred.accessToken,
          );
      await _finishLogin(data);
    } on SocialSignInCancelled {
      // 사용자 취소 — 무시
    } catch (e) {
      if (mounted) {
        final api = ref.read(authRepositoryProvider).asApiError(e);
        if (api != null) {
          ApiErrorHandler.show(context, e);
        }
        setState(() => _error = api?.message ?? e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(_socialSignInProvider);
    final kakaoKey = const String.fromEnvironment('KAKAO_NATIVE_APP_KEY', defaultValue: '');
    final googleKey = const String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID', defaultValue: '');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 24),
            Text(
              'Moimday',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text('가족 일정·모임을 함께 맞춰요', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            CheckboxListTile(
              value: _ageOk,
              onChanged: (v) => setState(() => _ageOk = v ?? false),
              title: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('만 14세 이상이며 '),
                  InkWell(
                    onTap: () => _openUrl(termsUrl),
                    child: Text(
                      '이용약관',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text(' 및 '),
                  InkWell(
                    onTap: () => _openUrl(privacyUrl),
                    child: Text(
                      '개인정보처리방침',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text('에 동의합니다'),
                ],
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            if (kakaoKey.isNotEmpty)
              FtPrimaryButton(
                label: '카카오로 시작하기',
                loading: _loading,
                onPressed: _canSignIn ? () => _signIn(social.signInKakao) : null,
              )
            else
              Text(
                '카카오: flutter run --dart-define=KAKAO_NATIVE_APP_KEY=...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            if (googleKey.isNotEmpty)
              FtSecondaryButton(
                label: 'Google로 시작하기',
                onPressed: _canSignIn && !_loading ? () => _signIn(social.signInGoogle) : null,
              )
            else
              Text(
                'Google: --dart-define=GOOGLE_OAUTH_CLIENT_ID=...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            if (defaultTargetPlatform == TargetPlatform.iOS)
              FtSecondaryButton(
                label: 'Apple로 시작하기',
                onPressed: _canSignIn && !_loading ? () => _signIn(social.signInApple) : null,
              ),
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              Text(
                '개발: 각 제공자 키는 apps/mobile/docs/oauth-setup.md 참고',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
