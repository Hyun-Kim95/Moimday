# ADR-0005: 소셜 로그인 (카카오 · Google · Apple)

## 상태
승인 (MVP 1차)

## 맥락
- SMS OTP는 사업자·발신번호 등록 부담으로 **MVP에서 제외**.
- iOS에 Google·카카오 로그인 시 **Sign in with Apple** 필수.

## 결정
- **1차 제공자:** `kakao`, `google`, `apple`
- **2차:** `naver` (별도 마일스톤)
- 계정 식별: `OAuthAccount(provider, subject)` 유니크 → `User` 1:N (제공자당 1계정)
- **자동 계정 병합 없음** (동일인이 여러 제공자로 가입 시 별도 User)
- `User.phoneE164` **optional** (레거시·시드 호환)
- OTP API·`OtpChallenge`·SMS 발송 **삭제**

## API
- `POST /v1/auth/oauth/:provider` — body: Google/Apple `{ "idToken" }`, Kakao `{ "accessToken" }`
- 응답: 기존 OTP verify와 동일 (`accessToken`, `refreshToken`, `user`)

## Human
- 카카오 REST API 키, Google OAuth Client ID, Apple Bundle ID / Service ID
- 이용약관·개인정보처리방침 공개 URL

## 후속
- 네이버 로그인, 계정 연동(merge)
