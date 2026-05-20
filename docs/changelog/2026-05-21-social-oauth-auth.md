# 소셜 로그인 전환 (2026-05-21)

## 변경
- SMS OTP 제거 → `POST /auth/oauth/{kakao|google|apple}`
- Prisma: `OAuthAccount`, `User.email` optional, `phoneE164` optional, `OtpChallenge` 삭제
- Flutter: 카카오·Google·Apple 로그인 UI, 약관/개인정보 링크
- 통합 테스트: `issueTestAccessToken` 헬퍼
- 문서: [ADR-0005](../decisions/0005-social-oauth-auth.md), PRD §8.4, API v1.3

## Human
- [apps/mobile/docs/oauth-setup.md](../../apps/mobile/docs/oauth-setup.md)
- 약관·개인정보 공개 URL

## 2차
- 네이버 로그인
