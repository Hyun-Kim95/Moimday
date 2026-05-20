import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialSignInResult {
  SocialSignInResult({
    required this.provider,
    this.idToken,
    this.accessToken,
  });

  final String provider;
  final String? idToken;
  final String? accessToken;
}

class SocialSignInCancelled implements Exception {}

class SocialSignInService {
  static const _googleClientId = String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID', defaultValue: '');

  Future<SocialSignInResult> signInGoogle() async {
    final google = GoogleSignIn(
      scopes: const ['email', 'profile'],
      clientId: Platform.isIOS && _googleClientId.isNotEmpty ? _googleClientId : null,
    );
    final account = await google.signIn();
    if (account == null) throw SocialSignInCancelled();
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google idToken이 없어요. GOOGLE_OAUTH_CLIENT_ID를 확인해 주세요.');
    }
    return SocialSignInResult(provider: 'google', idToken: idToken);
  }

  Future<SocialSignInResult> signInApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw UnsupportedError('Apple 로그인은 iOS/macOS에서만 지원해요.');
    }
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Apple identityToken이 없어요.');
    }
    return SocialSignInResult(provider: 'apple', idToken: idToken);
  }

  Future<SocialSignInResult> signInKakao() async {
    final key = const String.fromEnvironment('KAKAO_NATIVE_APP_KEY', defaultValue: '');
    if (key.isEmpty) {
      throw StateError('KAKAO_NATIVE_APP_KEY dart-define가 필요해요.');
    }

    OAuthToken token;
    if (await isKakaoTalkInstalled()) {
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
      } catch (e) {
        debugPrint('KakaoTalk login failed, fallback: $e');
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }

    return SocialSignInResult(
      provider: 'kakao',
      accessToken: token.accessToken,
    );
  }
}
