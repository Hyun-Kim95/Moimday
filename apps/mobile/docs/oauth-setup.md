# 소셜 로그인 네이티브 설정 (Human)

앱 실행 시 `dart-define`으로 키를 넘깁니다. API 서버 `.env`는 [services/api/.env.example](../../../services/api/.env.example) 참고.

## 공통 실행 예

```bash
cd apps/mobile
flutter pub get
flutter run \
  --dart-define=KAKAO_NATIVE_APP_KEY=카카오_네이티브앱키 \
  --dart-define=GOOGLE_OAUTH_CLIENT_ID=xxx.apps.googleusercontent.com \
  --dart-define=TERMS_URL=https://your-site.com/terms \
  --dart-define=PRIVACY_URL=https://your-site.com/privacy
```

## 카카오

1. [Kakao Developers](https://developers.kakao.com/) 앱 생성
2. **네이티브 앱 키** → `KAKAO_NATIVE_APP_KEY`
3. 플랫폼 등록: Android 패키지명, iOS 번들 ID
4. **Android** `android/app/src/main/AndroidManifest.xml` — `kakao{네이티브앱키}` scheme용 `AuthCodeHandlerActivity` ([카카오 Flutter 가이드](https://developers.kakao.com/docs/latest/ko/flutter/getting-started))
5. **iOS** `Info.plist` — `CFBundleURLTypes`에 `kakao{네이티브앱키}` 추가
6. API `.env`: `KAKAO_REST_API_KEY` (REST API 키, 서버 검증용)

## Google

1. [Google Cloud Console](https://console.cloud.google.com/) OAuth 클라이언트 ID
2. **Android**: 패키지명 + SHA-1 (debug/release)
3. **iOS**: iOS 클라이언트 ID → `GOOGLE_OAUTH_CLIENT_ID`
4. API `.env`: `GOOGLE_OAUTH_CLIENT_IDS` (쉼표로 Android/iOS/Web 클라이언트 ID)

## Apple (iOS 필수)

1. Apple Developer → Identifiers → Sign in with Apple
2. Xcode → Runner → Signing & Capabilities → **Sign in with Apple**
3. API `.env`: `APPLE_CLIENT_IDS` = Bundle ID (예: `com.example.moimday`)

## API 서버

```env
KAKAO_REST_API_KEY=
GOOGLE_OAUTH_CLIENT_IDS=android-id,ios-id
APPLE_CLIENT_IDS=com.your.bundle
```

OTP/SMS 변수는 제거됨.

## 2차: 네이버

[ADR-0005](../../../docs/decisions/0005-social-oauth-auth.md) — 별도 마일스톤.
